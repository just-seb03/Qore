/// File: library_playlist_card.dart
/// Description: Individual playlist card widget for the Library playlist list view.
/// Styled as a full-bleed 2:1 widescreen hero banner with sharp unrounded 90-degree corners
/// matching Space, zero play button, and rendering the custom-positioned, custom-styled
/// Google Fonts typography created by the user.
///
/// Components / Classes / Functions:
/// - LibraryPlaylistCard: Hero banner card widget for playlists in Library.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/playlist/components/playlist_text_banner.dart';

/// Hero banner card widget rendering a playlist in the Library list view.
/// Features a strict 2:1 aspect ratio, sharp 90-degree unrounded corners matching Space,
/// no play button, and displays the user's custom-positioned, styled typography.
class LibraryPlaylistCard extends StatelessWidget {
  /// Playlist model data.
  final Playlist playlist;

  /// Callback when the playlist card is tapped.
  final VoidCallback? onTap;

  /// Callback when the playlist card is long pressed.
  final VoidCallback? onLongPress;

  /// Retained for backwards compatibility across tests.
  final VoidCallback? onPlayTap;

  /// Retained for backwards compatibility across tests (defaults to false per user request).
  final bool showPlayButton;

  const LibraryPlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
    this.onLongPress,
    this.onPlayTap,
    this.showPlayButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.0, // 2:1 Aspect Ratio matching Space
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.zero, // Zero rounding, sharp 90-degree corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.50),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            splashColor: Colors.white.withValues(alpha: 0.08),
            highlightColor: Colors.white.withValues(alpha: 0.04),
            child: PlaylistTextBanner(
              title: playlist.name,
              coverPath: playlist.coverPath,
              representativeSongId: playlist.firstMediaStoreId,
              fontFamily: playlist.fontFamily,
              textAlignX: playlist.textAlignX,
              textAlignY: playlist.textAlignY,
              textColor: playlist.textColor,
              textGradientColor: playlist.textGradientColor,
              isInteractive: false,
              fontSize: playlist.fontSize,
              textEffect: playlist.textEffect,
            ),
          ),
        ),
      ),
    );
  }
}
