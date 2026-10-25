/// File: neo_tokyo_light_theme.dart
/// Description: Neo-Tokyo Light theme featuring an ultra-pale lavender white canvas,
/// deep plum reading typography, clean white surfaces, and vibrant anime violet accents.
///
/// Components / Classes / Functions:
/// - NeoTokyoLightTheme: Implementation of [AppThemePalette] for Neo-Tokyo Light.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';

/// Neo-Tokyo Light anime/cyberpunk color palette implementation.
class NeoTokyoLightTheme extends AppThemePalette {
  const NeoTokyoLightTheme();

  static const NeoTokyoLightTheme palette = NeoTokyoLightTheme();

  @override
  String get id => 'neo_tokyo_light';

  @override
  String get family => 'neo_tokyo';

  @override
  String get name => 'Neo-Tokyo';

  @override
  Brightness get brightness => Brightness.light;

  @override
  List<Color> get constituentColors => const [
        Color(0xFFFAF7FC), // 1. Fondo principal (blanco lavanda ultra pálido)
        Color(0xFFFFFFFF), // 2. Fondo secundario / Superficie
        Color(0xFF261C33), // 3. Texto normal (ciruela profundo)
        Color(0xFF8353E2), // 4. Color de acento principal (Violeta anime)
        Color(0xFF756C84), // 5. Texto atenuado / Subtexto (malva medio)
      ];

  @override
  Color get background => const Color(0xFFFAF7FC);

  @override
  Color get surface => const Color(0xFFFFFFFF);

  @override
  Color get surfaceContainer => const Color(0xFFF1ECF7);

  @override
  Color get surfaceContainerHigh => const Color(0xFFE8E0F2);

  @override
  Color get surfaceContainerHighest => const Color(0xFFDDD2EB);

  @override
  Color get outline => const Color(0xFFC4B8D8);

  @override
  Color get outlineVariant => const Color(0xFFE8E0F2);

  @override
  Color get onBackground => const Color(0xFF261C33);

  @override
  Color get onSurface => const Color(0xFF261C33);

  @override
  Color get onSurfaceVariant => const Color(0xFF756C84);

  @override
  Color get onSurfaceDisabled => const Color(0xFFA59EB3);

  @override
  Color get accent => const Color(0xFF8353E2);

  @override
  Color get onAccent => const Color(0xFFFFFFFF);

  @override
  Color get futuristicWhite => const Color(0xFF261C33);

  @override
  Color get navIndicator => const Color(0xFFECE4FA);

  @override
  Color get navActiveIcon => const Color(0xFF8353E2);

  @override
  Color get navInactiveIcon => const Color(0xFF756C84);

  @override
  Color get navActiveLabel => const Color(0xFF8353E2);

  @override
  Color get navInactiveLabel => const Color(0xFF756C84);

  @override
  Color get pinnedRedBackground => const Color(0xFFFCEBF2);

  @override
  Color get pinnedRedSurface => const Color(0xFFF7D7E4);

  @override
  Color get pinnedRedBorder => const Color(0x66FF2A85);
}
