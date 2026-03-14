import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'dashboard_screen.dart';
import 'map_screen.dart';
import 'ai_insights_screen.dart';
import 'ai_advisor_screen.dart';
import 'settings_screen.dart';
import 'farm_selection_screen.dart';
import 'farm_history_screen.dart';
import 'image_diagnosis_screen.dart';
import 'weather_forecast_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({Key? key}) : super(key: key);

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    FarmSelectionScreen(),
    MapScreen(),
    FarmHistoryScreen(),
    WeatherForecastScreen(),
    ImageDiagnosisScreen(),
    AiAdvisorScreen(),
    AiInsightsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          border: Border(top: BorderSide(color: AppColors.primaryAccent.withOpacity(0.2), width: 1)),
          boxShadow: [BoxShadow(color: AppColors.primaryAccent.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primaryAccent,
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 8),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 20), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.agriculture, size: 20), label: 'Farms'),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded, size: 20), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded, size: 20), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.cloud, size: 20), label: 'Weather'),
            BottomNavigationBarItem(icon: Icon(Icons.camera_alt, size: 20), label: 'Diagnosis'),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy, size: 20), label: 'AI Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome, size: 20), label: 'Insights'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded, size: 20), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
