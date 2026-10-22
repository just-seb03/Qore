/// File: home_artist_card.dart
/// Description: Individual artist card widget for the Home pinned favorites grid.
/// Sized identically to LibraryAlbumCard (1:1 square ratio) with prominent circular artist avatar,
/// subtle atmospheric halo, deep shadow, and high-impact Inconsolata typography.
///
/// Components / Classes / Functions:
/// - HomeArtistCard: Card widget rendering a pinned artist in the Home grid.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/search/components/common/material_artist_avatar.dart';

/// Card widget rendering a pinned artist on the Home screen.
class HomeArtistCard extends StatelessWidget {
  /// Pinned favorite metadata for this artist.
  final PinnedFavorite artist;

  /// Optional tap callback.
  final VoidCallback? onTap;

  const HomeArtistCard({
    super.key,
    required this.artist,
    this.onTap,
  });

  static final TextStyle _nameStyle = GoogleFonts.inconsolata(
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.1,
  );

  static final TextStyle _subtitleStyle = GoogleFonts.inconsolata(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
    letterSpacing: 0.3,
  );

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.of(context).push(
      ArtistDetailScreen.route(artist.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        splashColor: const Color(0xFF282828),
        highlightColor: const Color(0xFF1E1E1E),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Large Circular Avatar without square container
            AspectRatio(
              aspectRatio: 1.0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth;
                  final radius = (size / 2.0) - 6.0;

                  return Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 14.0,
                            spreadRadius: 1.0,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: MaterialArtistAvatar(
                        radius: radius > 0 ? radius : 46.0,
                        artistName: artist.title,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        iconColor: AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10.0),

            // 2. Artist Name centered in its component
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                artist.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _nameStyle,
              ),
            ),
            const SizedBox(height: 2.0),

            // 3. Subtitle centered
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                artist.subtitle ?? 'Artist',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _subtitleStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
