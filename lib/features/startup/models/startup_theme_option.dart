/// File: startup_theme_option.dart
/// Description: Immutable domain model representing a selectable theme family in the startup theme selector.
/// Encapsulates theme identifiers, human-readable display names, and constituent palettes for both Dark and Light modes.
///
/// Components / Classes / Functions:
/// - StartupThemeOption: Theme preview descriptor with 5 characteristic palette colors for Dark and Light.
library;

import 'package:flutter/material.dart';

/// Predefined theme configuration for startup preview and selection across Dark and Light modes.
class StartupThemeOption {
  /// Unique machine identifier for this theme family (e.g. 'solar', 'that_pad').
  final String id;

  /// User-facing display title.
  final String name;

  /// The 5 characteristic colors for the dark mode variant.
  final List<Color> darkColors;

  /// The 5 characteristic colors for the light mode variant.
  final List<Color> lightColors;

  const StartupThemeOption({
    required this.id,
    required this.name,
    required this.darkColors,
    required this.lightColors,
  });

  /// Default getter returning darkColors for backward compatibility.
  List<Color> get colors => darkColors;

  /// Resolves the 5 palette colors according to active brightness mode.
  List<Color> paletteFor(bool isDark) => isDark ? darkColors : lightColors;

  // --- Predefined Theme Families ---

  /// Solar Theme: Solarized-inspired teal/cyan dark and soft ivory light.
  static const StartupThemeOption solar = StartupThemeOption(
    id: 'solar',
    name: 'Solar',
    darkColors: [
      Color(0xFF002B36), // Fondo principal
      Color(0xFF073642), // Fondo secundario / Superficie
      Color(0xFF839496), // Texto normal
      Color(0xFF93A1A1), // Texto destacado / Énfasis
      Color(0xFF586E75), // Texto atenuado / Subtexto
    ],
    lightColors: [
      Color(0xFFFDF6E3), // Fondo principal
      Color(0xFFEEE8D5), // Fondo secundario / Superficie
      Color(0xFF657B83), // Texto normal
      Color(0xFF586E75), // Texto destacado / Énfasis
      Color(0xFF93A1A1), // Texto atenuado / Subtexto
    ],
  );

  /// That Pad Theme: Industrial matte black / silver with TrackPoint red accents.
  static const StartupThemeOption thatPad = StartupThemeOption(
    id: 'that_pad',
    name: 'That Pad',
    darkColors: [
      Color(0xFF121212), // Fondo principal (chasis mate)
      Color(0xFF1E1E1E), // Fondo secundario / Superficie
      Color(0xFFE6E6E6), // Texto normal
      Color(0xFFE11422), // Color de acento principal (TrackPoint Red)
      Color(0xFF8A8A8A), // Texto atenuado / Subtexto
    ],
    lightColors: [
      Color(0xFFF3F4F6), // Fondo principal (aluminio anodizado)
      Color(0xFFFFFFFF), // Fondo secundario / Superficie
      Color(0xFF1A1D20), // Texto normal
      Color(0xFFD31220), // Color de acento principal (TrackPoint Red)
      Color(0xFF5F6368), // Texto atenuado / Subtexto
    ],
  );

  /// Corporate Theme: Modern dark slate / clean white with corporate blue accents.
  static const StartupThemeOption corporate = StartupThemeOption(
    id: 'corporate',
    name: 'Corporate',
    darkColors: [
      Color(0xFF1E1F20), // Fondo principal
      Color(0xFF282A2C), // Fondo secundario / Superficie
      Color(0xFFE3E3E3), // Texto normal
      Color(0xFF8AB4F8), // Color de acento principal (Azul pastel)
      Color(0xFF8E918F), // Texto atenuado / Subtexto
    ],
    lightColors: [
      Color(0xFFF8F9FA), // Fondo principal
      Color(0xFFFFFFFF), // Fondo secundario / Superficie
      Color(0xFF1F1F1F), // Texto normal
      Color(0xFF1A73E8), // Color de acento principal (Azul corporativo)
      Color(0xFF5F6368), // Texto atenuado / Subtexto
    ],
  );

  /// Neo-Tokyo Theme: Midnight abyssal purple / lavender with neon magenta and anime violet.
  static const StartupThemeOption neoTokyo = StartupThemeOption(
    id: 'neo_tokyo',
    name: 'Neo-Tokyo',
    darkColors: [
      Color(0xFF120E1C), // Fondo principal (púrpura abisal nocturno)
      Color(0xFF1F1A2F), // Fondo secundario / Superficie
      Color(0xFFECE8F6), // Texto normal (blanco lavanda)
      Color(0xFFFF2A85), // Color de acento principal (Magenta neón)
      Color(0xFF7D7595), // Texto atenuado / Subtexto (gris malva)
    ],
    lightColors: [
      Color(0xFFFAF7FC), // Fondo principal (blanco lavanda ultra pálido)
      Color(0xFFFFFFFF), // Fondo secundario / Superficie
      Color(0xFF261C33), // Texto normal (ciruela profundo)
      Color(0xFF8353E2), // Color de acento principal (Violeta anime)
      Color(0xFF756C84), // Texto atenuado / Subtexto (malva medio)
    ],
  );

  /// Monochrome Theme: The foundational Project Anima aesthetic.
  static const StartupThemeOption monochrome = StartupThemeOption(
    id: 'monochrome',
    name: 'Monochrome',
    darkColors: [
      Color(0xFF0E0E10), // Deep Screen Background
      Color(0xFF1A1A1E), // Elevated Surface Container
      Color(0xFF242429), // Surface Container High
      Color(0xFF8E8E96), // Outline / Mid-tone Variant
      Color(0xFFF2F2F2), // Pure White / High-Impact Foreground
    ],
    lightColors: [
      Color(0xFFF5F5F7), // Light Background
      Color(0xFFFFFFFF), // Clean Surface
      Color(0xFFE5E5EA), // Surface High
      Color(0xFF6E6E73), // Subtle Outline
      Color(0xFF0E0E10), // Deep Black Text
    ],
  );

  /// All selectable theme options in visual presentation order:
  /// Monochrome, That Pad, Neo-Tokyo, Solar, Corporate.
  static const List<StartupThemeOption> all = [
    monochrome,
    thatPad,
    neoTokyo,
    solar,
    corporate,
  ];
}
