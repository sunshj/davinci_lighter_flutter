import 'package:davinci_lighter/pages/home.dart';
import 'package:davinci_lighter/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main(List<String> args) {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Davinci Lighter',
        darkTheme: ThemeData.dark(),
        home: MainScreen(),
      ),
    );
  }
}

enum TorchMode { light, sound }

class AppState extends ChangeNotifier {
  var enable = false;

  toggleEnable([bool? value]) {
    enable = value ?? !enable;
    notifyListeners();
  }

  var torchMode = TorchMode.light;

  setTorchMode(TorchMode value) {
    torchMode = value;
    notifyListeners();
  }

  get torchModeText {
    return torchMode == TorchMode.light ? 'Light' : 'Sound';
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
    notifyListeners();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [const HomePage(), const SettingsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
      ),
    );
  }
}
