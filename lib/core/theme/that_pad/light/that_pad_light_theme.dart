/// File: that_pad_light_theme.dart
/// Description: That Pad Light theme with anodized aluminum silver canvas,
/// crisp carbon ink typography, pure white surfaces, and TrackPoint red highlights.
///
/// Components / Classes / Functions:
/// - ThatPadLightTheme: Implementation of [AppThemePalette] for That Pad Light.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';

/// That Pad Light color palette implementation.
class ThatPadLightTheme extends AppThemePalette {
  const ThatPadLightTheme();

  static const ThatPadLightTheme palette = ThatPadLightTheme();

  @override
  String get id => 'that_pad_light';

  @override
  String get family => 'that_pad';

  @override
  String get name => 'That Pad';

  @override
  Brightness get brightness => Brightness.light;

  @override
  List<Color> get constituentColors => const [
        Color(0xFFF3F4F6), // 1. Fondo principal (aluminio anodizado)
        Color(0xFFFFFFFF), // 2. Fondo secundario / Superficie
        Color(0xFF1A1D20), // 3. Texto normal (carbón oscuro)
        Color(0xFFD31220), // 4. Color de acento principal (TrackPoint Red)
        Color(0xFF5F6368), // 5. Texto atenuado / Subtexto
      ];

  @override
  Color get background => const Color(0xFFF3F4F6);

  @override
  Color get surface => const Color(0xFFFFFFFF);

  @override
  Color get surfaceContainer => const Color(0xFFEBECEF);

  @override
  Color get surfaceContainerHigh => const Color(0xFFE2E4E8);

  @override
  Color get surfaceContainerHighest => const Color(0xFFD8DBE0);

  @override
  Color get outline => const Color(0xFFC8CBD0);

  @override
  Color get outlineVariant => const Color(0xFFE0E2E6);

  @override
  Color get onBackground => const Color(0xFF1A1D20);

  @override
  Color get onSurface => const Color(0xFF1A1D20);

  @override
  Color get onSurfaceVariant => const Color(0xFF5F6368);

  @override
  Color get onSurfaceDisabled => const Color(0xFF9AA0A6);

  @override
  Color get accent => const Color(0xFFD31220);

  @override
  Color get onAccent => const Color(0xFFFFFFFF);

  @override
  Color get futuristicWhite => const Color(0xFF1A1D20);

  @override
  Color get navIndicator => const Color(0xFFFADBDC);

  @override
  Color get navActiveIcon => const Color(0xFFD31220);

  @override
  Color get navInactiveIcon => const Color(0xFF5F6368);

  @override
  Color get navActiveLabel => const Color(0xFFD31220);

  @override
  Color get navInactiveLabel => const Color(0xFF5F6368);

  @override
  Color get pinnedRedBackground => const Color(0xFFFDF0F1);

  @override
  Color get pinnedRedSurface => const Color(0xFFF8DCE0);

  @override
  Color get pinnedRedBorder => const Color(0x66D31220);
}
