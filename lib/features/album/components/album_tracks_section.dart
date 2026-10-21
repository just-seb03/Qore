/// File: album_tracks_section.dart
/// Description: Section component rendering the TRACKS header and the ordered
/// list of album songs using AlbumTrackTile.
///
/// Components / Classes / Functions:
/// - AlbumTracksSection: Cohesive tracklist section for album views.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/components/album_track_tile.dart';

/// Cohesive tracks section displaying the 'TRACKS' header and ordered track tiles.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'TRACKS',
            style: GoogleFonts.inconsolata(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8.0),

        // Tracklist
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          itemCount: songs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 2.0),
          itemBuilder: (context, index) {
            final song = songs[index];
            return AlbumTrackTile(
              song: song,
              trackIndex: index + 1,
              allAlbumSongs: songs,
            );
          },
        ),
      ],
    );
  }
}
