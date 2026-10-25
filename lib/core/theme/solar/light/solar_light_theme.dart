/// File: solar_light_theme.dart
/// Description: Solar Light theme implementation based on the classic Solarized light palette.
/// Soft ivory parchment canvas with slate reading text avoiding visual fatigue.
///
/// Components / Classes / Functions:
/// - SolarLightTheme: Implementation of [AppThemePalette] for Solar Light.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';

/// Solarized Light color palette implementation.
class SolarLightTheme extends AppThemePalette {
  const SolarLightTheme();

  static const SolarLightTheme palette = SolarLightTheme();

  @override
  String get id => 'solar_light';

  @override
  String get family => 'solar';

  @override
  String get name => 'Solar';

  @override
  Brightness get brightness => Brightness.light;

  @override
  List<Color> get constituentColors => const [
        Color(0xFFFDF6E3), // 1. Fondo principal
        Color(0xFFEEE8D5), // 2. Fondo secundario / Superficie
        Color(0xFF657B83), // 3. Texto normal
        Color(0xFF586E75), // 4. Texto destacado / Énfasis
        Color(0xFF93A1A1), // 5. Texto atenuado / Subtexto
      ];

  @override
  Color get background => const Color(0xFFFDF6E3);

  @override
  Color get surface => const Color(0xFFEEE8D5);

  @override
  Color get surfaceContainer => const Color(0xFFE4DEC8);

  @override
  Color get surfaceContainerHigh => const Color(0xFFDACFA8);

  @override
  Color get surfaceContainerHighest => const Color(0xFFD2C798);

  @override
  Color get outline => const Color(0xFFC4B892);

  @override
  Color get outlineVariant => const Color(0xFFE2D9BC);

  @override
  Color get onBackground => const Color(0xFF657B83);

  @override
  Color get onSurface => const Color(0xFF657B83);

  @override
  Color get onSurfaceVariant => const Color(0xFF93A1A1);

  @override
  Color get onSurfaceDisabled => const Color(0xFFB8C2C2);

  @override
  Color get accent => const Color(0xFF586E75);

  @override
  Color get onAccent => const Color(0xFFFDF6E3);

  @override
  Color get futuristicWhite => const Color(0xFF586E75);

  @override
  Color get navIndicator => const Color(0xFFE0D8BC);

  @override
  Color get navActiveIcon => const Color(0xFF586E75);

  @override
  Color get navInactiveIcon => const Color(0xFF93A1A1);

  @override
  Color get navActiveLabel => const Color(0xFF586E75);

  @override
  Color get navInactiveLabel => const Color(0xFF93A1A1);

  @override
  Color get pinnedRedBackground => const Color(0xFFF5E4E4);

  @override
  Color get pinnedRedSurface => const Color(0xFFEED0D0);

  @override
  Color get pinnedRedBorder => const Color(0x66DC322F);
}
