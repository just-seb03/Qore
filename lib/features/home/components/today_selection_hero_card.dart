/// File: today_selection_hero_card.dart
/// Description: Hero banner card widget for 'Today's Selection' system playlist on Home.
/// Features a 1920x620 aspect ratio, a 4-cover horizontal collage of songs, cinematic gradient overlay,
/// futuristic Inconsolata title, and responsive Play/Pause toggle button.
///
/// Components / Classes / Functions:
/// - TodaySelectionHeroCard: Stateful widget rendering the collage hero banner and play controls.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/selection/today_selection_service.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';

/// Hero banner card widget rendering 'Today's Selection' on the Home screen.
class TodaySelectionHeroCard extends StatelessWidget {
  /// The 20 tracks forming today's selection.
  final List<Song> songs;

  /// Optional custom onPlay callback (defaults to starting playback).
  final VoidCallback? onPlayTap;

  const TodaySelectionHeroCard({
    super.key,
    required this.songs,
    this.onPlayTap,
  });

  static const int _kTodayPlaylistId = -1;

  static final TextStyle _titleStyle = GoogleFonts.outfit(
    fontSize: 22.0,
    fontWeight: FontWeight.w800,
    color: AppColors.futuristicWhite,
    letterSpacing: -0.4,
    shadows: const [
      Shadow(
        color: Colors.black87,
        blurRadius: 8.0,
        offset: Offset(0, 2),
      ),
    ],
  );

  void _handleOpen(BuildContext context) {
    if (songs.isEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final todayPlaylist = Playlist(
      id: _kTodayPlaylistId,
      name: "Today Selection",
      createdAt: nowMs,
      updatedAt: nowMs,
      firstMediaStoreId: songs.isNotEmpty ? songs.first.mediaStoreId : null,
    );

    Navigator.of(context).push(
      PlaylistDetailScreen.route(
        playlist: todayPlaylist,
        initialSongs: songs,
        isEditable: false,
        showHeroCover: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collageSongs = TodaySelectionService.instance.getCollageSongs(songs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 135.0),
        child: AspectRatio(
          aspectRatio: 1920 / 620,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 24.0,
                  spreadRadius: 2.0,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8.0,
                  offset: const Offset(0, 3),
                ),
              ],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleOpen(context),
                  splashColor: Colors.white.withValues(alpha: 0.08),
                  highlightColor: Colors.white.withValues(alpha: 0.04),
                  child: Stack(
                    children: [
                      // 1. Horizontal 4-Cover Collage Artwork
                      Positioned.fill(
                        child: _buildCollage(collageSongs),
                      ),

                      // 2. Cinematic Gradient Scrim (Dark on left and bottom for text legibility)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.90),
                                Colors.black.withValues(alpha: 0.65),
                                Colors.black.withValues(alpha: 0.35),
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.45, 0.75, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // 3. Information Overlay (Centered along Y axis)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              context.l10n.home.todaySelectionHeroTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _titleStyle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollage(List<Song> collageSongs) {
    if (collageSongs.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C1619),
              Color(0xFF19191D),
              Color(0xFF111114),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: collageSongs.map((song) {
        return Expanded(
          child: AnimaArtworkImage(
            mediaStoreId: song.mediaStoreId,
            albumId: song.albumId,
            albumName: song.album,
            artistName: song.albumArtist ?? song.artist,
            borderRadius: 0.0,
            isThumbnail: false,
            fit: BoxFit.cover,
          ),
        );
      }).toList(),
    );
  }
}
