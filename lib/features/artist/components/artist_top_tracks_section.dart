/// File: artist_top_tracks_section.dart
/// Description: Featured section component rendering the user's top 3 most listened songs of this artist.
///
/// Components / Classes / Functions:
/// - ArtistTopTracksSection: Section container hosting top tracks list.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist/components/artist_top_track_tile.dart';

/// Section rendering the user's top 3 most listened songs of this artist.
/// Displays cover thumbnail, title, and album without rank numbers on the margin.
class ArtistTopTracksSection extends StatelessWidget {
  /// Top songs to display (up to 3).
  final List<Song> topSongs;

  /// Full queue of artist songs to enqueue when a track is tapped.
  final List<Song> allArtistSongs;

  const ArtistTopTracksSection({
    super.key,
    required this.topSongs,
    required this.allArtistSongs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            context.l10n.artist.featuredHeader,
            style: GoogleFonts.inconsolata(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < topSongs.length; i++) ...[
                if (i > 0) const SizedBox(height: 6.0),
                ArtistTopTrackTile(
                  song: topSongs[i],
                  allArtistSongs: allArtistSongs,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
