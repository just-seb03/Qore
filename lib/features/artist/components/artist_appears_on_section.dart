/// File: artist_appears_on_section.dart
/// Description: Horizontal scrolling carousel component displaying albums where the artist
/// appears as a guest or secondary contributor ('Appears On' / 'Aparece en').
/// Enforces sharp 90-degree square cover artwork without rounded corners.
///
/// Components / Classes / Functions:
/// - ArtistAppearsOnSection: Appears On horizontal album carousel widget.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';

/// Horizontal scrolling list showing albums where the artist is featured or a guest contributor.
class ArtistAppearsOnSection extends StatelessWidget {
  /// List of distinct albums where the artist is featured.
  final List<AlbumDiscoveryItem> albums;

  const ArtistAppearsOnSection({
    super.key,
    required this.albums,
  });

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            context.l10n.artist.appearsOnHeader,
            style: GoogleFonts.inconsolata(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.onSurfaceVariant,
            ),
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
              final subtitle = (album.artist.isNotEmpty &&
                      album.artist != '<Desconocido>' &&
                      album.artist.toLowerCase() != 'unknown artist')
                  ? album.artist
                  : context.l10n.artist.albumSongCount(album.songCount);

              return InkWell(
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
                          albumName: album.name,
                          artistName: album.artist,
                          width: 134.0,
                          height: 134.0,
                          borderRadius: 0.0,
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
                        subtitle,
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
