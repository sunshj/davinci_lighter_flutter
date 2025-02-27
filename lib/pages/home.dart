import 'dart:async';
import 'package:davinci_lighter/main.dart';
import 'package:davinci_lighter/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:ambient_light/ambient_light.dart';
import 'package:torch_light/torch_light.dart';
import 'package:noise_meter/noise_meter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _lux = 0.0;
  StreamSubscription? _lightSensorStreamSub;

  _toggleTorch(bool turnOn) {
    if (turnOn) {
      TorchLight.enableTorch();
    } else {
      TorchLight.disableTorch();
    }
  }

  _listenLightSensor() {
    final appState = context.read<AppState>();
    appState.toggleEnable();

    if (appState.enable) {
      _lightSensorStreamSub = AmbientLight().ambientLightStream.listen((
        luxValue,
      ) {
        setState(() {
          _lux = luxValue;
        });

        _toggleTorch(luxValue > appState.lightThreshold);
      });
    } else {
      _lightSensorStreamSub?.cancel();
      _lightSensorStreamSub = null;
      _toggleTorch(false);
    }
  }

  int _soundLevel = 0;
  StreamSubscription? _soundSensorStreamSub;

  _listenSoundLevel() {
    final appState = context.read<AppState>();
    appState.toggleEnable();

    if (appState.enable) {
      _soundSensorStreamSub = NoiseMeter().noise.listen((event) {
        setState(() {
          _soundLevel = event.maxDecibel.toInt();
        });
        _toggleTorch(event.maxDecibel > appState.soundThreshold);
      });
    } else {
      _soundSensorStreamSub?.cancel();
      _soundSensorStreamSub = null;
      _toggleTorch(false);
    }
  }

  _togglePower(TorchMode mode) async {
    if (mode == TorchMode.light) {
      _listenLightSensor();
    } else {
      final isGranted = await requestRecordPermission(
        onDenied: () {
          showMessageDialog(
            context,
            title: '请求权限',
            content: '请允许录音权限',
            onConfirm: () {
              requestRecordPermission();
            },
          );
        },
        onPermanentlyDenied: () {
          showMessageDialog(
            context,
            title: '请求权限',
            content: '请前往系统设置中开启录音权限',
            onConfirm: () {
              openAppSettings();
            },
          );
        },
      );

      if (!isGranted) return;
      _listenSoundLevel();
    }

    HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    _lightSensorStreamSub?.cancel();
    _soundSensorStreamSub?.cancel();
    _soundSensorStreamSub = null;
    _lightSensorStreamSub = null;
    _toggleTorch(false);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text('Davinci Lighter')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _togglePower(appState.torchMode),
                    child: Container(
                      width: 140,
                      height: 140,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.power_settings_new_rounded,
                          color: appState.enable ? Colors.green : Colors.red,
                          size: 120,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(appState.enable ? "已开启" : "未开启"),
                ],
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 5,
            children: [
              Text("当前模式：${appState.torchModeText}"),
              Text("触发阈值：${appState.threshold}"),
              if (appState.showValue &&
                  appState.enable &&
                  appState.torchMode == TorchMode.light)
                Text('当前亮度：$_lux'),
              if (appState.showValue &&
                  appState.enable &&
                  appState.torchMode == TorchMode.sound)
                Text('当前分贝：$_soundLevel'),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
