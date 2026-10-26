/// File: bottom_nav.dart
/// Description: Global, reusable Bottom Navigation Bar component built strictly
/// with Material Design 3 Expressive guidelines, a monochromatic dark palette,
/// and an integrated subtle film grain texture. Designed with low coupling
/// and high cohesion for seamless integration into any screen or scaffold.
/// Automatically integrates with NavigationController when no custom callback is supplied.
///
/// Components / Classes / Functions:
/// - BottomNavTab: Enum representing the available navigation destinations.
/// - AppBottomNav: The primary reusable navigation widget with M3 Expressive destinations.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:project_anima/components/film_grain.dart';
import 'package:project_anima/controls/navigation_controller.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/player/components/mini_player.dart';

/// Navigation destinations supported by [AppBottomNav].
enum BottomNavTab {
  home,
  search,
  library;

  /// Retrieves localized destination label.
  String localizedLabel(BuildContext context) {
    switch (this) {
      case BottomNavTab.home:
        return context.l10n.navigation.homeTab;
      case BottomNavTab.search:
        return context.l10n.navigation.searchTab;
      case BottomNavTab.library:
        return context.l10n.navigation.libraryTab;
    }
  }

  /// Retrieves localized destination tooltip.
  String localizedTooltip(BuildContext context) {
    switch (this) {
      case BottomNavTab.home:
        return context.l10n.navigation.homeTabTooltip;
      case BottomNavTab.search:
        return context.l10n.navigation.searchTabTooltip;
      case BottomNavTab.library:
        return context.l10n.navigation.libraryTabTooltip;
    }
  }
}

/// Global Material 3 Expressive Bottom Navigation Bar.
///
/// Implements low coupling by delegating destination selection through the
/// [onDestinationSelected] callback (falling back to [NavigationController]),
/// while managing visual presentation and cohesive styling internally.
class AppBottomNav extends StatelessWidget {
  /// The index of the currently active destination.
  final int currentIndex;

  /// Optional callback triggered when a destination is tapped.
  /// If null, defaults to triggering [NavigationController.navigateToTab].
  final ValueChanged<int>? onDestinationSelected;

  /// Optional grain intensity override for custom visual styling.
  final double grainIntensity;

  /// Whether to display the global floating [MiniPlayer] above the navigation bar.
  final bool showMiniPlayer;

  const AppBottomNav({
    super.key,
    this.currentIndex = 1,
    this.onDestinationSelected,
    this.grainIntensity = 0.035,
    this.showMiniPlayer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMiniPlayer) const MiniPlayer(),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bottomNavBackground.withValues(alpha: 0.85),
                border: Border(
                  top: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.35),
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
                onDestinationSelected: (index) {
                  if (onDestinationSelected != null) {
                    onDestinationSelected!(index);
                  } else {
                    NavigationController.instance.navigateToTab(context, index);
                  }
                },
                backgroundColor: Colors.transparent, // Handled by outer container
                indicatorColor: AppColors.navIndicator,
                elevation: 0,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.favorite_border_rounded),
                    selectedIcon: const Icon(Icons.favorite_rounded),
                    label: context.l10n.navigation.homeTab,
                    tooltip: context.l10n.navigation.homeTabTooltip,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.search_rounded),
                    selectedIcon: const Icon(Icons.search_rounded),
                    label: context.l10n.navigation.searchTab,
                    tooltip: context.l10n.navigation.searchTabTooltip,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.video_library_outlined),
                    selectedIcon: const Icon(Icons.video_library_rounded),
                    label: context.l10n.navigation.libraryTab,
                    tooltip: context.l10n.navigation.libraryTabTooltip,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ],
);
}
}
