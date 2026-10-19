/// File: theme.dart
/// Description: Defines the core monochromatic dark theme, design tokens, and
/// component themes according to Material Design 3 Expressive guidelines.
/// Provides centralized styling used across screens and navigation components.
///
/// Components / Classes / Functions:
/// - AppColors: Design tokens holding the monochromatic dark color palette.
/// - AppTheme: Factory and builder for the application's Material 3 dark theme.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized monochromatic dark color palette.
///
/// Designed with deep charcoal/black tones, subtle surface elevations,
/// and high contrast text hierarchy for an expressive, film-like aesthetic.
abstract final class AppColors {
  // Prevent instantiation
  const AppColors._();

  /// Primary deep background color for screens and bottom navigation.
  static const Color background = Color(0xFF0E0E10);

  /// Bottom navigation background color, strictly matching the screen background.
  static const Color bottomNavBackground = background;

  /// Elevated surface colors for cards, sheets, and dialogs.
  static const Color surface = Color(0xFF141417);
  static const Color surfaceContainer = Color(0xFF1A1A1E);
  static const Color surfaceContainerHigh = Color(0xFF242429);
  static const Color surfaceContainerHighest = Color(0xFF2E2E34);

  /// Border and divider colors.
  static const Color outline = Color(0xFF2A2A30);
  static const Color outlineVariant = Color(0xFF1C1C21);

  /// Typography and iconography colors.
  static const Color onBackground = Color(0xFFF2F2F2);
  static const Color onSurface = Color(0xFFF2F2F2);
  static const Color onSurfaceVariant = Color(0xFF8E8E96);
  static const Color onSurfaceDisabled = Color(0xFF4A4A52);

  /// Futuristic off-white with a subtle cool undertone for high-impact typography.
  static const Color futuristicWhite = Color(0xFFE6E8EC);

  /// Bottom navigation indicator and state colors.
  static const Color navIndicator = Color(0xFF28282E);
  static const Color navActiveIcon = Color(0xFFFFFFFF);
  static const Color navInactiveIcon = Color(0xFF7E7E88);
  static const Color navActiveLabel = Color(0xFFFFFFFF);
  static const Color navInactiveLabel = Color(0xFF7E7E88);
}

/// Material Design 3 Expressive Theme Provider.
abstract final class AppTheme {
  const AppTheme._();

  /// Generates the configured Material 3 Expressive dark theme data.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.onBackground,
        onPrimary: AppColors.background,
        secondary: AppColors.surfaceContainerHigh,
        onSecondary: AppColors.onBackground,
        error: Color(0xFFCF6679),
        onError: AppColors.background,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      fontFamily: GoogleFonts.inconsolata().fontFamily,
      navigationBarTheme: NavigationBarThemeData(
        height: 68.0,
        backgroundColor: AppColors.bottomNavBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.navIndicator,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inconsolata(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: AppColors.navActiveLabel,
              letterSpacing: 0.3,
            );
          }
          return GoogleFonts.inconsolata(
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
            color: AppColors.navInactiveLabel,
            letterSpacing: 0.2,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              size: 24.0,
              color: AppColors.navActiveIcon,
            );
          }
          return const IconThemeData(
            size: 24.0,
            color: AppColors.navInactiveIcon,
          );
        }),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.onBackground),
        titleTextStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          color: AppColors.onBackground,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
