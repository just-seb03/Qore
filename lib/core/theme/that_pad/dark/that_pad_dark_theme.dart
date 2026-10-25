/// File: that_pad_dark_theme.dart
/// Description: That Pad Dark theme inspired by industrial workstation aesthetics.
/// Deep matte black chassis, high contrast white reading typography, and TrackPoint red accents.
///
/// Components / Classes / Functions:
/// - ThatPadDarkTheme: Implementation of [AppThemePalette] for That Pad Dark.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';

/// That Pad Dark color palette implementation.
class ThatPadDarkTheme extends AppThemePalette {
  const ThatPadDarkTheme();

  static const ThatPadDarkTheme palette = ThatPadDarkTheme();

  @override
  String get id => 'that_pad_dark';

  @override
  String get family => 'that_pad';

  @override
  String get name => 'That Pad';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  List<Color> get constituentColors => const [
        Color(0xFF121212), // 1. Fondo principal (chasis mate)
        Color(0xFF1E1E1E), // 2. Fondo secundario / Superficie
        Color(0xFFE6E6E6), // 3. Texto normal (blanco mate)
        Color(0xFFE11422), // 4. Color de acento principal (TrackPoint Red)
        Color(0xFF8A8A8A), // 5. Texto atenuado / Subtexto
      ];

  @override
  Color get background => const Color(0xFF121212);

  @override
  Color get surface => const Color(0xFF1E1E1E);

  @override
  Color get surfaceContainer => const Color(0xFF262626);

  @override
  Color get surfaceContainerHigh => const Color(0xFF303030);

  @override
  Color get surfaceContainerHighest => const Color(0xFF3A3A3A);

  @override
  Color get outline => const Color(0xFF404040);

  @override
  Color get outlineVariant => const Color(0xFF2A2A2A);

  @override
  Color get onBackground => const Color(0xFFE6E6E6);

  @override
  Color get onSurface => const Color(0xFFE6E6E6);

  @override
  Color get onSurfaceVariant => const Color(0xFF8A8A8A);

  @override
  Color get onSurfaceDisabled => const Color(0xFF555555);

  @override
  Color get accent => const Color(0xFFE11422);

  @override
  Color get onAccent => const Color(0xFFFFFFFF);

  @override
  Color get futuristicWhite => const Color(0xFFE6E6E6);

  @override
  Color get navIndicator => const Color(0xFF2E2224);

  @override
  Color get navActiveIcon => const Color(0xFFE11422);

  @override
  Color get navInactiveIcon => const Color(0xFF8A8A8A);

  @override
  Color get navActiveLabel => const Color(0xFFE11422);

  @override
  Color get navInactiveLabel => const Color(0xFF8A8A8A);

  @override
  Color get pinnedRedBackground => const Color(0xFF251012);

  @override
  Color get pinnedRedSurface => const Color(0xFF341417);

  @override
  Color get pinnedRedBorder => const Color(0x66E11422);
}
