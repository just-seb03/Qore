/// File: home.dart
/// Description: Home screen hosting the global AppBottomNav component, requesting
/// audio permissions on initial launch, and featuring the futuristic Zen Dots HomeHeader.
/// Maintains low coupling and shares the monochromatic theme palette.
///
/// Components / Classes / Functions:
/// - Home: Type alias pointing to HomeScreen for flexible naming conventions.
/// - HomeScreen: Screen widget displaying the HomeHeader with AppBottomNav.
/// - _HomeScreenState: State class managing initial permission request lifecycle.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/permissions/audio_permission_service.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/home/components/home_header.dart';

/// Type alias allowing both `Home` and `HomeScreen` to be used cleanly across the codebase.
typedef Home = HomeScreen;

/// Home screen with the futuristic header and bottom navigation bar.
class HomeScreen extends StatefulWidget {
  /// Whether to display the bottom navigation bar. Defaults to true.
  final bool showBottomNav;

  const HomeScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInitialPermissions();
    });
  }

  Future<void> _requestInitialPermissions() async {
    final hasPermission = await AudioPermissionService.instance.hasPermission();
    if (!hasPermission) {
      await AudioPermissionService.instance.requestPermission();
    }
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
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(
              currentIndex: 0,
            )
          : null,
    );
  }
}

