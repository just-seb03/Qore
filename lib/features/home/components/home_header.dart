/// File: home_header.dart
/// Description: Header component for the Home screen displaying a prominent,
/// futuristic title in the 'Zen Dots' typeface, aligned to the left margin
/// with stacked words and clean styling without glow effects.
/// Implements static caching of typography to avoid frame-by-frame font re-parsing.
///
/// Components / Classes / Functions:
/// - HomeHeader: Stateless widget rendering the futuristic multi-line section header.
///   - _titleTextStyle: Pre-cached TextStyle for GoogleFonts.zenDots.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Header widget for the Home screen with high-impact typography.
///
/// Renders stacked words aligned to the left margin using Google Fonts'
/// 'Zen Dots' in a refined futuristic off-white hue.
class HomeHeader extends StatelessWidget {
  /// The header text to display. Defaults to stacked 'YOUR\nSELECTION'.
  final String title;

  /// Custom padding around the header.
  final EdgeInsetsGeometry padding;

  // Cached TextStyle to eliminate runtime font parsing on build
  static final TextStyle _titleTextStyle = GoogleFonts.zenDots(
    fontSize: 34.0,
    fontWeight: FontWeight.w400,
    height: 1.15,
    letterSpacing: 1.0,
    color: AppColors.futuristicWhite,
  );

  const HomeHeader({
    super.key,
    this.title = 'YOUR\nSELECTION',
    this.padding = const EdgeInsets.only(
      left: 24.0,
      top: 32.0,
      right: 24.0,
      bottom: 16.0,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          textAlign: TextAlign.left,
          style: _titleTextStyle,
        ),
      ),
    );
  }
}
