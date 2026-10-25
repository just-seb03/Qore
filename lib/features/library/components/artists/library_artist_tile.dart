/// File: library_artist_tile.dart
/// Description: Individual artist row widget for the Library artists list.
/// Renders the circular MaterialArtistAvatar and artist name in Inconsolata typography.
///
/// Components / Classes / Functions:
/// - LibraryArtistTile: Stateless list tile rendering artist avatar and name.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/features/search/components/common/material_artist_avatar.dart';

/// Row tile presenting an artist in the Library artists list.
class LibraryArtistTile extends StatelessWidget {
  /// Aggregated artist data.
  final ArtistDiscoveryItem artist;

  /// Callback when this artist is tapped.
  final VoidCallback? onTap;

  const LibraryArtistTile({
    super.key,
    required this.artist,
    this.onTap,
  });

  static final TextStyle _nameStyle = GoogleFonts.inconsolata(
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.1,
  );

  static final TextStyle _subtitleStyle = GoogleFonts.inconsolata(
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
    letterSpacing: 0.1,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF282828),
        highlightColor: const Color(0xFF1E1E1E),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // 1. Circular Avatar (Photo or Material silhouette)
              MaterialArtistAvatar(
                radius: 26.0,
                artistName: artist.name,
              ),
              const SizedBox(width: 16.0),

              // 2. Artist Name and Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _nameStyle,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      context.l10n.library.artistSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _subtitleStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
