/// File: neo_tokyo_dark_theme.dart
/// Description: Neo-Tokyo Dark theme featuring an abyssal midnight purple canvas,
/// lavender white reading text, and neon cyberpunk magenta accents.
///
/// Components / Classes / Functions:
/// - NeoTokyoDarkTheme: Implementation of [AppThemePalette] for Neo-Tokyo Dark.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';

/// Neo-Tokyo Dark cyberpunk color palette implementation.
class NeoTokyoDarkTheme extends AppThemePalette {
  const NeoTokyoDarkTheme();

  static const NeoTokyoDarkTheme palette = NeoTokyoDarkTheme();

  @override
  String get id => 'neo_tokyo_dark';

  @override
  String get family => 'neo_tokyo';

  @override
  String get name => 'Neo-Tokyo';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  List<Color> get constituentColors => const [
        Color(0xFF120E1C), // 1. Fondo principal (púrpura abisal nocturno)
        Color(0xFF1F1A2F), // 2. Fondo secundario / Superficie
        Color(0xFFECE8F6), // 3. Texto normal (blanco lavanda)
        Color(0xFFFF2A85), // 4. Color de acento principal (Magenta neón)
        Color(0xFF7D7595), // 5. Texto atenuado / Subtexto (gris malva)
      ];

  @override
  Color get background => const Color(0xFF120E1C);

  @override
  Color get surface => const Color(0xFF1F1A2F);

  @override
  Color get surfaceContainer => const Color(0xFF2A233D);

  @override
  Color get surfaceContainerHigh => const Color(0xFF352D4D);

  @override
  Color get surfaceContainerHighest => const Color(0xFF41375E);

  @override
  Color get outline => const Color(0xFF4C406B);

  @override
  Color get outlineVariant => const Color(0xFF2A233D);

  @override
  Color get onBackground => const Color(0xFFECE8F6);

  @override
  Color get onSurface => const Color(0xFFECE8F6);

  @override
  Color get onSurfaceVariant => const Color(0xFF7D7595);

  @override
  Color get onSurfaceDisabled => const Color(0xFF524B63);

  @override
  Color get accent => const Color(0xFFFF2A85);

  @override
  Color get onAccent => const Color(0xFFFFFFFF);

  @override
  Color get futuristicWhite => const Color(0xFFECE8F6);

  @override
  Color get navIndicator => const Color(0xFF3B1E38);

  @override
  Color get navActiveIcon => const Color(0xFFFF2A85);

  @override
  Color get navInactiveIcon => const Color(0xFF7D7595);

  @override
  Color get navActiveLabel => const Color(0xFFFF2A85);

  @override
  Color get navInactiveLabel => const Color(0xFF7D7595);

  @override
  Color get pinnedRedBackground => const Color(0xFF2A101C);

  @override
  Color get pinnedRedSurface => const Color(0xFF381527);

  @override
  Color get pinnedRedBorder => const Color(0x66FF2A85);
}
