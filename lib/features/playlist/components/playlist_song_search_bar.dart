/// File: playlist_song_search_bar.dart
/// Description: Dedicated search input widget for querying songs to add to a playlist.
/// Features instant query feedback, clear action, and M3 dark theme styling.
///
/// Components / Classes / Functions:
/// - PlaylistSongSearchBar: Stateless text input widget for song searching.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Song search bar placed above the playlist track list.
class PlaylistSongSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String? hintText;

  const PlaylistSongSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.hintText,
  });

  static TextStyle get _textStyle => AppFonts.segoe(
    fontSize: 15.0,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
  );

  static TextStyle get _hintStyle => AppFonts.segoe(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(25.0),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: _textStyle,
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          hintText: hintText ?? context.l10n.playlist.searchSongsPlaceholder,
          hintStyle: _hintStyle,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.onSurfaceVariant,
            size: 20.0,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18.0,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
                splashRadius: 16.0,
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }
}
