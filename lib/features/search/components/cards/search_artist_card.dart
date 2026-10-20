/// File: search_artist_card.dart
/// Description: Spotify-styled circular artist card used in secondary horizontal carousels,
/// displaying a native Material Design circular avatar, artist name, and 'Artista' subtitle.
///
/// Components / Classes / Functions:
/// - SearchArtistCard: Artist carousel card widget.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/features/search/components/common/material_artist_avatar.dart';

/// Reusable Spotify-styled circular artist card for horizontal carousels.
class SearchArtistCard extends StatelessWidget {
  /// Artist entity to display.
  final ArtistDiscoveryItem artist;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Card width. Defaults to 120.0.
  final double width;

  const SearchArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.width = 120.0,
  });

  static final TextStyle _artistNameStyle = GoogleFonts.inconsolata(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static final TextStyle _subtitleStyle = GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.0),
          splashColor: const Color(0xFF282828),
          highlightColor: const Color(0xFF1E1E1E),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Material Design Avatar
              const MaterialArtistAvatar(
                radius: 48.0,
              ),
              const SizedBox(height: 8.0),
              // Artist Name
              Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _artistNameStyle,
              ),
              const SizedBox(height: 2.0),
              // Subtitle Badge
              Text(
                'Artista',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _subtitleStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
