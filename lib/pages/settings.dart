import 'package:davinci_lighter/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _thresholdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    _thresholdController.text = appState.threshold.toString();

    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            title: Text("触发模式"),
            trailing: SizedBox(
              width: 100,
              child: DropdownButton(
                hint: Text(appState.torchModeText),
                items:
                    !appState.enable
                        ? [
                          DropdownMenuItem(
                            value: TorchMode.light,
                            enabled: !appState.enable,
                            child: Text("光敏"),
                          ),
                          DropdownMenuItem(
                            value: TorchMode.sound,
                            enabled: !appState.enable,
                            child: Text("声控"),
                          ),
                        ]
                        : null,
                value: appState.torchMode,
                onChanged: (value) {
                  appState.setTorchMode(value ?? TorchMode.light);
                },
              ),
            ),
          ),

          ListTile(
            title:
                appState.torchMode == TorchMode.light
                    ? Text("光敏触发阈值")
                    : Text("声控触发阈值"),
            trailing: SizedBox(
              width: 100,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(enabled: !appState.enable),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: _thresholdController,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    appState.setThreshold(appState.torchMode, parsed);
                  }
                },
              ),
            ),
          ),

          ListTile(
            title: Text("显示当前数值"),
            trailing: Switch(
              value: appState.showValue,
              onChanged: (value) {
                appState.toggleShowValue(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
