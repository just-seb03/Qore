/// File: metro_tile_glass_back.dart
/// Description: Solid back face for Windows Phone Metro live tiles.
/// Pure solid surfaceContainerHigh background matching the favorites tile front color
/// for seamless typography and accent icon presentation with zero blur or transparency.
///
/// Components / Classes / Functions:
/// - MetroTileGlassBack: Solid back surface widget.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Solid back face for Metro live tiles with zero glass effect.
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
    return Container(
      color: AppColors.surfaceContainerHigh,
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
              style: AppFonts.segoe(
                fontSize: 12.0,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
