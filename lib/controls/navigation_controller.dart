/// File: navigation_controller.dart
/// Description: Centralized navigation controller managing active destination state
/// and routing between primary screens from the global bottom navigation bar.
///
/// Components / Classes / Functions:
/// - NavigationTab: Enum defining the primary bottom navigation destinations.
/// - NavigationController: Singleton ChangeNotifier coordinating tab transitions.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/features/home/screens/home.dart';
import 'package:project_anima/features/library/screens/library.dart';
import 'package:project_anima/features/search/screens/search.dart';

/// Enumeration of root application navigation tabs.
enum NavigationTab {
  home,
  search,
  library;

  /// Retrieves the corresponding enum value from an integer index.
  static NavigationTab fromIndex(int index) {
    if (index >= 0 && index < NavigationTab.values.length) {
      return NavigationTab.values[index];
    }
    return NavigationTab.home;
  }
}

/// Controller responsible for bottom navigation tab switching and route handling.
class NavigationController extends ChangeNotifier {
  // Singleton pattern for centralized access
  static final NavigationController instance = NavigationController._internal();

  NavigationController._internal();

  factory NavigationController() => instance;

  int _currentIndex = 0;

  /// Gets the currently active tab index.
  int get currentIndex => _currentIndex;

  /// Updates the internal index without triggering route transitions.
  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  /// Changes the active tab and switches to the destination screen.
  void navigateToTab(BuildContext context, int newIndex) {
    if (_currentIndex == newIndex) return;

    _currentIndex = newIndex;
    notifyListeners();

    final destinationWidget = switch (newIndex) {
      0 => const HomeScreen(),
      1 => const SearchScreen(),
      2 => const LibraryScreen(),
      _ => const HomeScreen(),
    };

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destinationWidget,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}
