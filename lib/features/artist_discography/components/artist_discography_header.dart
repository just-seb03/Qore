/// File: artist_discography_header.dart
/// Description: Material Design 3 Expressive header view for the Artist Discography screen.
/// Presents the section category label, bold artist name in Inconsolata, and total albums count.
///
/// Components / Classes / Functions:
/// - ArtistDiscographyHeader: Header view widget for the full discography view.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Top header view displaying the artist's name and discography count in Inconsolata.
class ArtistDiscographyHeader extends StatelessWidget {
  /// Name of the artist.
  final String artistName;

  /// Optional total count of albums in this discography.
  final int? albumCount;

  const ArtistDiscographyHeader({
    super.key,
    required this.artistName,
    this.albumCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.artistDiscography.headerTitle,
            style: GoogleFonts.inconsolata(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            artistName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inconsolata(
              fontSize: 24.0,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
