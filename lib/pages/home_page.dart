import 'dart:async';
import 'package:davinci_lighter/state/app_state.dart';
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
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _lux = 0;
  StreamSubscription? _lightSensorStreamSub;
  int _soundLevel = 0;
  StreamSubscription? _soundSensorStreamSub;

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
          _lux = luxValue.toInt();
        });

        _toggleTorch(luxValue > appState.lightThreshold);
      });
    } else {
      _lightSensorStreamSub?.cancel();
      _lightSensorStreamSub = null;
      _toggleTorch(false);
    }
  }

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
      await requestPermission(
        Permission.microphone,
        onGranted: _listenSoundLevel,
        onDenied: () {
          showMessageDialog(
            context,
            title: '请求权限',
            content: '请允许录音权限',
            onConfirm: () async {
              await requestPermission(
                Permission.microphone,
                onGranted: _listenSoundLevel,
              );
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
    }
    _showTogglePowerSnackbar();
    HapticFeedback.vibrate();
  }

  _showTogglePowerSnackbar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    final appState = context.read<AppState>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "已${appState.enable ? "开启" : "关闭"}${appState.torchModeText}手电筒",
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF000000),
      ),
    );
  }

  turnOn() {
    final appState = context.read<AppState>();
    if (!appState.enable) {
      _togglePower(appState.torchMode);
    }
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
      appBar: AppBar(
        title: Text('Davinci Lighter'),
        actionsPadding: EdgeInsets.only(right: 10),
        actions: [
          IconButton(
            onPressed: () {
              showMessageDialog(
                context,
                title: '使用说明',
                content: '光敏模式：当外界亮度大于触发阈值时，打开手电筒。\n\n声控模式：当外界音量大于触发阈值时，打开手电筒。',
                showCancelButton: false,
              );
            },
            icon: Icon(Icons.info),
          ),
        ],
      ),
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

              if (appState.showInfo) Text("触发阈值：${appState.thresholdWithUnit}"),

              if (appState.showInfo && appState.enable)
                if (appState.lightTorchMode)
                  Text('当前亮度：$_lux')
                else
                  Text('当前分贝：$_soundLevel'),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
