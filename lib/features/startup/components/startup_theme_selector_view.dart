/// File: startup_theme_selector_view.dart
/// Description: Interactive theme selection view positioned slightly above the vertical center,
/// presenting theme family choices at the top (Solar, That Pad, Corporate, Neo-Tokyo, Monochrome),
/// 5 constituent color circles, and a Dark / Light mode toggle selector below.
///
/// Components / Classes / Functions:
/// - StartupThemeSelectorView: Stateful theme preview and selection component.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/models/startup_theme_option.dart';

/// Screen presenting available theme preview with constituent palette colors
/// and an interactive Dark / Light mode selector.
class StartupThemeSelectorView extends StatefulWidget {
  /// Callback triggered when the user accepts the active theme.
  final VoidCallback onAccept;

  /// Optional initial theme option. Defaults to [StartupThemeOption.solar].
  final StartupThemeOption? initialThemeOption;

  /// Optional initial brightness mode. Defaults to dark mode (`true`).
  final bool initialIsDark;

  const StartupThemeSelectorView({
    super.key,
    required this.onAccept,
    this.initialThemeOption,
    this.initialIsDark = true,
  });

  @override
  State<StartupThemeSelectorView> createState() => _StartupThemeSelectorViewState();
}

class _StartupThemeSelectorViewState extends State<StartupThemeSelectorView> {
  late StartupThemeOption _selectedOption;
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialThemeOption ?? StartupThemeOption.solar;
    _isDark = widget.initialIsDark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ThemeController.instance.setTheme(
          _selectedOption.id,
          isDark: _isDark,
        );
      }
    });
  }

  void _onSelectTheme(StartupThemeOption option) {
    setState(() {
      _selectedOption = option;
    });
    ThemeController.instance.setTheme(
      option.id,
      isDark: _isDark,
    );
  }

  void _onToggleMode(bool isDark) {
    setState(() {
      _isDark = isDark;
    });
    ThemeController.instance.setTheme(
      _selectedOption.id,
      isDark: isDark,
    );
  }

  void _onAcceptTheme() {
    ThemeController.instance.setTheme(
      _selectedOption.id,
      isDark: _isDark,
    );
    widget.onAccept();
  }

  String _localizedThemeName(BuildContext context, String id) {
    final l10n = context.l10n.startup;
    switch (id) {
      case 'solar':
        return l10n.themeNameSolar;
      case 'that_pad':
        return l10n.themeNameThatPad;
      case 'corporate':
        return l10n.themeNameCorporate;
      case 'neo_tokyo':
        return l10n.themeNameNeoTokyo;
      case 'monochrome':
      default:
        return l10n.themeNameMonochrome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.startup;
    final List<Color> activeColors = _selectedOption.paletteFor(_isDark);
    final String currentDisplayName = _localizedThemeName(context, _selectedOption.id);

    return Align(
      // Positioned slightly above the center on the Y axis
      alignment: const Alignment(0.0, -0.15),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category header
            Text(
              l10n.themeSelectorTitle,
              style: GoogleFonts.inconsolata(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20.0),

            // Top Theme Family Tabs / Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: StartupThemeOption.all.map((option) {
                  final bool isSelected = option.id == _selectedOption.id;
                  final String tabLabel = _localizedThemeName(context, option.id);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onSelectTheme(option),
                        borderRadius: BorderRadius.circular(16.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.outline.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            tabLabel,
                            style: GoogleFonts.inconsolata(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: 0.8,
                              color: isSelected ? AppColors.onAccent : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28.0),

            // Active Theme Title
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                currentDisplayName,
                key: ValueKey('${_selectedOption.id}_$_isDark'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inconsolata(
                  fontSize: 26.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.5,
                  color: AppColors.futuristicWhite,
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            // 5 Circles representing the theme constituent colors
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: Row(
                key: ValueKey('palette_${_selectedOption.id}_$_isDark'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < activeColors.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12.0),
                    _ColorPaletteCircle(
                      color: activeColors[i],
                      index: i + 1,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32.0),

            // Dark / Light Mode Selector
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(22.0),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.all(4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModeOptionButton(
                    label: l10n.darkModeLabel,
                    icon: Icons.dark_mode_rounded,
                    isSelected: _isDark,
                    onTap: () => _onToggleMode(true),
                  ),
                  const SizedBox(width: 4.0),
                  _ModeOptionButton(
                    label: l10n.lightModeLabel,
                    icon: Icons.light_mode_rounded,
                    isSelected: !_isDark,
                    onTap: () => _onToggleMode(false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40.0),

            // Accept Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onAcceptTheme,
                borderRadius: BorderRadius.circular(26.0),
                child: Ink(
                  width: 220.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(26.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.28),
                        blurRadius: 14.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      l10n.acceptThemeAction,
                      style: GoogleFonts.inconsolata(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: AppColors.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill toggle button for Dark / Light mode selection.
class _ModeOptionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOptionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(18.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16.0,
                color: isSelected ? AppColors.onAccent : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: GoogleFonts.inconsolata(
                  fontSize: 13.0,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 1.0,
                  color: isSelected ? AppColors.onAccent : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular chip displaying a single theme constituent color with a protective outline.
class _ColorPaletteCircle extends StatelessWidget {
  final Color color;
  final int index;

  const _ColorPaletteCircle({
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.0,
      height: 38.0,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          // Subtle border ensures the darkest or lightest palette colors remain distinctly visible
          color: AppColors.outline.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}
