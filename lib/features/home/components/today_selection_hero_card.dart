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
import 'package:project_anima/core/playback/playback_controller.dart';
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

  static final TextStyle _tagStyle = GoogleFonts.inconsolata(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: const Color(0xFFE50914),
    letterSpacing: 1.6,
  );

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

  static final TextStyle _subtitleStyle = GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: const Color(0xFFD4D4D4),
    letterSpacing: 0.4,
    shadows: const [
      Shadow(
        color: Colors.black87,
        blurRadius: 4.0,
        offset: Offset(0, 1),
      ),
    ],
  );

  void _handleOpen(BuildContext context) {
    if (songs.isEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final todayPlaylist = Playlist(
      id: _kTodayPlaylistId,
      name: "Today's Selection",
      createdAt: nowMs,
      updatedAt: nowMs,
      firstMediaStoreId: songs.isNotEmpty ? songs.first.mediaStoreId : null,
    );

    Navigator.of(context).push(
      PlaylistDetailScreen.route(
        playlist: todayPlaylist,
        initialSongs: songs,
      ),
    );
  }

  void _handlePlay() async {
    if (onPlayTap != null) {
      onPlayTap!();
      return;
    }

    if (songs.isEmpty) return;

    final controller = PlaybackController.instance;
    final isCurrent = controller.activePlaylistId == _kTodayPlaylistId;

    if (isCurrent) {
      await controller.togglePlayPause();
    } else {
      await controller.playSong(
        songs.first,
        queue: songs,
        playlistId: _kTodayPlaylistId,
      );
    }
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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: ClipRect(
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

                      // 3. Information and Controls Overlay
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left: Category Tag, Title, and Subtitle
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DAILY MIX',
                                    style: _tagStyle,
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    "Today's Selection",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _titleStyle,
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    '${songs.length} tracks • Curated for today',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _subtitleStyle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12.0),

                            // Right: Prominent Direct Play / Pause Trigger
                            _buildPlayTrigger(),
                          ],
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

  Widget _buildPlayTrigger() {
    return ListenableBuilder(
      listenable: PlaybackController.instance,
      builder: (context, _) {
        final isCurrent = PlaybackController.instance.activePlaylistId == _kTodayPlaylistId;
        final isPlaying = isCurrent && PlaybackController.instance.isPlaying;

        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _handlePlay,
            splashColor: Colors.white.withValues(alpha: 0.25),
            highlightColor: Colors.white.withValues(alpha: 0.15),
            child: Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: isPlaying
                    ? const Color(0xFFE50914)
                    : Colors.black.withValues(alpha: 0.70),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPlaying
                      ? const Color(0xFFFF5252)
                      : Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isPlaying
                        ? const Color(0xFFE50914).withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.65),
                    blurRadius: 10.0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 26.0,
                  color: AppColors.futuristicWhite,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
