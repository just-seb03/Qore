/// File: localization_controller.dart
/// Description: State manager for runtime application locale switching, device language auto-detection,
/// and OS locale change observation.
/// Automatically detects device language on startup and adapts reactively when system language changes.
///
/// Components / Classes / Functions:
/// - LocalizationController: Singleton ChangeNotifier coordinating active language and system detection.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_locale.dart';

/// Singleton ChangeNotifier managing the active language and device language auto-detection.
class LocalizationController extends ChangeNotifier with WidgetsBindingObserver {
  LocalizationController._internal();

  /// Global singleton instance.
  static final LocalizationController instance =
      LocalizationController._internal();

  AppLocale _currentLocale = AppLocale.en;
  bool _followSystemLocale = true;
  bool _isObserverAttached = false;

  /// The currently active [AppLocale].
  AppLocale get currentAppLocale => _currentLocale;

  /// The current Flutter [Locale].
  Locale get currentLocale => _currentLocale.flutterLocale;

  /// Whether the controller currently follows the host system / device language.
  bool get followSystemLocale => _followSystemLocale;

  /// Detects the host device's primary locale.
  /// Falls back to [AppLocale.en] when the platform locale cannot be queried.
  static AppLocale detectDeviceLocale([Locale? platformLocale]) {
    if (platformLocale != null) {
      return AppLocale.fromLocale(platformLocale);
    }
    try {
      final dispatcher = WidgetsBinding.instance.platformDispatcher;
      final deviceLocale = dispatcher.locales.isNotEmpty
          ? dispatcher.locales.first
          : dispatcher.locale;
      return AppLocale.fromLocale(deviceLocale);
    } catch (_) {
      return AppLocale.en;
    }
  }

  /// Initializes automatic language detection from the device and attaches
  /// the system locale observer.
  void init({Locale? initialDeviceLocale, bool followSystem = true}) {
    _followSystemLocale = followSystem;
    if (_followSystemLocale) {
      _currentLocale = detectDeviceLocale(initialDeviceLocale);
    }
    if (!_isObserverAttached) {
      try {
        WidgetsBinding.instance.addObserver(this);
        _isObserverAttached = true;
      } catch (_) {
        // Safe fallback in headless unit tests where WidgetsBinding may not be bound
      }
    }
  }

  /// Re-enables system locale auto-detection and synchronizes with current device language.
  void enableSystemLocale() {
    _followSystemLocale = true;
    final detected = detectDeviceLocale();
    if (_currentLocale != detected) {
      _currentLocale = detected;
      notifyListeners();
    }
  }

  /// Updates the active application locale and optionally disables system tracking.
  void setLocale(AppLocale newLocale, {bool followSystem = false}) {
    _followSystemLocale = followSystem;
    if (_currentLocale == newLocale) return;
    _currentLocale = newLocale;
    notifyListeners();
  }

  /// Updates the locale from a standard Flutter [Locale].
  void setLocaleFromFlutter(Locale locale, {bool followSystem = false}) {
    setLocale(AppLocale.fromLocale(locale), followSystem: followSystem);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (!_followSystemLocale) return;
    if (locales == null || locales.isEmpty) return;

    final newLocale = AppLocale.fromLocale(locales.first);
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isObserverAttached) {
      try {
        WidgetsBinding.instance.removeObserver(this);
        _isObserverAttached = false;
      } catch (_) {}
    }
    super.dispose();
  }
}
