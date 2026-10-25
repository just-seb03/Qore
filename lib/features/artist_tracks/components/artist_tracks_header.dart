/// File: artist_tracks_header.dart
/// Description: Top header view for the Artist Tracks feature.
/// Presents section category, bold artist name in Inconsolata, track count, and total duration.
///
/// Components / Classes / Functions:
/// - ArtistTracksHeader: Header view displaying track count and aggregated runtime.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Top header view displaying the artist's name and tracklist statistics in Inconsolata.
class ArtistTracksHeader extends StatelessWidget {
  /// Name of the artist.
  final String artistName;

  /// Optional total count of songs in this list.
  final int? songCount;

  /// Optional total duration in milliseconds across all songs.
  final int? totalDurationMs;

  const ArtistTracksHeader({
    super.key,
    required this.artistName,
    this.songCount,
    this.totalDurationMs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.artistTracks.headerTitle,
            style: GoogleFonts.inconsolata(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            artistName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inconsolata(
              fontSize: 24.0,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
