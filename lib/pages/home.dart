import 'dart:async';

import 'package:davinci_lighter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ambient_light/ambient_light.dart';
import 'package:torch_light/torch_light.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:noise_meter/noise_meter.dart';

_requestRecordPermission() async {
  final status = await Permission.microphone.status;
  if (status.isGranted) {
    print('麦克风权限已授予');
  } else {
    final result = await Permission.microphone.request();
    if (result.isGranted) {
      print('麦克风权限请求成功');
    } else if (result.isDenied) {
      print('麦克风权限被拒绝');
    } else if (result.isPermanentlyDenied) {
      print('麦克风权限被永久拒绝，请到设置中开启');
      openAppSettings();
    }
  }
}

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
      TorchLight.isTorchAvailable();
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

  _listenSoundLevel() async {
    await _requestRecordPermission();
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
      appBar: AppBar(title: Text('🔦Davinci Lighter')),
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
                    onTap: () {
                      if (appState.torchMode == TorchMode.light) {
                        _listenLightSensor();
                      } else {
                        _listenSoundLevel();
                      }
                      HapticFeedback.vibrate();
                    },
                    child: Container(
                      width: 140,
                      height: 140,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
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

          Text("当前模式：${appState.torchModeText} 当前触发阈值：${appState.threshold}"),
          if (appState.enable && appState.torchMode == TorchMode.light)
            Text('当前亮度：$_lux'),
          if (appState.enable && appState.torchMode == TorchMode.sound)
            Text('当前分贝：$_soundLevel'),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
