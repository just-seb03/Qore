/// File: bottom_nav.dart
/// Description: Global, reusable Bottom Navigation Bar component built strictly
/// with Material Design 3 Expressive guidelines, a monochromatic dark palette,
/// and an integrated subtle film grain texture. Designed with low coupling
/// and high cohesion for seamless integration into any screen or scaffold.
///
/// Components / Classes / Functions:
/// - BottomNavTab: Enum representing the available navigation destinations.
/// - AppBottomNav: The primary reusable navigation widget with M3 Expressive destinations.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/film_grain.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Navigation destinations supported by [AppBottomNav].
enum BottomNavTab {
  home,
  search,
  library,
}

/// Global Material 3 Expressive Bottom Navigation Bar.
///
/// Implements low coupling by delegating destination selection through the
/// [onDestinationSelected] callback while managing visual presentation and
/// cohesive styling internally.
class AppBottomNav extends StatelessWidget {
  /// The index of the currently active destination.
  final int currentIndex;

  /// Callback triggered when a navigation destination is tapped.
  final ValueChanged<int>? onDestinationSelected;

  /// Optional grain intensity override for custom visual styling.
  final double grainIntensity;

  const AppBottomNav({
    super.key,
    this.currentIndex = 0,
    this.onDestinationSelected,
    this.grainIntensity = 0.035,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomNavBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant,
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: FilmGrain(
          intensity: grainIntensity,
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            backgroundColor: Colors.transparent, // Handled by outer container
            indicatorColor: AppColors.navIndicator,
            elevation: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
                tooltip: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                selectedIcon: Icon(Icons.search_rounded),
                label: 'Search',
                tooltip: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.video_library_outlined),
                selectedIcon: Icon(Icons.video_library_rounded),
                label: 'Library',
                tooltip: 'Library',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
