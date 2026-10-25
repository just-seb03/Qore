/// File: startup_header.dart
/// Description: Visual brand header component displaying the monochromatic "PROJECT ANIMA"
/// typography with custom letter-spacing and high-impact Inconsolata styling.
///
/// Components / Classes / Functions:
/// - StartupHeader: Monochromatic brand title component with clean typography.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Top branding header for the application launch and startup sequence.
class StartupHeader extends StatelessWidget {
  const StartupHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Subtle minimal insignia line
        Container(
          width: 32.0,
          height: 3.0,
          decoration: BoxDecoration(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(height: 18.0),
        // Monochromatic brand title with Inconsolata font
        Text(
          'PROJECT ANIMA',
          style: GoogleFonts.inconsolata(
            fontSize: 24.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 4.5,
            color: AppColors.futuristicWhite,
          ),
        ),
      ],
    );
  }
}
