/// File: home.dart
/// Description: Minimal Home screen hosting the global AppBottomNav component.
/// Provides an empty screen surface matching the monochromatic background color
/// of the bottom navigation bar.
///
/// Components / Classes / Functions:
/// - Home: Type alias pointing to HomeScreen for flexible naming conventions.
/// - HomeScreen: Screen widget displaying an empty canvas with AppBottomNav.
/// - _HomeScreenState: State class managing navigation destination index.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Type alias allowing both `Home` and `HomeScreen` to be used cleanly across the codebase.
typedef Home = HomeScreen;

/// Empty Home screen with the bottom navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onNavigationChanged(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bottomNavBackground,
      body: const SizedBox.shrink(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onDestinationSelected: _onNavigationChanged,
      ),
    );
  }
}
