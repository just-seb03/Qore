/// File: search_album_card.dart
/// Description: Spotify-styled square album card used in secondary horizontal carousels,
/// displaying 130dp high-res artwork, album title, and artist name.
///
/// Components / Classes / Functions:
/// - SearchAlbumCard: Album carousel card widget.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';

/// Reusable Spotify-styled square album card for horizontal carousels.
class SearchAlbumCard extends StatelessWidget {
  /// Album entity to display.
  final AlbumDiscoveryItem album;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Card width. Defaults to 130.0.
  final double width;

  const SearchAlbumCard({
    super.key,
    required this.album,
    this.onTap,
    this.width = 130.0,
  });

  static final TextStyle _albumTitleStyle = GoogleFonts.inconsolata(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static final TextStyle _artistStyle = GoogleFonts.inconsolata(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 130x130 Square High-Res Artwork
              AnimaArtworkImage(
                mediaStoreId: album.representativeSongId,
                albumId: album.albumId,
                width: width,
                height: width,
                borderRadius: 6.0,
                fallbackIcon: Icons.album_rounded,
                isThumbnail: false,
              ),
              const SizedBox(height: 8.0),
              // Album Title
              Text(
                album.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _albumTitleStyle,
              ),
              const SizedBox(height: 2.0),
              // Artist Name
              Text(
                album.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _artistStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
