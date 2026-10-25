/// File: corporate_light_theme.dart
/// Description: Corporate Light theme presenting a clean crisp professional aesthetic
/// with clean white floating cards and corporate blue highlights.
///
/// Components / Classes / Functions:
/// - CorporateLightTheme: Implementation of [AppThemePalette] for Corporate Light.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';

/// Corporate Light color palette implementation.
class CorporateLightTheme extends AppThemePalette {
  const CorporateLightTheme();

  static const CorporateLightTheme palette = CorporateLightTheme();

  @override
  String get id => 'corporate_light';

  @override
  String get family => 'corporate';

  @override
  String get name => 'Corporate';

  @override
  Brightness get brightness => Brightness.light;

  @override
  List<Color> get constituentColors => const [
        Color(0xFFF8F9FA), // 1. Fondo principal
        Color(0xFFFFFFFF), // 2. Fondo secundario / Superficie
        Color(0xFF1F1F1F), // 3. Texto normal
        Color(0xFF1A73E8), // 4. Color de acento principal (Azul corporativo)
        Color(0xFF5F6368), // 5. Texto atenuado / Subtexto
      ];

  @override
  Color get background => const Color(0xFFF8F9FA);

  @override
  Color get surface => const Color(0xFFFFFFFF);

  @override
  Color get surfaceContainer => const Color(0xFFF1F3F4);

  @override
  Color get surfaceContainerHigh => const Color(0xFFE8EAED);

  @override
  Color get surfaceContainerHighest => const Color(0xFFDADCE0);

  @override
  Color get outline => const Color(0xFFBDC1C6);

  @override
  Color get outlineVariant => const Color(0xFFE8EAED);

  @override
  Color get onBackground => const Color(0xFF1F1F1F);

  @override
  Color get onSurface => const Color(0xFF1F1F1F);

  @override
  Color get onSurfaceVariant => const Color(0xFF5F6368);

  @override
  Color get onSurfaceDisabled => const Color(0xFF9AA0A6);

  @override
  Color get accent => const Color(0xFF1A73E8);

  @override
  Color get onAccent => const Color(0xFFFFFFFF);

  @override
  Color get futuristicWhite => const Color(0xFF1F1F1F);

  @override
  Color get navIndicator => const Color(0xFFE8F0FE);

  @override
  Color get navActiveIcon => const Color(0xFF1A73E8);

  @override
  Color get navInactiveIcon => const Color(0xFF5F6368);

  @override
  Color get navActiveLabel => const Color(0xFF1A73E8);

  @override
  Color get navInactiveLabel => const Color(0xFF5F6368);

  @override
  Color get pinnedRedBackground => const Color(0xFFFCE8E6);

  @override
  Color get pinnedRedSurface => const Color(0xFFFAD2CF);

  @override
  Color get pinnedRedBorder => const Color(0x66D93025);
}
