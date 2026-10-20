/// File: search_play_button.dart
/// Description: Spotify-styled floating circular play button used across Top Result cards
/// and search tiles, featuring elevation shadow and crisp play icon.
///
/// Components / Classes / Functions:
/// - SearchPlayButton: Circular white play button with shadow and dark icon.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Reusable floating circular play button.
class SearchPlayButton extends StatelessWidget {
  /// Diameter of the play button. Defaults to 48.0.
  final double size;

  /// Icon size. Defaults to 30.0.
  final double iconSize;

  /// Background color. Defaults to [AppColors.futuristicWhite].
  final Color backgroundColor;

  /// Icon color. Defaults to dark surface (#121212).
  final Color iconColor;

  /// Optional tap callback.
  final VoidCallback? onTap;

  const SearchPlayButton({
    super.key,
    this.size = 48.0,
    this.iconSize = 30.0,
    this.backgroundColor = AppColors.futuristicWhite,
    this.iconColor = const Color(0xFF121212),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.play_arrow_rounded,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );

    if (onTap == null) {
      return button;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: button,
    );
  }
}
