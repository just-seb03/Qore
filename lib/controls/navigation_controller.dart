/// File: navigation_controller.dart
/// Description: Centralized navigation controller managing active destination state
/// and routing between primary screens from the global bottom navigation bar.
///
/// Components / Classes / Functions:
/// - NavigationTab: Enum defining the primary bottom navigation destinations.
/// - NavigationController: Singleton ChangeNotifier coordinating tab transitions.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/controls/menu_transition_controller.dart';

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

  /// Changes the active tab and triggers the animated menu transition.
  void navigateToTab(BuildContext context, int newIndex) {
    if (_currentIndex == newIndex) return;

    _currentIndex = newIndex;
    notifyListeners();

    // Delegate visual directional slide animation to MenuTransitionController
    MenuTransitionController.instance.animateTo(newIndex);
  }
}
