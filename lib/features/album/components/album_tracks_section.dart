/// File: album_tracks_section.dart
/// Description: Section component rendering the album tracklist.
/// Automatically partitions tracks by disc numbers ("DISC 1", "DISC 2", etc.)
/// when the album contains more than one disc, while preserving a unified
/// playback queue across the entire album.
///
/// Components / Classes / Functions:
/// - AlbumTracksSection: Cohesive tracklist section with multi-disc support.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/components/album_track_tile.dart';

/// Cohesive tracks section displaying the tracklist, automatically segmented
/// into English disc headers ('DISC 1', 'DISC 2') if and only if the album
/// contains multiple discs.
class AlbumTracksSection extends StatelessWidget {
  /// Ordered list of album songs.
  final List<Song> songs;

  const AlbumTracksSection({
    super.key,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine unique disc numbers across all album songs
    final Set<int> uniqueDiscs = {};
    for (final song in songs) {
      uniqueDiscs.add((song.discNumber != null && song.discNumber! > 0)
          ? song.discNumber!
          : 1);
    }

    final bool hasMultipleDiscs = uniqueDiscs.length > 1;

    // Single-disc album: Render standard flat tracklist with "TRACKS" header
    if (!hasMultipleDiscs) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              context.l10n.album.tracksHeader,
              style: GoogleFonts.inconsolata(
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int index = 0; index < songs.length; index++) ...[
                  if (index > 0) const SizedBox(height: 2.0),
                  AlbumTrackTile(
                    song: songs[index],
                    trackIndex: index + 1,
                    allAlbumSongs: songs,
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // Multi-disc album: Partition songs by disc number in ascending order
    final List<int> sortedDiscs = uniqueDiscs.toList()..sort();
    final Map<int, List<Song>> songsByDisc = {
      for (final disc in sortedDiscs) disc: <Song>[],
    };

    for (final song in songs) {
      final disc = (song.discNumber != null && song.discNumber! > 0)
          ? song.discNumber!
          : 1;
      songsByDisc[disc]!.add(song);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final disc in sortedDiscs) ...[
          Padding(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: disc == sortedDiscs.first ? 0.0 : 20.0,
              bottom: 8.0,
            ),
            child: Row(
              children: [
                Text(
                  context.l10n.album.discHeader(disc),
                  style: GoogleFonts.inconsolata(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Container(
                    height: 1.0,
                    color: AppColors.surfaceContainerHigh.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int index = 0; index < songsByDisc[disc]!.length; index++) ...[
                  if (index > 0) const SizedBox(height: 2.0),
                  AlbumTrackTile(
                    song: songsByDisc[disc]![index],
                    trackIndex: index + 1,
                    allAlbumSongs: songs,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
