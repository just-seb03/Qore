/// File: settings_theme_card.dart
/// Description: Theme and brightness mode selection card with startup aesthetics.
/// Uses staged pending state to preview theme options without mutating global app state
/// until settings are dismissed.
///
/// Components / Classes / Functions:
/// - SettingsThemeCard: Interactive card widget managing staged theme and mode selection.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/models/startup_theme_option.dart';

/// Card component presenting theme family and brightness mode selectors with staged reactivity.
class SettingsThemeCard extends StatelessWidget {
  /// The currently staged theme family identifier.
  final String selectedFamily;

  /// The currently staged brightness mode (dark vs light).
  final bool isDark;

  /// Callback when the user selects a new theme family.
  final ValueChanged<String> onFamilyChanged;

  /// Callback when the user toggles brightness mode.
  final ValueChanged<bool> onModeChanged;

  const SettingsThemeCard({
    super.key,
    required this.selectedFamily,
    required this.isDark,
    required this.onFamilyChanged,
    required this.onModeChanged,
  });

  List<StartupThemeOption> get _options => StartupThemeOption.all;

  String _localizedThemeName(BuildContext context, String id) {
    final l10n = context.l10n.startup;
    switch (id) {
      case 'monochrome':
        return l10n.themeNameMonochrome;
      case 'that_pad':
        return l10n.themeNameThatPad;
      case 'neo_tokyo':
        return l10n.themeNameNeoTokyo;
      case 'solar':
        return l10n.themeNameSolar;
      case 'corporate':
      default:
        return l10n.themeNameCorporate;
    }
  }

  void _nextTheme() {
    final index = _options.indexWhere((opt) => opt.id == selectedFamily);
    final nextIndex = (index + 1) % _options.length;
    onFamilyChanged(_options[nextIndex].id);
  }

  void _prevTheme() {
    final index = _options.indexWhere((opt) => opt.id == selectedFamily);
    final prevIndex = (index - 1 + _options.length) % _options.length;
    onFamilyChanged(_options[prevIndex].id);
  }

  void _toggleMode() {
    onModeChanged(!isDark);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.settings;
    final startupL10n = context.l10n.startup;

    final currentOption = _options.firstWhere(
      (opt) => opt.id == selectedFamily,
      orElse: () => StartupThemeOption.monochrome,
    );

    final String themeName = _localizedThemeName(context, currentOption.id);
    final String modeName = isDark ? startupL10n.darkModeLabel : startupL10n.lightModeLabel;
    final List<Color> paletteDots = currentOption.paletteFor(isDark);

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
            l10n.themeTitle,
            style: GoogleFonts.inconsolata(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: AppColors.futuristicWhite,
            ),
          ),
          const SizedBox(height: 14.0),

          // Theme Family Selector: < ThemeName >
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: AppColors.onSurfaceVariant,
                  iconSize: 22.0,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                  onPressed: _prevTheme,
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.94, end: 1.0).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          '< $themeName >',
                          key: ValueKey('settings_theme_${currentOption.id}'),
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
                  onPressed: _nextTheme,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10.0),

          // 5-Color Constituent Preview Dots for staged theme & brightness
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: paletteDots.map((color) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                width: 22.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16.0),

          // Brightness Mode Subheader
          Text(
            l10n.themeModeTitle,
            style: GoogleFonts.inconsolata(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8.0),

          // Brightness Selector: < Oscuro > / < Claro >
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: AppColors.onSurfaceVariant,
                  iconSize: 22.0,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                  onPressed: _toggleMode,
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          '< $modeName >',
                          key: ValueKey('settings_mode_$isDark'),
                          style: GoogleFonts.inconsolata(
                            fontSize: 14.0,
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
                  onPressed: _toggleMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
