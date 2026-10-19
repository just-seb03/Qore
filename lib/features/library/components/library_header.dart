/// File: library_header.dart
/// Description: Top header component for the Library screen displaying a centered
/// title in the 'Zen Dots' typeface without background or separator lines.
///
/// Components / Classes / Functions:
/// - LibraryHeader: Stateless widget rendering the centered Zen Dots section title.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Top header for the Library screen with centered Zen Dots typography.
class LibraryHeader extends StatelessWidget {
  /// The header text to display. Defaults to 'Library'.
  final String title;

  /// Custom padding around the header text.
  final EdgeInsetsGeometry padding;

  const LibraryHeader({
    super.key,
    this.title = 'Library',
    this.padding = const EdgeInsets.only(
      top: 24.0,
      bottom: 20.0,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.zenDots(
            fontSize: 22.0,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
            color: AppColors.futuristicWhite,
          ),
        ),
      ),
    );
  }
}
