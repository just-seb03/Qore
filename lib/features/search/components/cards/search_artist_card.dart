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
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
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

  static TextStyle get _artistNameStyle => GoogleFonts.inconsolata(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle get _subtitleStyle => GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
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
          splashColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.4),
          highlightColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Material Design Avatar with drop shadow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 14.0,
                      spreadRadius: 1.0,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: MaterialArtistAvatar(
                  radius: 48.0,
                  artistName: artist.name,
                ),
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
                context.l10n.search.artistSubtitle,
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
