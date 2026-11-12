/// File: app_theme_palette.dart
/// Description: Architectural contract defining design tokens, color palettes,
/// and Material 3 ThemeData generation for all application themes.
///
/// Components / Classes / Functions:
/// - AppThemePalette: Immutable contract holding theme tokens, 5 constituent colors, and ThemeData builder.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/app_fonts.dart';

/// Immutable design token contract holding the 5 constituent colors and
/// Material Design 3 tokens for a specific theme and brightness mode.
abstract class AppThemePalette {
  const AppThemePalette();

  /// Unique machine identifier for this theme variant (e.g. 'solar_dark').
  String get id;

  /// Identifier of the theme family (e.g. 'solar', 'that_pad', 'corporate', 'neo_tokyo', 'monochrome').
  String get family;

  /// User-facing display name of the theme.
  String get name;

  /// Brightness mode (dark or light).
  Brightness get brightness;

  /// Whether this is a dark theme.
  bool get isDark => brightness == Brightness.dark;

  /// The 5 characteristic palette colors constituting the theme preview.
  List<Color> get constituentColors;

  // --- Core Design Tokens ---

  /// Primary deep background color for screens and window canvasing.
  Color get background;

  /// Bottom navigation bar background.
  Color get bottomNavBackground => background;

  /// Surface color for cards, sheets, and dialogs.
  Color get surface;

  /// Elevated surface container for cards and floating items.
  Color get surfaceContainer;

  /// Higher elevated surface container.
  Color get surfaceContainerHigh;

  /// Highest elevated surface container.
  Color get surfaceContainerHighest;

  /// Primary border, outline, and divider color.
  Color get outline;

  /// Subtle outline variant.
  Color get outlineVariant;

  /// Primary body and title text color.
  Color get onBackground;

  /// Primary on-surface text color.
  Color get onSurface;

  /// Subtitle, metadata, and placeholder text color.
  Color get onSurfaceVariant;

  /// Disabled state text and icon color.
  Color get onSurfaceDisabled;

  /// Primary brand accent / highlight color.
  Color get accent;

  /// Contrast foreground color for icons and text positioned over [accent].
  Color get onAccent => isDark ? Colors.black : Colors.white;

  /// High-impact foreground / headline tint.
  Color get futuristicWhite;

  // --- Navigation Bar Tokens ---

  Color get navIndicator;
  Color get navActiveIcon;
  Color get navInactiveIcon;
  Color get navActiveLabel;
  Color get navInactiveLabel;

  // --- Pinned / Favorite Accent Tokens ---

  Color get pinnedRedBackground;
  Color get pinnedRedSurface;
  Color get pinnedRedBorder;

  /// Builds a complete, cached Material 3 Expressive [ThemeData] for this palette.
  ThemeData toThemeData() {
    const String fontFamily = AppFonts.segoeUi;

    final selectedNavLabelStyle = AppFonts.segoe(
      fontSize: 12.0,
      fontWeight: FontWeight.w400,
      color: navActiveLabel,
      letterSpacing: 0.3,
    );

    final unselectedNavLabelStyle = AppFonts.segoe(
      fontSize: 12.0,
      fontWeight: FontWeight.w300,
      color: navInactiveLabel,
      letterSpacing: 0.2,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: surfaceContainerHigh,
        onSecondary: onBackground,
        error: const Color(0xFFCF6679),
        onError: isDark ? Colors.black : Colors.white,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      fontFamily: fontFamily,
      fontFamilyFallback: AppFonts.fallbackChain,
      navigationBarTheme: NavigationBarThemeData(
        height: 68.0,
        backgroundColor: bottomNavBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: navIndicator,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedNavLabelStyle;
          }
          return unselectedNavLabelStyle;
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(size: 24.0, color: navActiveIcon);
          }
          return IconThemeData(size: 24.0, color: navInactiveIcon);
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: onBackground),
        titleTextStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w300,
          color: onBackground,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
