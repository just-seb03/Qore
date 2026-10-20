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

  /// Maximum elapsed time between taps on the search destination to qualify as consecutive double-tap.
  static const Duration doubleTapTimeout = Duration(milliseconds: 1500);

  DateTime? _lastSearchTapTime;

  /// Trigger dispatched when the search screen should reset to its initial state
  /// (e.g. tapped twice consecutively in the bottom navigation bar).
  final ValueNotifier<int> searchResetNotifier = ValueNotifier<int>(0);

  /// Trigger dispatched when the active search screen should scroll back to top.
  final ValueNotifier<int> searchScrollToTopNotifier = ValueNotifier<int>(0);

  /// Gets the currently active tab index.
  int get currentIndex => _currentIndex;

  /// Updates the internal index without triggering route transitions.
  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    _lastSearchTapTime = null;
    notifyListeners();
  }

  /// Handles destination selection from the bottom navigation bar.
  /// Coordinates tab transitions and detects consecutive double-taps on the Search tab.
  void handleDestinationSelected(BuildContext? context, int newIndex) {
    final bool isSameTab = (_currentIndex == newIndex);

    if (newIndex == NavigationTab.search.index) {
      final now = DateTime.now();
      if (_lastSearchTapTime != null &&
          now.difference(_lastSearchTapTime!) <= doubleTapTimeout) {
        // Consecutive tap on search detected: trigger reset to initial state
        searchResetNotifier.value++;
        _lastSearchTapTime = null;
      } else {
        if (isSameTab) {
          // Single tap on already active search tab: scroll to top
          searchScrollToTopNotifier.value++;
        }
        _lastSearchTapTime = now;
      }
    } else {
      // Switched to a different tab; clear search tap tracking
      _lastSearchTapTime = null;
    }

    if (!isSameTab) {
      _currentIndex = newIndex;
      notifyListeners();
      // Delegate visual directional slide animation to MenuTransitionController
      MenuTransitionController.instance.animateTo(newIndex);
    }
  }

  /// Changes the active tab and triggers the animated menu transition.
  void navigateToTab(BuildContext? context, int newIndex) {
    handleDestinationSelected(context, newIndex);
  }

  /// Resets controller state to the initial Home tab.
  void reset() {
    _currentIndex = 0;
    _lastSearchTapTime = null;
    notifyListeners();
  }
}

