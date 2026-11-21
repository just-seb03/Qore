/// File: theme_controller.dart
/// Description: Centralized theme manager coordinating the active Monochrome theme
/// and brightness mode (Dark / Light) with reactive change notifications.
///
/// Components / Classes / Functions:
/// - ThemeController: Singleton ChangeNotifier managing active AppThemePalette and ThemeData.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/database/dao/app_metadata_dao.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';
import 'package:project_anima/core/theme/monochrome/dark/monochrome_dark_theme.dart';
import 'package:project_anima/core/theme/monochrome/light/monochrome_light_theme.dart';

/// Centralized state manager for application themes and brightness switching.
/// Automatically observes device platform brightness changes to dynamically sync
/// between Monochrome Dark and Light themes.
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController._internal();

  /// Global singleton instance.
  static final ThemeController instance = ThemeController._internal();

  static final Map<String, Map<bool, AppThemePalette>> _registry = {
    'monochrome': {
      true: MonochromeDarkTheme.palette,
      false: MonochromeLightTheme.palette,
    },
  };

  String _activeFamily = 'monochrome';
  bool _isDarkMode = true;
  bool _hasManualBrightnessOverride = false;
  bool _initialized = false;
  bool _observerRegistered = false;

  /// Ordered list of available theme family identifiers.
  List<String> get availableFamilies => const [
        'monochrome',
      ];

  /// Active theme family identifier.
  String get activeFamily => _activeFamily;

  /// Whether dark mode is currently selected.
  bool get isDarkMode => _isDarkMode;

  /// Whether controller has loaded persisted theme preferences.
  bool get isInitialized => _initialized;

  /// Active theme palette tokens.
  AppThemePalette get currentPalette {
    final familyMap = _registry[_activeFamily] ?? _registry['monochrome']!;
    return familyMap[_isDarkMode] ?? MonochromeDarkTheme.palette;
  }

  /// Active cached [ThemeData] for [MaterialApp].
  ThemeData get currentThemeData => currentPalette.toThemeData();

  /// Ensures platform brightness observer is registered.
  void ensureObserver() {
    if (!_observerRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _observerRegistered = true;
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (!_hasManualBrightnessOverride) {
      syncWithSystemBrightness();
    }
  }

  /// Synchronizes active dark/light mode with the device platform brightness.
  void syncWithSystemBrightness([Brightness? platformBrightness]) {
    final brightness = platformBrightness ??
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark = brightness == Brightness.dark;
    _updateSystemUIOverlay(isDark);
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      AppMetadataDao.instance.setIsDarkMode(isDark);
      notifyListeners();
    }
  }

  void _updateSystemUIOverlay(bool isDark) {
    try {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
      );
    } catch (_) {
      // In non-GUI or unit test environments, SystemChrome may not be initialized.
    }
  }

  /// Initializes the active theme from persistent metadata and syncs with system brightness.
  Future<void> init({
    AppMetadataDao? appMetadataDao,
    bool syncWithSystem = true,
  }) async {
    final dao = appMetadataDao ?? AppMetadataDao.instance;
    ensureObserver();
    try {
      final savedFamily = await dao.getThemeFamily();
      if (savedFamily != null && _registry.containsKey(savedFamily)) {
        _activeFamily = savedFamily;
      }
      final savedDark = await dao.getIsDarkMode();
      if (savedDark != null) {
        _isDarkMode = savedDark;
        _hasManualBrightnessOverride = true;
        _updateSystemUIOverlay(_isDarkMode);
      } else if (syncWithSystem) {
        syncWithSystemBrightness();
      }
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ [ThemeController] Error initializing theme: $e');
    }
  }

  @override
  void dispose() {
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _observerRegistered = false;
    }
    super.dispose();
  }

  /// Retrieves a specific theme palette by family and brightness.
  AppThemePalette getPalette(String family, {required bool isDark}) {
    final familyMap = _registry[family] ?? _registry['monochrome']!;
    return familyMap[isDark] ?? currentPalette;
  }

  /// Sets the active theme family and optionally updates brightness mode.
  void setTheme(String family, {bool? isDark}) {
    bool changed = false;
    if (_registry.containsKey(family)) {
      if (_activeFamily != family) {
        _activeFamily = family;
        changed = true;
      }
      AppMetadataDao.instance.setThemeFamily(family);
    }
    if (isDark != null) {
      _hasManualBrightnessOverride = true;
      AppMetadataDao.instance.setIsDarkMode(isDark);
      if (_isDarkMode != isDark) {
        _isDarkMode = isDark;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Updates the brightness mode between Dark and Light.
  void setDarkMode(bool isDark) {
    _hasManualBrightnessOverride = true;
    AppMetadataDao.instance.setIsDarkMode(isDark);
    _updateSystemUIOverlay(isDark);
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
    }
  }

  /// Toggles between Dark and Light mode.
  void toggleBrightness() {
    _hasManualBrightnessOverride = true;
    _isDarkMode = !_isDarkMode;
    _updateSystemUIOverlay(_isDarkMode);
    AppMetadataDao.instance.setIsDarkMode(_isDarkMode);
    notifyListeners();
  }
}
