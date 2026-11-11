/// File: profile.dart
/// Description: Profile screen for user account, preferences, and activity.
/// Instantiated as a minimal, clean placeholder following senior architectural standards.
///
/// Components / Classes / Functions:
/// - Profile: Type alias for ProfileScreen.
/// - ProfileScreen: Screen widget displaying the Profile interface.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/profile/components/profile_header.dart';

/// Type alias allowing both `Profile` and `ProfileScreen` across the codebase.
typedef Profile = ProfileScreen;

/// Primary Profile screen for the application.
class ProfileScreen extends StatelessWidget {
  /// Whether to display the bottom navigation bar. Defaults to true.
  final bool showBottomNav;

  const ProfileScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.bottomNavBackground,
      body: const SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? const AppBottomNav(
              currentIndex: 4,
            )
          : null,
    );
  }
}

