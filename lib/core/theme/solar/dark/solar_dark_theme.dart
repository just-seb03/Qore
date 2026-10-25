/// File: solar_dark_theme.dart
/// Description: Solar Dark theme implementation based on the classic Solarized dark palette.
/// Low-contrast, eye-strain reducing dark theme with deep teal/cyan background.
///
/// Components / Classes / Functions:
/// - SolarDarkTheme: Implementation of [AppThemePalette] for Solar Dark.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';

/// Solarized Dark color palette implementation.
class SolarDarkTheme extends AppThemePalette {
  const SolarDarkTheme();

  static const SolarDarkTheme palette = SolarDarkTheme();

  @override
  String get id => 'solar_dark';

  @override
  String get family => 'solar';

  @override
  String get name => 'Solar';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  List<Color> get constituentColors => const [
        Color(0xFF002B36), // 1. Fondo principal
        Color(0xFF073642), // 2. Fondo secundario / Superficie
        Color(0xFF839496), // 3. Texto normal
        Color(0xFF93A1A1), // 4. Texto destacado / Énfasis
        Color(0xFF586E75), // 5. Texto atenuado / Subtexto
      ];

  @override
  Color get background => const Color(0xFF002B36);

  @override
  Color get surface => const Color(0xFF073642);

  @override
  Color get surfaceContainer => const Color(0xFF0B4352);

  @override
  Color get surfaceContainerHigh => const Color(0xFF104F60);

  @override
  Color get surfaceContainerHighest => const Color(0xFF175D70);

  @override
  Color get outline => const Color(0xFF225866);

  @override
  Color get outlineVariant => const Color(0xFF073642);

  @override
  Color get onBackground => const Color(0xFF839496);

  @override
  Color get onSurface => const Color(0xFF839496);

  @override
  Color get onSurfaceVariant => const Color(0xFF586E75);

  @override
  Color get onSurfaceDisabled => const Color(0xFF384E55);

  @override
  Color get accent => const Color(0xFF93A1A1);

  @override
  Color get onAccent => const Color(0xFF002B36);

  @override
  Color get futuristicWhite => const Color(0xFF93A1A1);

  @override
  Color get navIndicator => const Color(0xFF0B4352);

  @override
  Color get navActiveIcon => const Color(0xFF93A1A1);

  @override
  Color get navInactiveIcon => const Color(0xFF586E75);

  @override
  Color get navActiveLabel => const Color(0xFF93A1A1);

  @override
  Color get navInactiveLabel => const Color(0xFF586E75);

  @override
  Color get pinnedRedBackground => const Color(0xFF1F2228);

  @override
  Color get pinnedRedSurface => const Color(0xFF2E242C);

  @override
  Color get pinnedRedBorder => const Color(0x66DC322F);
}
