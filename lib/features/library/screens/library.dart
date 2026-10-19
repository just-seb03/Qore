/// File: library.dart
/// Description: Library screen displaying the centered Zen Dots LibraryHeader,
/// the Material Design 3 Expressive connected pill filter component, and the global AppBottomNav.
///
/// Components / Classes / Functions:
/// - Library: Type alias for LibraryScreen.
/// - LibraryScreen: Screen widget displaying the Library filters and bottom navigation.
/// - _LibraryScreenState: State class managing screen view lifecycle and active filters.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';
import 'package:project_anima/features/library/components/library_header.dart';

/// Type alias allowing both `Library` and `LibraryScreen` across the codebase.
typedef Library = LibraryScreen;

/// Primary Library screen for the application.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Set<int> _selectedFilters = const <int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bottomNavBackground,
      body: SafeArea(
        child: Column(
          children: [
            const LibraryHeader(),
            LibraryFilterPills(
              initialSelectedIndices: _selectedFilters,
              onFiltersChanged: (indices) {
                setState(() {
                  _selectedFilters = indices;
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
