/// File: home.dart
/// Description: Home screen hosting the global AppBottomNav component and
/// featuring the futuristic Zen Dots HomeHeader aligned to the left margin.
/// Maintains low coupling and shares the monochromatic theme palette.
///
/// Components / Classes / Functions:
/// - Home: Type alias pointing to HomeScreen for flexible naming conventions.
/// - HomeScreen: Screen widget displaying the HomeHeader with AppBottomNav.
/// - _HomeScreenState: State class managing navigation destination index.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/home/components/home_header.dart';

/// Type alias allowing both `Home` and `HomeScreen` to be used cleanly across the codebase.
typedef Home = HomeScreen;

/// Home screen with the futuristic header and bottom navigation bar.
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
      body: const SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeader(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onDestinationSelected: _onNavigationChanged,
      ),
    );
  }
}
