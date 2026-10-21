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
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';

/// Centered track title, artist, and album presentation widget.
class PlayerMetadataView extends StatelessWidget {
  final Song? song;
  final VoidCallback? onArtistTap;
  final VoidCallback? onAlbumTap;

  const PlayerMetadataView({
    super.key,
    required this.song,
    this.onArtistTap,
    this.onAlbumTap,
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
    final hasArtist = song?.artist != null &&
        song!.artist!.trim().isNotEmpty &&
        song!.artist != '<Desconocido>' &&
        song!.artist != 'Unknown Artist';
    final artist = hasArtist ? song!.artist! : 'Artista desconocido';
    final hasAlbum = song?.album != null &&
        song!.album!.trim().isNotEmpty &&
        song!.album != '<Desconocido>' &&
        song!.album != 'Unknown Album';
    final album = hasAlbum ? song!.album! : 'Unknown Album';

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
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: hasArtist
                  ? () {
                      if (onArtistTap != null) {
                        onArtistTap!();
                      } else {
                        Navigator.of(context).push(ArtistDetailScreen.route(artist));
                      }
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                child: Text(
                  artist,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _artistStyle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4.0),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: hasAlbum
                  ? () {
                      if (onAlbumTap != null) {
                        onAlbumTap!();
                      } else {
                        Navigator.of(context).push(
                          AlbumDetailScreen.route(
                            albumName: album,
                            artistName: hasArtist ? artist : null,
                            albumId: song?.albumId,
                            representativeSongId: song?.mediaStoreId,
                          ),
                        );
                      }
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                child: Text(
                  album,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _albumStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
