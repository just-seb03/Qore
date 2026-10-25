/// File: theme_controller.dart
/// Description: Centralized theme manager coordinating active theme families (Solar, That Pad,
/// Corporate, Neo-Tokyo, Monochrome) and brightness mode (Dark / Light) with reactive change notifications.
///
/// Components / Classes / Functions:
/// - ThemeController: Singleton ChangeNotifier managing active AppThemePalette and ThemeData.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';
import 'package:project_anima/core/theme/corporate/dark/corporate_dark_theme.dart';
import 'package:project_anima/core/theme/corporate/light/corporate_light_theme.dart';
import 'package:project_anima/core/theme/monochrome/dark/monochrome_dark_theme.dart';
import 'package:project_anima/core/theme/monochrome/light/monochrome_light_theme.dart';
import 'package:project_anima/core/theme/neo_tokyo/dark/neo_tokyo_dark_theme.dart';
import 'package:project_anima/core/theme/neo_tokyo/light/neo_tokyo_light_theme.dart';
import 'package:project_anima/core/theme/solar/dark/solar_dark_theme.dart';
import 'package:project_anima/core/theme/solar/light/solar_light_theme.dart';
import 'package:project_anima/core/theme/that_pad/dark/that_pad_dark_theme.dart';
import 'package:project_anima/core/theme/that_pad/light/that_pad_light_theme.dart';

/// Centralized state manager for application themes and brightness switching.
class ThemeController extends ChangeNotifier {
  ThemeController._internal();

  /// Global singleton instance.
  static final ThemeController instance = ThemeController._internal();

  static final Map<String, Map<bool, AppThemePalette>> _registry = {
    'monochrome': {
      true: MonochromeDarkTheme.palette,
      false: MonochromeLightTheme.palette,
    },
    'solar': {
      true: SolarDarkTheme.palette,
      false: SolarLightTheme.palette,
    },
    'that_pad': {
      true: ThatPadDarkTheme.palette,
      false: ThatPadLightTheme.palette,
    },
    'corporate': {
      true: CorporateDarkTheme.palette,
      false: CorporateLightTheme.palette,
    },
    'neo_tokyo': {
      true: NeoTokyoDarkTheme.palette,
      false: NeoTokyoLightTheme.palette,
    },
  };

  String _activeFamily = 'monochrome';
  bool _isDarkMode = true;

  /// Ordered list of available theme family identifiers.
  List<String> get availableFamilies => const [
        'monochrome',
        'solar',
        'that_pad',
        'corporate',
        'neo_tokyo',
      ];

  /// Active theme family identifier.
  String get activeFamily => _activeFamily;

  /// Whether dark mode is currently selected.
  bool get isDarkMode => _isDarkMode;

  /// Active theme palette tokens.
  AppThemePalette get currentPalette {
    final familyMap = _registry[_activeFamily] ?? _registry['monochrome']!;
    return familyMap[_isDarkMode] ?? MonochromeDarkTheme.palette;
  }

  /// Active cached [ThemeData] for [MaterialApp].
  ThemeData get currentThemeData => currentPalette.toThemeData();

  /// Retrieves a specific theme palette by family and brightness.
  AppThemePalette getPalette(String family, {required bool isDark}) {
    final familyMap = _registry[family] ?? _registry['monochrome']!;
    return familyMap[isDark] ?? currentPalette;
  }

  /// Sets the active theme family and optionally updates brightness mode.
  void setTheme(String family, {bool? isDark}) {
    bool changed = false;
    if (_registry.containsKey(family) && _activeFamily != family) {
      _activeFamily = family;
      changed = true;
    }
    if (isDark != null && _isDarkMode != isDark) {
      _isDarkMode = isDark;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Updates the brightness mode between Dark and Light.
  void setDarkMode(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
    }
  }

  /// Toggles between Dark and Light mode.
  void toggleBrightness() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
