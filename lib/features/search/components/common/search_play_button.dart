/// File: search_play_button.dart
/// Description: Spotify-styled floating circular play button used across Top Result cards
/// and search tiles, featuring elevation shadow and crisp play icon.
///
/// Components / Classes / Functions:
/// - SearchPlayButton: Circular white play button with shadow and dark icon.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Reusable floating circular play button.
class SearchPlayButton extends StatelessWidget {
  /// Diameter of the play button. Defaults to 48.0.
  final double size;

  /// Icon size. Defaults to 30.0.
  final double iconSize;

  /// Background color. Defaults to [AppColors.accent].
  final Color? backgroundColor;

  /// Icon color. Defaults to [AppColors.onAccent].
  final Color? iconColor;

  /// Optional tap callback.
  final VoidCallback? onTap;

  const SearchPlayButton({
    super.key,
    this.size = 48.0,
    this.iconSize = 30.0,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.accent;
    final effectiveIcon = iconColor ?? AppColors.onAccent;

    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.zero,
      ),
      child: Center(
        child: Icon(
          Icons.play_arrow_rounded,
          color: effectiveIcon,
          size: iconSize,
        ),
      ),
    );

    if (onTap == null) {
      return button;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: button,
    );
  }
}
