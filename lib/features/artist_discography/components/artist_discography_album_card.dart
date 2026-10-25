/// File: artist_discography_album_card.dart
/// Description: Individual album card widget for the Artist Discography 2-per-row grid.
/// Enforces sharp 90-degree square corners without rounded borders,
/// rich elevation shadows, and Inconsolata typography for album and track count metadata.
///
/// Components / Classes / Functions:
/// - ArtistDiscographyAlbumCard: Stateless card widget presenting album artwork, title, and metadata.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';

/// Card widget rendering an individual album in the Artist Discography grid.
class ArtistDiscographyAlbumCard extends StatelessWidget {
  /// Aggregated album data.
  final AlbumDiscoveryItem album;

  /// Optional tap callback. If null, navigates to [AlbumDetailScreen].
  final VoidCallback? onTap;

  const ArtistDiscographyAlbumCard({
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

  static final TextStyle _metaStyle = GoogleFonts.inconsolata(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.1,
  );

  @override
  Widget build(BuildContext context) {
    final countLabel =
        context.l10n.artistDiscography.trackCount(album.songCount);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ??
            () {
              Navigator.of(context).push(
                AlbumDetailScreen.route(
                  albumName: album.name,
                  artistName: album.artist,
                  albumId: album.albumId,
                  representativeSongId: album.representativeSongId,
                ),
              );
            },
        splashColor: const Color(0xFF282828),
        highlightColor: const Color(0xFF1E1E1E),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Sharp square artwork with elevation shadow
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

            // 3. Track Count Metadata
            Text(
              countLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _metaStyle,
            ),
          ],
        ),
      ),
    );
  }
}
