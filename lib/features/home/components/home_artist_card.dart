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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Square Container (matching LibraryAlbumCard dimensions) with Centered Circular Avatar
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 10.0,
                      spreadRadius: 1.0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle atmospheric ambient halo
                      Container(
                        width: 105.0,
                        height: 105.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.06),
                              Colors.transparent,
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 12.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: MaterialArtistAvatar(
                          radius: 46.0,
                          artistName: artist.title,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          iconColor: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10.0),

            // 2. Artist Name (prominent and bold)
            Text(
              artist.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _nameStyle,
            ),
            const SizedBox(height: 2.0),

            // 3. Subtitle ("Artist")
            Text(
              artist.subtitle ?? 'Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _subtitleStyle,
            ),
          ],
        ),
      ),
    );
  }
}
