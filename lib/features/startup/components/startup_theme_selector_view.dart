/// File: startup_theme_selector_view.dart
/// Description: Theme selection view positioned slightly above the vertical center,
/// displaying the theme name ("Monochrome"), a row of 5 constituent color circles,
/// and an accept action button triggering the initialization sequence.
///
/// Components / Classes / Functions:
/// - StartupThemeSelectorView: Visual theme picker preview component.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/models/startup_theme_option.dart';

/// Screen presenting available theme preview with constituent palette colors
/// and an accept button to proceed with startup indexing.
class StartupThemeSelectorView extends StatelessWidget {
  /// Callback triggered when the user accepts the active theme.
  final VoidCallback onAccept;

  /// Active theme preview option. Defaults to [StartupThemeOption.monochrome].
  final StartupThemeOption themeOption;

  const StartupThemeSelectorView({
    super.key,
    required this.onAccept,
    this.themeOption = StartupThemeOption.monochrome,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.startup;

    return Align(
      // Positioned slightly above the center on the Y axis
      alignment: const Alignment(0.0, -0.20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category subtitle
            Text(
              l10n.themeSelectorTitle,
              style: GoogleFonts.inconsolata(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12.0),
            // Theme Name (e.g. Monochrome)
            Text(
              l10n.themeNameMonochrome,
              textAlign: TextAlign.center,
              style: GoogleFonts.inconsolata(
                fontSize: 28.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 4.0,
                color: AppColors.futuristicWhite,
              ),
            ),
            const SizedBox(height: 32.0),
            // 5 Circles representing the theme constituent colors
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < themeOption.colors.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14.0),
                  _ColorPaletteCircle(
                    color: themeOption.colors[i],
                    index: i + 1,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 48.0),
            // Accept Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAccept,
                borderRadius: BorderRadius.circular(26.0),
                child: Ink(
                  width: 200.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: AppColors.futuristicWhite,
                    borderRadius: BorderRadius.circular(26.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.futuristicWhite.withValues(alpha: 0.15),
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
                        color: AppColors.background,
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
          // Subtle border ensures the darkest palette color (#0E0E10) is distinctly visible
          color: AppColors.outline.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}
