/// File: search_section_header.dart
/// Description: Spotify-styled section header with Inconsolata typography used
/// to delineate search categories (TOP RESULT, SONGS, ALBUMS, ARTISTS).
///
/// Components / Classes / Functions:
/// - SearchSectionHeader: Reusable section header text with optional trailing action.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Section header displaying title in Inconsolata styling with optional trailing widget.
class SearchSectionHeader extends StatelessWidget {
  /// Section title text.
  final String title;

  /// Optional trailing widget (e.g. action button).
  final Widget? trailing;

  /// Horizontal padding. Defaults to 16.0.
  final double horizontalPadding;

  /// Vertical padding. Defaults to 8.0.
  final double verticalPadding;

  const SearchSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.horizontalPadding = 16.0,
    this.verticalPadding = 8.0,
  });

  static TextStyle get _headerStyle => AppFonts.segoe(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: _headerStyle,
          ),
          ?trailing,
        ],
      ),
    );
  }
}
