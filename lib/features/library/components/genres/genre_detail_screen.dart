/// File: genre_detail_screen.dart
/// Description: Full-screen Metro detail view displaying all songs belonging to a
/// selected genre, with Play / Shuffle controls, MiniPlayer integration, and
/// pull-down modal dismissal.
///
/// Components / Classes / Functions:
/// - GenreDetailScreen: Stateful screen presenting tracks for a genre.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/components/scroll_edge_fade_mask.dart';
import 'package:project_anima/core/database/models/genre_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/library/components/songs/library_song_tile.dart';
import 'package:project_anima/features/player/components/mini_player.dart';

/// Full-screen track catalog view presenting all songs matching a genre.
class GenreDetailScreen extends StatefulWidget {
  final GenreDiscoveryItem genre;
  final bool animateBounce;
  final bool showMiniPlayer;

  const GenreDetailScreen({
    super.key,
    required this.genre,
    this.animateBounce = true,
    this.showMiniPlayer = true,
  });

  /// Factory route for smooth bottom-to-top modal slide transition.
  static Route<void> route(
    GenreDiscoveryItem genre, {
    bool animateBounce = true,
    bool showMiniPlayer = true,
  }) {
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: '/genre/${genre.name}'),
      pageBuilder: (context, animation, secondaryAnimation) =>
          GenreDetailScreen(
        genre: genre,
        animateBounce: animateBounce,
        showMiniPlayer: showMiniPlayer,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  State<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends State<GenreDetailScreen> {
  Future<void> _playGenre({required bool shuffle}) async {
    final songs = widget.genre.songs;
    if (songs.isEmpty) return;

    final queue = List<Song>.from(songs);
    if (shuffle) {
      queue.shuffle();
    }

    final playback = PlaybackController.instance;
    if (playback.isShuffleEnabled) {
      await playback.toggleShuffle();
    }
    await playback.playSong(queue.first, queue: queue);
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.genre.songs;

    return Scaffold(
      backgroundColor: AppColors.bottomNavBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AmbientParticlesCanvas(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Metro header with genre title, song count, and Play/Shuffle buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 14.0, 16.0, 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.genre.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.segoe(
                                fontSize: 28.0,
                                fontWeight: FontWeight.w300,
                                color: AppColors.onBackground,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              context.l10n.library.songCount(songs.length),
                              style: AppFonts.segoe(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w300,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      IconButton(
                        key: const ValueKey('genre_shuffle_button'),
                        onPressed: songs.isEmpty
                            ? null
                            : () => _playGenre(shuffle: true),
                        icon: const Icon(Icons.shuffle_rounded, size: 22.0),
                        color: AppColors.onBackground,
                        tooltip: context.l10n.player.shuffleTooltip,
                      ),
                      const SizedBox(width: 4.0),
                      Material(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.zero,
                        child: InkWell(
                          key: const ValueKey('genre_play_button'),
                          onTap: songs.isEmpty
                              ? null
                              : () => _playGenre(shuffle: false),
                          child: SizedBox(
                            width: 42.0,
                            height: 42.0,
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.onAccent,
                              size: 26.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Track list
                Expanded(
                  child: ScrollEdgeFadeMask(
                    topFadeExtent: 20.0,
                    bottomFadeExtent: 64.0,
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: 120.0 + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemExtent: LibrarySongTile.tileHeight,
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return LibrarySongTile(
                          song: song,
                          onTap: () => PlaybackController.instance
                              .playSong(song, queue: songs),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating MiniPlayer + dismiss indicator
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showMiniPlayer) const MiniPlayer(),
                Padding(
                  padding: EdgeInsets.only(
                    top: 4.0,
                    bottom: 8.0 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: ModalDismissIndicator(
                    onDismiss: () => Navigator.of(context).maybePop(),
                    animate: widget.animateBounce,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
