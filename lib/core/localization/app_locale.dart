/// File: app_locale.dart
/// Description: Defines the supported locales and locale conversion utilities
/// for the Project Anima localization architecture.
///
/// Components / Classes / Functions:
/// - AppLocale: Strongly typed enum representing supported application languages.
library;

import 'package:flutter/material.dart';

/// Supported application locales for Project Anima.
enum AppLocale {
  /// English (United States / International)
  en('en', 'English'),

  /// Spanish (Español)
  es('es', 'Español');

  /// Two-letter ISO language code (e.g. 'en', 'es').
  final String languageCode;

  /// Native human-readable display title for this locale.
  final String displayName;

  const AppLocale(this.languageCode, this.displayName);

  /// Converts this [AppLocale] to a standard Flutter [Locale].
  Locale get flutterLocale => Locale(languageCode);

  /// All supported Flutter [Locale] objects.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
  ];

  /// Resolves an [AppLocale] from a Flutter [Locale] or language code string.
  /// Defaults to [AppLocale.en] if no match is found.
  static AppLocale fromLocale(Locale? locale) {
    if (locale == null) return AppLocale.en;
    return AppLocale.values.firstWhere(
      (item) => item.languageCode == locale.languageCode.toLowerCase(),
      orElse: () => AppLocale.en,
    );
  }

  /// Resolves an [AppLocale] from a raw language code string.
  static AppLocale fromLanguageCode(String? code) {
    if (code == null) return AppLocale.en;
    return AppLocale.values.firstWhere(
      (item) => item.languageCode == code.toLowerCase().trim(),
      orElse: () => AppLocale.en,
    );
  }
}
