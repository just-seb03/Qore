/// File: localization_controller.dart
/// Description: State manager for runtime application locale switching and persistence.
/// Notifies listeners when the language changes, triggering automatic reactive rebuilds.
///
/// Components / Classes / Functions:
/// - LocalizationController: Singleton ChangeNotifier controlling active language.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_locale.dart';

/// Singleton ChangeNotifier managing the active language and notifying UI of changes.
class LocalizationController extends ChangeNotifier {
  LocalizationController._internal();

  /// Global singleton instance.
  static final LocalizationController instance =
      LocalizationController._internal();

  AppLocale _currentLocale = AppLocale.en;

  /// The currently active [AppLocale].
  AppLocale get currentAppLocale => _currentLocale;

  /// The current Flutter [Locale].
  Locale get currentLocale => _currentLocale.flutterLocale;

  /// Updates the active application locale and notifies listening widgets.
  void setLocale(AppLocale newLocale) {
    if (_currentLocale == newLocale) return;
    _currentLocale = newLocale;
    notifyListeners();
  }

  /// Updates the locale from a standard Flutter [Locale].
  void setLocaleFromFlutter(Locale locale) {
    setLocale(AppLocale.fromLocale(locale));
  }
}
