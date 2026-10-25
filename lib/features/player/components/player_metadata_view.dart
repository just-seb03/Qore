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
import 'package:project_anima/core/localization/app_localizations.dart';
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

  static TextStyle get _titleStyle => GoogleFonts.inconsolata(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    color: AppColors.futuristicWhite,
    letterSpacing: -0.2,
  );

  static TextStyle get _artistStyle => GoogleFonts.inconsolata(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.1,
  );

  static TextStyle get _albumStyle => GoogleFonts.inconsolata(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceDisabled,
  );

  @override
  Widget build(BuildContext context) {
    final title = song?.title ?? context.l10n.player.noPlayback;
    final hasArtist = song?.artist != null &&
        song!.artist!.trim().isNotEmpty &&
        song!.artist != '<Desconocido>' &&
        song!.artist != 'Unknown Artist';
    final artist =
        hasArtist ? song!.artist! : context.l10n.common.unknownArtist;
    final hasAlbum = song?.album != null &&
        song!.album!.trim().isNotEmpty &&
        song!.album != '<Desconocido>' &&
        song!.album != 'Unknown Album';
    final album = hasAlbum ? song!.album! : context.l10n.common.unknownAlbum;

    final hasAlbumArtist = song?.albumArtist != null &&
        song!.albumArtist!.trim().isNotEmpty &&
        song!.albumArtist != '<Desconocido>' &&
        song!.albumArtist != 'Unknown Artist';
    final albumArtist = hasAlbumArtist
        ? song!.albumArtist!.trim()
        : (hasArtist ? song!.artist!.trim() : null);

    String separator = ', ';
    if (song?.artist != null) {
      if (song!.artist!.contains(' / ') || (song!.artist!.contains('/') && !song!.artist!.contains(','))) {
        separator = ' / ';
      } else if (song!.artist!.contains(';')) {
        separator = '; ';
      }
    }
    final individualArtists = song?.artists ?? const [];

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
          _buildArtistSection(
            context,
            hasArtist: hasArtist,
            fallbackArtist: artist,
            individualArtists: individualArtists,
            separator: separator,
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
                            artistName: albumArtist,
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

  Widget _buildArtistSection(
    BuildContext context, {
    required bool hasArtist,
    required String fallbackArtist,
    required List<String> individualArtists,
    required String separator,
  }) {
    if (!hasArtist || individualArtists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: Text(
          fallbackArtist,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _artistStyle,
        ),
      );
    }

    if (individualArtists.length == 1) {
      final singleArtist = individualArtists.first;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: () {
            if (onArtistTap != null) {
              onArtistTap!();
            } else {
              Navigator.of(context).push(ArtistDetailScreen.route(singleArtist));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            child: Text(
              singleArtist,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _artistStyle,
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < individualArtists.length; i++) ...[
          if (i > 0)
            Text(
              separator,
              style: _artistStyle.copyWith(
                color: AppColors.onSurfaceDisabled,
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6.0),
              onTap: () {
                Navigator.of(context).push(
                  ArtistDetailScreen.route(individualArtists[i]),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: Text(
                  individualArtists[i],
                  style: _artistStyle,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
