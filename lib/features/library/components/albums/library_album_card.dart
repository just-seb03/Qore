/// File: library_album_card.dart
/// Description: Individual album card widget for the Library albums grid.
/// Enforces sharp 90-degree square corners without rounded borders,
/// rich elevation shadows, and Inconsolata typography for album and artist names.
///
/// Components / Classes / Functions:
/// - LibraryAlbumCard: Stateless card widget presenting album artwork, title, and artist.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';

/// Card widget rendering an album in the Library grid (2 per row).
class LibraryAlbumCard extends StatelessWidget {
  /// Aggregated album data.
  final AlbumDiscoveryItem album;

  /// Callback when the album card is tapped.
  final VoidCallback? onTap;

  const LibraryAlbumCard({
    super.key,
    required this.album,
    this.onTap,
  });

  static final TextStyle _titleStyle = GoogleFonts.inconsolata(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.1,
  );

  static final TextStyle _artistStyle = GoogleFonts.inconsolata(
    fontSize: 12.5,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Square Artwork with Shadow (no rounded corners)
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 10.0,
                      spreadRadius: 1.0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: AnimaArtworkImage(
                  mediaStoreId: album.representativeSongId,
                  albumName: album.name,
                  artistName: album.artist,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 0.0,
                  fallbackIcon: Icons.album_rounded,
                  isThumbnail: false,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10.0),

            // 2. Album Title
            Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle,
            ),
            const SizedBox(height: 2.0),

            // 3. Album Artist
            Text(
              album.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _artistStyle,
            ),
          ],
        ),
      ),
    );
  }
}
