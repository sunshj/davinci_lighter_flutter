import 'package:davinci_lighter/pages/home_page.dart';
import 'package:davinci_lighter/pages/settings_page.dart';
import 'package:davinci_lighter/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';

void main(List<String> args) async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 创建 AppState 并初始化
  final appState = AppState();
  await appState.init();

  runApp(MyApp(appState: appState));
}

class MyApp extends StatelessWidget {
  final AppState appState;

  const MyApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Davinci Lighter',
        darkTheme: ThemeData.dark(),
        home: MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 添加GlobalKey来引用HomePage的状态
  final homePageKey = GlobalKey<HomePageState>();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    _pages.addAll([HomePage(key: homePageKey), SettingsPage()]);

    setupQuickActions();
  }

  setupQuickActions() {
    final quickActions = QuickActions();

    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'turn_on_power') {
        setState(() {
          _selectedIndex = 0;
        });
        if (mounted) {
          homePageKey.currentState?.turnOn();
        }
      }
    });

    quickActions.setShortcutItems([
      const ShortcutItem(
        type: 'turn_on_power',
        localizedTitle: '启动',
        icon: 'ic_launcher',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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
