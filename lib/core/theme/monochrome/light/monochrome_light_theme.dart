/// File: monochrome_light_theme.dart
/// Description: Monochromatic Light theme with clean minimalist gray/white surfaces
/// and deep black typography.
///
/// Components / Classes / Functions:
/// - MonochromeLightTheme: Implementation of [AppThemePalette] for Monochrome Light.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';

/// Monochromatic Light color palette implementation.
class MonochromeLightTheme extends AppThemePalette {
  const MonochromeLightTheme();

  static const MonochromeLightTheme palette = MonochromeLightTheme();

  @override
  String get id => 'monochrome_light';

  @override
  String get family => 'monochrome';

  @override
  String get name => 'Monochrome';

  @override
  Brightness get brightness => Brightness.light;

  @override
  List<Color> get constituentColors => const [
        Color(0xFFF5F5F7), // 1. Fondo principal
        Color(0xFFFFFFFF), // 2. Fondo secundario / Superficie
        Color(0xFFE5E5EA), // 3. Superficie elevada
        Color(0xFF6E6E73), // 4. Texto atenuado / Subtexto
        Color(0xFF0E0E10), // 5. Negro profundo
      ];

  @override
  Color get background => const Color(0xFFF5F5F7);

  @override
  Color get surface => const Color(0xFFFFFFFF);

  @override
  Color get surfaceContainer => const Color(0xFFEBEBF0);

  @override
  Color get surfaceContainerHigh => const Color(0xFFE1E1E6);

  @override
  Color get surfaceContainerHighest => const Color(0xFFD6D6DC);

  @override
  Color get outline => const Color(0xFFC7C7CC);

  @override
  Color get outlineVariant => const Color(0xFFE5E5EA);

  @override
  Color get onBackground => const Color(0xFF0E0E10);

  @override
  Color get onSurface => const Color(0xFF0E0E10);

  @override
  Color get onSurfaceVariant => const Color(0xFF6E6E73);

  @override
  Color get onSurfaceDisabled => const Color(0xFFA1A1A6);

  @override
  Color get accent => const Color(0xFF0E0E10);

  @override
  Color get onAccent => const Color(0xFFF5F5F7);

  @override
  Color get futuristicWhite => const Color(0xFF0E0E10);

  @override
  Color get navIndicator => const Color(0xFFE5E5EA);

  @override
  Color get navActiveIcon => const Color(0xFF0E0E10);

  @override
  Color get navInactiveIcon => const Color(0xFF6E6E73);

  @override
  Color get navActiveLabel => const Color(0xFF0E0E10);

  @override
  Color get navInactiveLabel => const Color(0xFF6E6E73);

  @override
  Color get pinnedRedBackground => const Color(0xFFFDF0F0);

  @override
  Color get pinnedRedSurface => const Color(0xFFFBE2E2);

  @override
  Color get pinnedRedBorder => const Color(0x66E53935);
}
