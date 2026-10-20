/// File: material_artist_avatar.dart
/// Description: Native Material Design circular avatar used for Artist representation.
/// Complies with the project-wide constraint that artists do NOT display album covers,
/// but instead use a clean, futuristic circular avatar with an icon silhouette.
///
/// Components / Classes / Functions:
/// - MaterialArtistAvatar: Reusable circular avatar widget for artists.
library;

import 'package:flutter/material.dart';

/// Reusable circular Material Design avatar for artists.
class MaterialArtistAvatar extends StatelessWidget {
  /// Radius of the avatar circle.
  final double radius;

  /// Background color of the avatar. Defaults to dark grey (#282828).
  final Color backgroundColor;

  /// Foreground icon color. Defaults to light grey (#B3B3B3).
  final Color iconColor;

  /// Optional custom icon. Defaults to [Icons.person_rounded].
  final IconData icon;

  const MaterialArtistAvatar({
    super.key,
    this.radius = 24.0,
    this.backgroundColor = const Color(0xFF282828),
    this.iconColor = const Color(0xFFB3B3B3),
    this.icon = Icons.person_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Icon(
        icon,
        size: radius * 1.15,
        color: iconColor,
      ),
    );
  }
}
