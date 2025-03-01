import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TorchMode { light, sound }

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // 初始化方法，加载保存的设置
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  var enable = false;

  toggleEnable([bool? value]) {
    enable = value ?? !enable;
    _saveSettings();
    notifyListeners();
  }

  var showValue = false;

  toggleShowValue([bool? value]) {
    showValue = value ?? !showValue;
    _saveSettings();
    notifyListeners();
  }

  var torchMode = TorchMode.light;

  setTorchMode(TorchMode value) {
    torchMode = value;
    _saveSettings();
    notifyListeners();
  }

  get torchModeText {
    return torchMode == TorchMode.light ? '光敏' : '声控';
  }

  var lightThreshold = 2000;
  var soundThreshold = 80;

  get threshold {
    return torchMode == TorchMode.light ? lightThreshold : soundThreshold;
  }

  setThreshold(TorchMode mode, int value) {
    if (mode == TorchMode.light) {
      lightThreshold = value;
    } else {
      soundThreshold = value;
    }
    _saveSettings();
    notifyListeners();
  }

  // 保存设置到 SharedPreferences
  void _saveSettings() {
    if (_prefs == null) return;

    _prefs!.setBool('showValue', showValue);
    _prefs!.setInt('torchMode', torchMode.index);
    _prefs!.setInt('lightThreshold', lightThreshold);
    _prefs!.setInt('soundThreshold', soundThreshold);
  }

  // 从 SharedPreferences 加载设置
  void _loadSettings() {
    if (_prefs == null) return;

    showValue = _prefs!.getBool('showValue') ?? false;
    torchMode = TorchMode.values[_prefs!.getInt('torchMode') ?? 0];
    lightThreshold = _prefs!.getInt('lightThreshold') ?? 2000;
    soundThreshold = _prefs!.getInt('soundThreshold') ?? 80;
  }
}
