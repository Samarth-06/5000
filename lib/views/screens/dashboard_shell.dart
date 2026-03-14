import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'dashboard_screen.dart';
import 'map_screen.dart';
import 'ai_hub_screen.dart';
import 'settings_screen.dart';

/// 4-tab shell:
///   0 → Home (Dashboard)
///   1 → AI Hub  (Insights · Advisor · Diagnose · Soil · History · Farms)
///   2 → Map
///   3 → Profile / Settings
class DashboardShell extends StatefulWidget {
  const DashboardShell({Key? key}) : super(key: key);

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    AiHubScreen(),
    MapScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF060D06),
          border: Border(
            top: BorderSide(color: AppColors.primaryAccent.withOpacity(0.2), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAccent.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primaryAccent,
          unselectedItemColor: Colors.white30,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome, size: 24),
              label: 'AI Hub',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded, size: 24),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded, size: 24),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
