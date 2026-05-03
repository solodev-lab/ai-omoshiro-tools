import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/solara_theme.dart';
import 'screens/map_screen.dart';
import 'screens/horoscope_screen.dart';
import 'screens/observe_screen.dart';
import 'screens/galaxy_screen.dart';
import 'screens/sanctuary_screen.dart';
import 'utils/app_locale.dart';
import 'utils/celestial_events.dart';
import 'utils/tarot_data.dart';
import 'widgets/solara_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Make system nav bar transparent for edge-to-edge
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));
  await TarotData.initialize();
  await CelestialEvents.initialize();
  await AppLocale.instance.load();
  runApp(const SolaraApp());
}

class SolaraApp extends StatelessWidget {
  const SolaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: AppLocale.instance.notifier,
      builder: (_, locale, _) => MaterialApp(
        title: 'Solara',
        debugShowCheckedModeBanner: false,
        theme: SolaraTheme.dark,
        locale: locale, // null の時は端末設定が使われる
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SolaraHome(),
      ),
    );
  }
}

class SolaraHome extends StatefulWidget {
  const SolaraHome({super.key});

  @override
  State<SolaraHome> createState() => _SolaraHomeState();
}

class _SolaraHomeState extends State<SolaraHome> {
  int _currentIndex = 0;
  final _mapKey = GlobalKey<MapScreenState>();
  final _horoKey = GlobalKey<HoroscopeScreenState>();
  final _galaxyKey = GlobalKey<GalaxyScreenState>();

  late final _screens = <Widget>[
    MapScreen(key: _mapKey, onNavigateToSanctuary: () => _onTabTap(4)),
    HoroscopeScreen(key: _horoKey, onNavigateToSanctuary: () => _onTabTap(4)),
    const ObserveScreen(),
    GalaxyScreen(key: _galaxyKey),
    const SanctuaryScreen(),
  ];

  void _onTabTap(int i) {
    // Galaxy タブ入室時は同じタブ再タップでなければ背景を再生成
    // (Horoと違い、毎回新鮮な星空を表示)
    final switchingToGalaxy = i == 3 && _currentIndex != 3;
    setState(() => _currentIndex = i);
    // Map / Horo へ戻ったときはプロフィールを再読込（Sanctuary で編集された場合に追従）
    if (i == 0) _mapKey.currentState?.reloadProfile();
    if (i == 1) _horoKey.currentState?.loadProfile();
    // Regenerate Galaxy background each time entering
    if (switchingToGalaxy) _galaxyKey.currentState?.regenerateBackground();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        // 2026-05-03: TickerMode で裏画面の AnimationController.repeat() を停止。
        // Galaxy 星空回転 / Horoscope 円 / Tarot Altar 等の常時 tick が
        // SurfaceFlinger の release タイミングを乱して Map 画面の点滅を引き起こしていた。
        children: [
          for (int i = 0; i < _screens.length; i++)
            TickerMode(enabled: i == _currentIndex, child: _screens[i]),
        ],
      ),
      bottomNavigationBar: SolaraNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}
