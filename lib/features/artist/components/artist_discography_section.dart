/// File: artist_discography_section.dart
/// Description: Horizontal scrolling discography carousel component displaying an artist's albums,
/// cover artwork, song count, and navigation to the full album detail screen.
///
/// Components / Classes / Functions:
/// - ArtistDiscographySection: Discography carousel widget.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';

/// Discography horizontal scrolling list showing albums with dummy navigation arrow.
class ArtistDiscographySection extends StatelessWidget {
  /// List of distinct albums released by the artist.
  final List<AlbumDiscoveryItem> albums;

  const ArtistDiscographySection({
    super.key,
    required this.albums,
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
                'DISCOGRAPHY',
                style: GoogleFonts.inconsolata(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Dummy navigation arrow indicating full albums view
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () {},
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
        const SizedBox(height: 12.0),
        SizedBox(
          height: 192.0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: albums.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14.0),
            itemBuilder: (context, index) {
              final album = albums[index];
              final countStr =
                  '${album.songCount} ${album.songCount == 1 ? "song" : "songs"}';

              return InkWell(
                borderRadius: BorderRadius.circular(16.0),
                onTap: () {
                  Navigator.of(context).push(
                    AlbumDetailScreen.route(
                      albumName: album.name,
                      artistName: album.artist,
                      albumId: album.albumId,
                      representativeSongId: album.representativeSongId,
                    ),
                  );
                },
                child: SizedBox(
                  width: 134.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 10.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AnimaArtworkImage(
                          mediaStoreId: album.representativeSongId,
                          albumId: album.albumId,
                          width: 134.0,
                          height: 134.0,
                          borderRadius: 16.0,
                          fallbackIcon: Icons.album_rounded,
                          isThumbnail: false,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        album.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        countStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inconsolata(
                          fontSize: 12.0,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
