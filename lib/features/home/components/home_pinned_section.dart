/// File: home_pinned_section.dart
/// Description: Responsive gapless grid section rendering pinned favorites (albums, artists, playlists).
/// Implements intelligent row-pairing to ensure zero awkward gaps (Anti-Jank & High Cohesion).
///
/// Components / Classes / Functions:
/// - HomePinnedSection: Stateless widget presenting pinned favorites with gapless packing.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/home/components/home_artist_card.dart';
import 'package:project_anima/features/library/components/albums/library_album_card.dart';
import 'package:project_anima/features/library/components/playlists/library_playlist_card.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';

/// Sealed row descriptor for gapless home layout.
sealed class HomeRowItem {
  const HomeRowItem();
}

class FullRowItem extends HomeRowItem {
  final PinnedFavorite playlist;
  const FullRowItem(this.playlist);
}

class PairRowItem extends HomeRowItem {
  final PinnedFavorite first;
  final PinnedFavorite? second;
  const PairRowItem(this.first, [this.second]);
}

/// Section widget rendering user-pinned favorites with gapless row packing.
class HomePinnedSection extends StatelessWidget {
  /// List of pinned items from SQLite.
  final List<PinnedFavorite> items;

  const HomePinnedSection({
    super.key,
    required this.items,
  });

  static final TextStyle _sectionHeaderStyle = GoogleFonts.inconsolata(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  /// Partitions items into gapless rows (2-span playlists on full rows, 1-span items paired).
  static List<HomeRowItem> buildGaplessRows(List<PinnedFavorite> items) {
    final List<HomeRowItem> rows = [];
    final List<PinnedFavorite> halfItems = [];
    final List<PinnedFavorite> fullItems = [];

    for (final item in items) {
      if (item.isPlaylist) {
        fullItems.add(item);
      } else {
        halfItems.add(item);
      }
    }

    int halfIdx = 0;
    int fullIdx = 0;

    while (halfIdx < halfItems.length || fullIdx < fullItems.length) {
      if (halfIdx + 1 < halfItems.length) {
        rows.add(PairRowItem(halfItems[halfIdx], halfItems[halfIdx + 1]));
        halfIdx += 2;
      } else if (halfIdx < halfItems.length && fullIdx >= fullItems.length) {
        rows.add(PairRowItem(halfItems[halfIdx]));
        halfIdx += 1;
      }

      if (fullIdx < fullItems.length) {
        rows.add(FullRowItem(fullItems[fullIdx]));
        fullIdx += 1;
      }

      if (halfIdx < halfItems.length && fullIdx >= fullItems.length) {
        rows.add(PairRowItem(halfItems[halfIdx]));
        halfIdx += 1;
      }
    }

    return rows;
  }

  void _openAlbum(BuildContext context, PinnedFavorite item) {
    Navigator.of(context).push(
      AlbumDetailScreen.route(
        albumName: item.title,
        artistName: item.subtitle,
        albumId: item.albumId,
        representativeSongId: item.representativeSongId,
      ),
    );
  }

  void _openPlaylist(BuildContext context, PinnedFavorite item) {
    final playlist = Playlist(
      id: item.playlistId,
      name: item.title,
      coverPath: item.coverPath,
      fontFamily: item.fontFamily,
      firstMediaStoreId: item.representativeSongId,
      createdAt: item.pinnedAt.millisecondsSinceEpoch,
      updatedAt: item.pinnedAt.millisecondsSinceEpoch,
    );

    Navigator.of(context).push(
      PlaylistDetailScreen.route(playlist: playlist),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 16.0),
          child: Row(
            children: [
              Text(
                'PINNED FAVORITES',
                style: _sectionHeaderStyle,
              ),
              const SizedBox(width: 8.0),
              Icon(
                Icons.push_pin_rounded,
                size: 14.0,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),

        // Body: Empty State or Gapless Rows
        if (items.isEmpty)
          _buildEmptyState()
        else
          _buildRows(context),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                size: 22.0,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DOUBLE-TAP TO PIN',
                    style: GoogleFonts.inconsolata(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.futuristicWhite,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    'Double-tap any album, artist, or playlist to pin them here for instant access.',
                    style: GoogleFonts.inconsolata(
                      fontSize: 12.0,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRows(BuildContext context) {
    final rows = buildGaplessRows(items);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: rows.length,
      separatorBuilder: (ctx, _) => const SizedBox(height: 18.0),
      itemBuilder: (context, index) {
        final row = rows[index];
        switch (row) {
          case FullRowItem(:final playlist):
            return _buildFullPlaylistCard(context, playlist);

          case PairRowItem(:final first, :final second):
            return _buildPairRow(context, first, second);
        }
      },
    );
  }

  Widget _buildFullPlaylistCard(BuildContext context, PinnedFavorite item) {
    final playlist = Playlist(
      id: item.playlistId,
      name: item.title,
      coverPath: item.coverPath,
      fontFamily: item.fontFamily,
      firstMediaStoreId: item.representativeSongId,
      createdAt: item.pinnedAt.millisecondsSinceEpoch,
      updatedAt: item.pinnedAt.millisecondsSinceEpoch,
    );

    return LibraryPlaylistCard(
      playlist: playlist,
      onTap: () => _openPlaylist(context, item),
      onPlayTap: () async {
        if (playlist.id == null) return;
        final controller = PlaybackController.instance;
        final isCurrent = controller.activePlaylistId == playlist.id;

        if (isCurrent) {
          await controller.togglePlayPause();
        } else {
          final songs = await PlaylistDao().getPlaylistSongs(playlist.id!);
          if (songs.isNotEmpty) {
            await controller.playSong(
              songs.first,
              queue: songs,
              playlistId: playlist.id,
            );
          }
        }
      },
    );
  }

  Widget _buildPairRow(
    BuildContext context,
    PinnedFavorite first,
    PinnedFavorite? second,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSingleCard(context, first),
        ),
        const SizedBox(width: 14.0),
        Expanded(
          child: second != null
              ? _buildSingleCard(context, second)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSingleCard(BuildContext context, PinnedFavorite item) {
    if (item.isAlbum) {
      final albumDiscovery = AlbumDiscoveryItem(
        name: item.title,
        artist: item.subtitle ?? '',
        albumId: item.albumId,
        representativeSongId: item.representativeSongId ?? 0,
        songCount: 0,
        totalDuration: 0,
      );
      return LibraryAlbumCard(
        album: albumDiscovery,
        onTap: () => _openAlbum(context, item),
      );
    }

    if (item.isArtist) {
      return HomeArtistCard(
        artist: item,
      );
    }

    // Defensive fallback
    return const SizedBox.shrink();
  }
}
