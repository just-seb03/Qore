/// File: corporate_dark_theme.dart
/// Description: Corporate Dark theme presenting a balanced modern dark slate aesthetic
/// with pastel blue focus elements and comfortable reading contrast.
///
/// Components / Classes / Functions:
/// - CorporateDarkTheme: Implementation of [AppThemePalette] for Corporate Dark.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';

/// Corporate Dark color palette implementation.
class CorporateDarkTheme extends AppThemePalette {
  const CorporateDarkTheme();

  static const CorporateDarkTheme palette = CorporateDarkTheme();

  @override
  String get id => 'corporate_dark';

  @override
  String get family => 'corporate';

  @override
  String get name => 'Corporate';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  List<Color> get constituentColors => const [
        Color(0xFF1E1F20), // 1. Fondo principal
        Color(0xFF282A2C), // 2. Fondo secundario / Superficie
        Color(0xFFE3E3E3), // 3. Texto normal
        Color(0xFF8AB4F8), // 4. Color de acento principal (Azul suave pastel)
        Color(0xFF8E918F), // 5. Texto atenuado / Subtexto
      ];

  @override
  Color get background => const Color(0xFF1E1F20);

  @override
  Color get surface => const Color(0xFF282A2C);

  @override
  Color get surfaceContainer => const Color(0xFF313336);

  @override
  Color get surfaceContainerHigh => const Color(0xFF3B3E41);

  @override
  Color get surfaceContainerHighest => const Color(0xFF45484C);

  @override
  Color get outline => const Color(0xFF505459);

  @override
  Color get outlineVariant => const Color(0xFF313336);

  @override
  Color get onBackground => const Color(0xFFE3E3E3);

  @override
  Color get onSurface => const Color(0xFFE3E3E3);

  @override
  Color get onSurfaceVariant => const Color(0xFF8E918F);

  @override
  Color get onSurfaceDisabled => const Color(0xFF5A5D61);

  @override
  Color get accent => const Color(0xFF8AB4F8);

  @override
  Color get onAccent => const Color(0xFF1E1F20);

  @override
  Color get futuristicWhite => const Color(0xFFE3E3E3);

  @override
  Color get navIndicator => const Color(0xFF2F3C50);

  @override
  Color get navActiveIcon => const Color(0xFF8AB4F8);

  @override
  Color get navInactiveIcon => const Color(0xFF8E918F);

  @override
  Color get navActiveLabel => const Color(0xFF8AB4F8);

  @override
  Color get navInactiveLabel => const Color(0xFF8E918F);

  @override
  Color get pinnedRedBackground => const Color(0xFF2B1D20);

  @override
  Color get pinnedRedSurface => const Color(0xFF3A2429);

  @override
  Color get pinnedRedBorder => const Color(0x66F28B82);
}
