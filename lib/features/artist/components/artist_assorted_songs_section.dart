/// File: artist_assorted_songs_section.dart
/// Description: Chronological assorted tracks section showing up to 5 songs without covers,
/// using compact styling and dummy navigation arrow.
///
/// Components / Classes / Functions:
/// - ArtistAssortedSongsSection: Chronological songs list container.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist/components/artist_compact_track_tile.dart';

import 'package:project_anima/features/artist_tracks/screens/artist_tracks_screen.dart';

/// Chronological assorted tracks section showing up to 5 songs without covers, compact styling.
class ArtistAssortedSongsSection extends StatelessWidget {
  /// Assorted songs list to display.
  final List<Song> songs;

  /// Full queue of artist songs to enqueue when a track is tapped.
  final List<Song> allArtistSongs;

  /// Optional name of the artist for navigation to the full tracks view.
  final String? artistName;

  /// Optional custom callback when viewing all tracks.
  final VoidCallback? onViewAll;

  const ArtistAssortedSongsSection({
    super.key,
    required this.songs,
    required this.allArtistSongs,
    this.artistName,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Text(
                'SONGS',
                style: GoogleFonts.inconsolata(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Navigation arrow indicating full songs view
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () {
                    if (onViewAll != null) {
                      onViewAll!();
                    } else if (artistName != null && artistName!.isNotEmpty) {
                      Navigator.of(context).push(
                        ArtistTracksScreen.route(artistName: artistName!),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13.0,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: songs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 3.0),
          itemBuilder: (context, index) {
            final song = songs[index];
            return ArtistCompactTrackTile(
              song: song,
              allArtistSongs: allArtistSongs,
            );
          },
        ),
      ],
    );
  }
}
