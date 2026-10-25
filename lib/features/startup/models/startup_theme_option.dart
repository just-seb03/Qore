/// File: startup_theme_option.dart
/// Description: Immutable domain model representing a theme option in the startup theme selector.
/// Encapsulates theme identifiers, human-readable display names, and constituent color palettes.
///
/// Components / Classes / Functions:
/// - StartupThemeOption: Theme preview descriptor with 5 characteristic palette colors.
library;

import 'package:flutter/material.dart';

/// Predefined theme configuration for startup preview and selection.
class StartupThemeOption {
  /// Unique machine identifier for this theme.
  final String id;

  /// User-facing display title.
  final String name;

  /// The 5 characteristic colors constituting the theme.
  final List<Color> colors;

  const StartupThemeOption({
    required this.id,
    required this.name,
    required this.colors,
  });

  /// Default monochromatic dark theme palette matching Project Anima design system.
  static const StartupThemeOption monochrome = StartupThemeOption(
    id: 'monochrome',
    name: 'Monochrome',
    colors: [
      Color(0xFF0E0E10), // 1. Deep Screen Background
      Color(0xFF1A1A1E), // 2. Elevated Surface Container
      Color(0xFF242429), // 3. Surface Container High
      Color(0xFF8E8E96), // 4. Outline / Mid-tone Variant
      Color(0xFFF2F2F2), // 5. Pure White / High-Impact Foreground
    ],
  );
}
