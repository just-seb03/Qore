/// File: app_localizations.dart
/// Description: Main Flutter Localizations coordinator and delegate for Project Anima.
/// Exposes type-safe access to localized string contracts via [BuildContext] extension
/// or static lookup, backed by compile-time constant translation dictionaries.
///
/// Components / Classes / Functions:
/// - AppLocalizations: Core localizations class and factory.
/// - _AppLocalizationsDelegate: Flutter LocalizationsDelegate implementation.
/// - AppLocalizationsX: Convenience extension on [BuildContext] providing `context.l10n`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_locale.dart';
import 'package:project_anima/core/localization/contracts/app_strings.dart';
import 'package:project_anima/core/localization/translations/en/en_strings.dart';

export 'package:project_anima/core/localization/app_locale.dart';
export 'package:project_anima/core/localization/contracts/app_strings.dart';

/// Central localizations coordinator holding the active [AppStrings] implementation.
class AppLocalizations {
  /// The active [Locale] for this instance.
  final Locale locale;

  /// The active typed [AppStrings] bundle.
  final AppStrings strings;

  const AppLocalizations(this.locale, this.strings);

  /// Default English singleton instance for zero-allocation fallbacks.
  static const AppStrings defaultStrings = EnStrings();

  /// Resolves the current [AppStrings] from the given [BuildContext].
  ///
  /// Example:
  /// ```dart
  /// final title = AppLocalizations.of(context).album.tracksHeader;
  /// ```
  static AppStrings of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    return localizations?.strings ?? defaultStrings;
  }

  /// Factory creating an [AppLocalizations] instance for the requested [Locale].
  /// Falls back to English [EnStrings] when a locale is not yet fully implemented.
  static AppLocalizations load(Locale locale) {
    final appLocale = AppLocale.fromLocale(locale);
    switch (appLocale) {
      case AppLocale.en:
        return AppLocalizations(locale, const EnStrings());
      case AppLocale.es:
        // Spanish strings will be plugged in here once implemented.
        // Falls back to EnStrings safely to ensure zero crash or missing key risks.
        return AppLocalizations(locale, const EnStrings());
    }
  }

  /// The singleton delegate for Flutter's [MaterialApp.localizationsDelegates].
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// All supported [Locale] objects.
  static const List<Locale> supportedLocales = AppLocale.supportedLocales;
}

/// Internal delegate handling Flutter lifecycle and locale resolution.
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocale.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations.load(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Convenience extension on [BuildContext] to simplify syntax:
/// Instead of `AppLocalizations.of(context).album.tracksHeader`,
/// write `context.l10n.album.tracksHeader`.
extension AppLocalizationsX on BuildContext {
  /// Access to current localized strings bundle.
  AppStrings get l10n => AppLocalizations.of(this);
}
