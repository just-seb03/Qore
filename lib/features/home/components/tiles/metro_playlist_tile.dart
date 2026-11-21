/// File: metro_playlist_tile.dart
/// Description: Windows Phone Metro rectangular live tile for a pinned Playlist.
/// Spans across 2 columns (2:1 aspect ratio), sharp 90-degree corners, zero shadows,
/// zero padding, rendering the user's custom-positioned and styled typography overlay
/// directly over the artwork without bottom-left scrims or subtitles, and vertical 3D
/// perspective flip revealing the Playlist icon on solid theme background.
///
/// Components / Classes / Functions:
/// - MetroPlaylistTile: Rectangular live tile presenting a pinned playlist with vertical flip.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/features/home/components/metro_live_tile.dart';
import 'package:project_anima/features/home/components/tiles/metro_tile_glass_back.dart';
import 'package:project_anima/features/playlist/components/playlist_text_banner.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';

/// Rectangular Windows Phone Metro live tile for a pinned playlist.
class MetroPlaylistTile extends StatelessWidget {
  /// The pinned playlist entity.
  final PinnedFavorite playlistItem;

  /// Staggered initial delay for the flip animation.
  final Duration initialDelay;

  /// Optional tap callback override.
  final VoidCallback? onTap;

  /// Optional long press callback (e.g. unpin).
  final VoidCallback? onLongPress;

  const MetroPlaylistTile({
    super.key,
    required this.playlistItem,
    this.initialDelay = const Duration(seconds: 48),
    this.onTap,
    this.onLongPress,
  });

  Playlist _toPlaylist() {
    return Playlist(
      id: playlistItem.playlistId,
      name: playlistItem.title,
      coverPath: playlistItem.coverPath,
      fontFamily: playlistItem.fontFamily,
      firstMediaStoreId: playlistItem.representativeSongId,
      textAlignX: playlistItem.textAlignX,
      textAlignY: playlistItem.textAlignY,
      textColor: playlistItem.textColor,
      textGradientColor: playlistItem.textGradientColor,
      fontSize: playlistItem.fontSize,
      textEffect: playlistItem.textEffect,
      createdAt: playlistItem.pinnedAt.millisecondsSinceEpoch,
      updatedAt: playlistItem.pinnedAt.millisecondsSinceEpoch,
    );
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.of(context).push(
      PlaylistDetailScreen.route(
        playlist: _toPlaylist(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.0, // 2 columns wide by 1 row high
      child: MetroLiveTile(
        flipAxis: MetroFlipAxis.vertical,
        initialDelay: initialDelay,
        interval: const Duration(seconds: 82),
        onTap: () => _handleTap(context),
        onLongPress: onLongPress,
        front: _buildFront(context),
        back: const MetroTileGlassBack(
          icon: Icons.queue_music_rounded,
          label: 'PLAYLIST',
        ),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    return PlaylistTextBanner(
      title: playlistItem.title,
      coverPath: playlistItem.coverPath,
      representativeSongId: playlistItem.representativeSongId,
    );
  }
}
