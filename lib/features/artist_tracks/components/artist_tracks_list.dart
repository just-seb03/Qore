/// File: artist_tracks_list.dart
/// Description: High-performance virtualized track list for the Artist Tracks feature.
/// Utilizes strict itemExtent fixed-height virtualization, oversized cacheExtent,
/// and empty state presentation with Inconsolata typography.
///
/// Components / Classes / Functions:
/// - ArtistTracksList: Virtualized list view rendering ArtistTrackTile rows.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist_tracks/components/artist_track_tile.dart';

/// Virtualized list rendering an artist's songs with fixed 64dp extent for high frame-rate scrolling.
class ArtistTracksList extends StatelessWidget {
  /// The songs list to render.
  final List<Song> songs;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  const ArtistTracksList({
    super.key,
    required this.songs,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note_outlined,
                size: 56.0,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16.0),
              Text(
                'NO TRACKS FOUND',
                style: GoogleFonts.inconsolata(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'No indexed audio tracks available for this artist.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inconsolata(
                  fontSize: 13.0,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 24.0),
      itemExtent: ArtistTrackTile.tileHeight,
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ArtistTrackTile(
          song: song,
          allArtistSongs: songs,
        );
      },
    );
  }
}
