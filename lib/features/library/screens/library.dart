/// File: library.dart
/// Description: Library screen displaying an empty canvas with the Material Design 3
/// Expressive connected pill filter component at the top and the global AppBottomNav below.
///
/// Components / Classes / Functions:
/// - Library: Type alias for LibraryScreen.
/// - LibraryScreen: Screen widget displaying the Library filters and bottom navigation.
/// - _LibraryScreenState: State class managing screen view lifecycle.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';

/// Type alias allowing both `Library` and `LibraryScreen` across the codebase.
typedef Library = LibraryScreen;

/// Primary Library screen for the application.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bottomNavBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LibraryFilterPills(
              initialIndex: _selectedFilter,
              onFilterChanged: (index) {
                setState(() {
                  _selectedFilter = index;
                });
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(
        currentIndex: 2,
      ),
    );
  }
}
