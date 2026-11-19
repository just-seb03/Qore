/// File: monochrome_dark_theme.dart
/// Description: Monochromatic Dark theme matching Project Anima's core cinematic design system.
///
/// Components / Classes / Functions:
/// - MonochromeDarkTheme: Implementation of [AppThemePalette] for Monochrome Dark.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';

/// Monochromatic Dark color palette implementation.
class MonochromeDarkTheme extends AppThemePalette {
  const MonochromeDarkTheme();

  static const MonochromeDarkTheme palette = MonochromeDarkTheme();

  @override
  String get id => 'monochrome_dark';

  @override
  String get family => 'monochrome';

  @override
  String get name => 'Monochrome';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  List<Color> get constituentColors => const [
        Color(0xFF0E0E10), // 1. Deep Screen Background
        Color(0xFF1A1A1E), // 2. Elevated Surface Container
        Color(0xFF242429), // 3. Surface Container High
        Color(0xFF8E8E96), // 4. Outline / Mid-tone Variant
        Color(0xFF5BABCE), // 5. Brand Accent (#5BABCE)
      ];

  @override
  Color get background => const Color(0xFF0E0E10);

  @override
  Color get surface => const Color(0xFF141417);

  @override
  Color get surfaceContainer => const Color(0xFF1A1A1E);

  @override
  Color get surfaceContainerHigh => const Color(0xFF242429);

  @override
  Color get surfaceContainerHighest => const Color(0xFF2E2E34);

  @override
  Color get outline => const Color(0xFF2A2A30);

  @override
  Color get outlineVariant => const Color(0xFF1C1C21);

  @override
  Color get onBackground => const Color(0xFFF2F2F2);

  @override
  Color get onSurface => const Color(0xFFF2F2F2);

  @override
  Color get onSurfaceVariant => const Color(0xFF8E8E96);

  @override
  Color get onSurfaceDisabled => const Color(0xFF4A4A52);

  @override
  Color get accent => const Color(0xFF5BABCE);

  @override
  Color get onAccent => const Color(0xFF0E0E10);

  @override
  Color get futuristicWhite => const Color(0xFF5BABCE);

  @override
  Color get navIndicator => const Color(0xFF28282E);

  @override
  Color get navActiveIcon => const Color(0xFF5BABCE);

  @override
  Color get navInactiveIcon => const Color(0xFF7E7E88);

  @override
  Color get navActiveLabel => const Color(0xFF5BABCE);

  @override
  Color get navInactiveLabel => const Color(0xFF7E7E88);

  @override
  Color get pinnedRedBackground => const Color(0xFF1E0E10);

  @override
  Color get pinnedRedSurface => const Color(0xFF281215);

  @override
  Color get pinnedRedBorder => const Color(0x66E53935);
}
