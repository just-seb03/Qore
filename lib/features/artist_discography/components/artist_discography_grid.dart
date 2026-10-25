/// File: artist_discography_grid.dart
/// Description: Grid layout widget displaying 2 album cards per row in the Artist Discography screen.
/// Implements responsive spacing, empty state presentation, and cohesive Inconsolata typography.
///
/// Components / Classes / Functions:
/// - ArtistDiscographyGrid: Grid widget presenting 2 album cards per row.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist_discography/components/artist_discography_album_card.dart';

/// Grid displaying artist albums 2 per row with cohesive spacing and typography.
class ArtistDiscographyGrid extends StatelessWidget {
  /// The list of albums to display.
  final List<AlbumDiscoveryItem> albums;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  const ArtistDiscographyGrid({
    super.key,
    required this.albums,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.album_outlined,
                size: 56.0,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16.0),
              Text(
                'NO ALBUMS FOUND',
                style: GoogleFonts.inconsolata(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'No indexed albums available for this artist.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inconsolata(
                  fontSize: 13.0,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 22.0,
        childAspectRatio: 0.72,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return ArtistDiscographyAlbumCard(album: album);
      },
    );
  }
}
