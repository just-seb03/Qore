/// File: metro_tile_glass_back.dart
/// Description: Frosted glassmorphic back face for Windows Phone Metro live tiles.
/// Utilizes BackdropFilter with real-time blur and translucent tint so ambient background
/// particles remain visible through the tile back during and after the 3D flip.
///
/// Components / Classes / Functions:
/// - MetroTileGlassBack: Glassmorphism back surface widget.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Frosted glassmorphic back face for Metro live tiles.
class MetroTileGlassBack extends StatelessWidget {
  /// Iconic representation of the tile type (favorite, album, person, playlist).
  final IconData icon;

  /// Uppercase type label ('CANCIONES', 'ÁLBUM', 'ARTISTA', 'PLAYLIST').
  final String label;

  const MetroTileGlassBack({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.35),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 48.0,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 8.0),
                Text(
                  label,
                  style: GoogleFonts.inconsolata(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
