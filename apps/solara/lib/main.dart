import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/solara_theme.dart';
import 'screens/map_screen.dart';
import 'screens/observe_screen.dart';
import 'screens/galaxy_screen.dart';
import 'screens/sanctuary_screen.dart';
import 'utils/celestial_events.dart';
import 'utils/tarot_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await TarotData.initialize();
  await CelestialEvents.initialize();
  runApp(const SolaraApp());
}

class SolaraApp extends StatelessWidget {
  const SolaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solara',
      debugShowCheckedModeBanner: false,
      theme: SolaraTheme.dark,
      home: const SolaraHome(),
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

  final _screens = [
    const MapScreen(),
    const ObserveScreen(),
    const GalaxyScreen(),
    const SanctuaryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Color(0xCC080C14),
            ],
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.blur_circular),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.visibility_outlined),
              label: 'Observe',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              label: 'Galaxy',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.self_improvement),
              label: 'Sanctuary',
            ),
          ],
        ),
      ),
    );
  }
}
