/// File: settings_language_card.dart
/// Description: Language selection card with startup aesthetics.
/// Uses staged pending state to preview language choice without mutating global app state
/// until settings are dismissed.
///
/// Components / Classes / Functions:
/// - SettingsLanguageCard: Interactive card widget managing staged language selection.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Card component presenting language selector with staged reactivity.
class SettingsLanguageCard extends StatelessWidget {
  /// The currently staged application locale.
  final AppLocale selectedLocale;

  /// Callback when the user toggles locale.
  final ValueChanged<AppLocale> onLocaleChanged;

  const SettingsLanguageCard({
    super.key,
    required this.selectedLocale,
    required this.onLocaleChanged,
  });

  void _toggleLanguage() {
    final next = selectedLocale == AppLocale.es ? AppLocale.en : AppLocale.es;
    onLocaleChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.settings;
    final displayName = selectedLocale.displayName;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title
          Text(
            l10n.languageTitle,
            style: GoogleFonts.inconsolata(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: AppColors.futuristicWhite,
            ),
          ),
          const SizedBox(height: 14.0),

          // Language Selector: < Español > / < English >
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: InkWell(
              onTap: _toggleLanguage,
              borderRadius: BorderRadius.circular(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: AppColors.onSurfaceVariant,
                    iconSize: 22.0,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                    onPressed: _toggleLanguage,
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            '< $displayName >',
                            key: ValueKey('settings_language_${selectedLocale.languageCode}'),
                            style: GoogleFonts.inconsolata(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: AppColors.futuristicWhite,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: AppColors.onSurfaceVariant,
                    iconSize: 22.0,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                    onPressed: _toggleLanguage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
