/// File: theme.dart
/// Description: Defines the core monochromatic dark theme, design tokens, and
/// component themes according to Material Design 3 Expressive guidelines.
/// Implements static caching of ThemeData and GoogleFonts text styles to prevent
/// runtime font-map re-parsing and redundant theme reconstructions.
///
/// Components / Classes / Functions:
/// - AppColors: Design tokens holding the monochromatic dark color palette.
/// - AppTheme: Factory provider holding pre-built, cached Material 3 dark theme data.
///   - darkTheme: Pre-built ThemeData instance created once on initial access.
///   - _buildDarkTheme(): Private builder constructing theme tokens and cached font styles.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';

export 'package:project_anima/core/theme/app_fonts.dart';

/// Centralized design tokens palette.
///
/// Provides dynamic runtime access to the active [ThemeController.instance.currentPalette].
abstract final class AppColors {
  // Prevent instantiation
  const AppColors._();

  static AppThemePalette get _current => ThemeController.instance.currentPalette;

  /// Primary deep background color for screens and bottom navigation.
  static Color get background => _current.background;

  /// Bottom navigation background color, strictly matching the screen background.
  static Color get bottomNavBackground => _current.bottomNavBackground;

  /// Elevated surface colors for cards, sheets, and dialogs.
  static Color get surface => _current.surface;
  static Color get surfaceContainer => _current.surfaceContainer;
  static Color get surfaceContainerHigh => _current.surfaceContainerHigh;
  static Color get surfaceContainerHighest => _current.surfaceContainerHighest;

  /// Border and divider colors.
  static Color get outline => _current.outline;
  static Color get outlineVariant => _current.outlineVariant;

  /// Typography and iconography colors.
  static Color get onBackground => _current.onBackground;
  static Color get onSurface => _current.onSurface;
  static Color get onSurfaceVariant => _current.onSurfaceVariant;
  static Color get onSurfaceDisabled => _current.onSurfaceDisabled;

  /// Futuristic off-white with a subtle cool undertone for high-impact typography.
  static Color get futuristicWhite => _current.futuristicWhite;

  /// Primary brand accent color.
  static Color get accent => _current.accent;

  /// Contrast foreground color for icons and text placed over [accent].
  static Color get onAccent => _current.onAccent;

  /// Bottom navigation indicator and state colors.
  static Color get navIndicator => _current.navIndicator;
  static Color get navActiveIcon => _current.navActiveIcon;
  static Color get navInactiveIcon => _current.navInactiveIcon;
  static Color get navActiveLabel => _current.navActiveLabel;
  static Color get navInactiveLabel => _current.navInactiveLabel;

  /// Subtle dark crimson tinted background and accents for pinned/favorite states.
  static Color get pinnedRedBackground => _current.pinnedRedBackground;
  static Color get pinnedRedSurface => _current.pinnedRedSurface;
  static Color get pinnedRedBorder => _current.pinnedRedBorder;

  /// Active dynamic theme palette provided by [ThemeController].
  static AppThemePalette get current => _current;
}

/// Material Design 3 Expressive Theme Provider.
abstract final class AppTheme {
  const AppTheme._();

  /// Dynamically active Material 3 Expressive theme data provided by [ThemeController].
  static ThemeData get darkTheme => ThemeController.instance.currentThemeData;

  /// Dynamically active theme data matching current family and brightness.
  static ThemeData get theme => ThemeController.instance.currentThemeData;
}
