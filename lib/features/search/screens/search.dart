/// File: search.dart
/// Description: Search screen displaying the centered Zen Dots SearchHeader and
/// the Material Design 3 Expressive AppSearchBar with the global AppBottomNav below.
///
/// Components / Classes / Functions:
/// - Search: Type alias for SearchScreen.
/// - SearchScreen: Screen widget displaying the Search interface.
/// - _SearchScreenState: State class managing the search controller input.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/search/components/search_bar.dart';
import 'package:project_anima/features/search/components/search_header.dart';

/// Type alias allowing both `Search` and `SearchScreen` across the codebase.
typedef Search = SearchScreen;

/// Primary Search screen for the application.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bottomNavBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SearchHeader(),
            AppSearchBar(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              onClear: () => setState(() {}),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(
        currentIndex: 1,
      ),
    );
  }
}
