/// File: search_badge.dart
/// Description: Spotify-styled pill badge displaying entity category
/// ('SONG', 'ALBUM', 'ARTIST') in Top Result cards.
///
/// Components / Classes / Functions:
/// - SearchBadge: Pill container with dark background and Inconsolata label.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Pill badge displaying category type in Top Result cards.
class SearchBadge extends StatelessWidget {
  /// Category label text (e.g. 'SONG', 'ALBUM', 'ARTIST').
  final String label;

  /// Optional background color of the badge. Defaults to [AppColors.surfaceContainerHigh].
  final Color? backgroundColor;

  /// Optional text color. Defaults to [AppColors.onSurfaceVariant].
  final Color? textColor;

  const SearchBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  static TextStyle get _badgeTextStyle => AppFonts.segoe(
    fontSize: 11.5,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.surfaceContainerHigh;
    final effectiveTextColor = textColor ?? AppColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label,
        style: _badgeTextStyle.copyWith(color: effectiveTextColor),
      ),
    );
  }
}
