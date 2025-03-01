import 'package:davinci_lighter/state/app_state.dart';
import 'package:davinci_lighter/util.dart';
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: Text("触发模式"),
                  leading: Icon(Icons.power_settings_new_sharp),
                  trailing: SizedBox(
                    width: 100,
                    child: DropdownMenu(
                      inputDecorationTheme: InputDecorationTheme(
                        border: InputBorder.none,
                      ),
                      initialSelection: appState.torchMode,
                      enabled: !appState.enable,
                      dropdownMenuEntries: [
                        DropdownMenuEntry(
                          value: TorchMode.light,
                          label: "光敏",
                          trailingIcon: Icon(Icons.light_mode_sharp),
                        ),
                        DropdownMenuEntry(
                          value: TorchMode.sound,
                          label: "声控",
                          trailingIcon: Icon(Icons.record_voice_over_sharp),
                        ),
                      ],
                      onSelected: (value) {
                        appState.setTorchMode(value as TorchMode);
                      },
                    ),
                  ),
                ),

                ListTile(
                  title:
                      appState.lightTorchMode ? Text("光敏触发阈值") : Text("声控触发阈值"),
                  leading:
                      appState.lightTorchMode
                          ? Icon(Icons.light_mode_sharp)
                          : Icon(Icons.record_voice_over_sharp),
                  trailing: SizedBox(
                    width: 100,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        enabled: !appState.enable,
                        suffixText: appState.lightTorchMode ? 'lux' : 'dB',
                      ),
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
                  title: Text("显示更多信息"),
                  leading: Icon(Icons.info_outline),
                  trailing: Switch(
                    value: appState.showInfo,
                    onChanged: (value) {
                      appState.toggleInfoShown(value);
                    },
                  ),
                ),
              ],
            ),
          ),

          Text(
            'Davinci Lighter',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          GestureDetector(
            child: Text('©2025 sunshj'),
            onTap: () {
              openExternalUrl('https://sunshj.top');
            },
          ),
          TextButton(
            onPressed: () {
              showLicensePage(context: context);
            },
            child: Text('Licenses'),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
