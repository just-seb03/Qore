/// File: home_header.dart
/// Description: Header component for the Home screen displaying a prominent,
/// futuristic title in the 'Inconsolata' typeface, aligned to the left margin
/// with stacked words and clean styling without glow effects.
/// Implements static caching of typography to avoid frame-by-frame font re-parsing.
///
/// Components / Classes / Functions:
/// - HomeHeader: Stateless widget rendering the futuristic multi-line section header.
///   - _titleTextStyle: Pre-cached TextStyle for GoogleFonts.inconsolata.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Header widget for the Home screen with high-impact typography.
///
/// Renders stacked words aligned to the left margin using Google Fonts'
/// 'Inconsolata' in a refined futuristic off-white hue.
class HomeHeader extends StatelessWidget {
  /// The header text to display. Defaults to 'WELCOME'.
  final String title;

  /// Custom padding around the header.
  final EdgeInsetsGeometry padding;

  /// Whether the home grid is in edit / arranging mode.
  final bool isArranging;

  /// Callback when the checkmark ticket button is tapped to exit arranging mode.
  final VoidCallback? onDoneTap;

  // Cached TextStyle to eliminate runtime font parsing on build
  static final TextStyle _titleTextStyle = GoogleFonts.inconsolata(
    fontSize: 34.0,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: 1.2,
    color: AppColors.futuristicWhite,
  );

  const HomeHeader({
    super.key,
    this.title = 'WELCOME',
    this.padding = const EdgeInsets.only(
      left: 24.0,
      top: 32.0,
      right: 24.0,
      bottom: 12.0,
    ),
    this.isArranging = false,
    this.onDoneTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: _titleTextStyle,
            ),
          ),
          if (isArranging && onDoneTap != null) ...[
            const SizedBox(height: 6.0),
            IconButton(
              key: const ValueKey('home_slot_grid_done_button'),
              icon: const Icon(
                Icons.check_rounded,
                color: AppColors.futuristicWhite,
                size: 28.0,
              ),
              tooltip: 'Listo',
              splashRadius: 22.0,
              onPressed: onDoneTap,
            ),
          ],
        ],
      ),
    );
  }
}
