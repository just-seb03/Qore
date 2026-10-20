/// File: player_metadata_view.dart
/// Description: Song metadata display component presenting title, artist,
/// and album in a centered typography stack using Inconsolata and AppColors.
///
/// Components / Classes / Functions:
/// - PlayerMetadataView: Centered text hierarchy widget.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Centered track title, artist, and album presentation widget.
class PlayerMetadataView extends StatelessWidget {
  final Song? song;

  const PlayerMetadataView({
    super.key,
    required this.song,
  });

  static final TextStyle _titleStyle = GoogleFonts.inconsolata(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    color: AppColors.futuristicWhite,
    letterSpacing: -0.2,
  );

  static final TextStyle _artistStyle = GoogleFonts.inconsolata(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.1,
  );

  static final TextStyle _albumStyle = GoogleFonts.inconsolata(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceDisabled,
  );

  @override
  Widget build(BuildContext context) {
    final title = song?.title ?? 'Sin reproducción';
    final artist = (song?.artist != null && song!.artist!.trim().isNotEmpty && song!.artist != '<Desconocido>')
        ? song!.artist!
        : 'Artista desconocido';
    final album = (song?.album != null && song!.album!.trim().isNotEmpty && song!.album != '<Desconocido>')
        ? song!.album!
        : 'Álbum desconocido';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _titleStyle,
          ),
          const SizedBox(height: 6.0),
          Text(
            artist,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _artistStyle,
          ),
          const SizedBox(height: 4.0),
          Text(
            album,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _albumStyle,
          ),
        ],
      ),
    );
  }
}
