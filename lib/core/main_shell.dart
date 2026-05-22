import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/screens/home_screen.dart';
import '../screens/supervisor/supervisor_dashboard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../main.dart'; // for themeNotifier

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const SupervisorDashboardScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        final isDarkMode = currentMode == ThemeMode.dark;
        final themeBg = isDarkMode ? const Color(0xFF060608) : const Color(0xFFF4F6F9);
        
        return Scaffold(
          backgroundColor: themeBg,
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: _buildBottomNavigationBar(isDarkMode),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF121216) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            width: 1.5,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: const Color(0xFF8B5CF6).withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF8B5CF6)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent_rounded, color: Color(0xFFEC4899)),
            label: 'Supervisor',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF3B82F6)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
