/// File: album_detail_screen.dart
/// Description: Modular Album detail modal screen presenting a prominent square unrounded
/// artwork with deep shadow, metadata, unified drag-to-dismiss chevron indicator,
/// and an ordered tracklist displaying track index numbers on the margin without track covers.
/// Refactored according to Low Coupling & High Cohesion principles into dedicated components.
///
/// Components / Classes / Functions:
/// - AlbumDetailScreen: Coordinator screen for inspecting and playing an album.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/scanner/music_indexer.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/components/album_header_view.dart';
import 'package:project_anima/features/album/components/album_tracks_section.dart';
import 'package:project_anima/features/player/components/mini_player.dart';

/// Full album presentation view with large square artwork, metadata, and ordered tracklist.
class AlbumDetailScreen extends StatefulWidget {
  /// Name of the album to display.
  final String albumName;

  /// Primary or credited artist of the album, if known.
  final String? artistName;

  /// Optional Android MediaStore album ID.
  final int? albumId;

  /// MediaStore ID of a representative song used for artwork lookup.
  final int? representativeSongId;

  /// Optional custom SongDao instance for dependency injection.
  final SongDao? songDao;

  /// Whether to run continuous idle bounce micro-animations (disabled in tests).
  final bool animateBounce;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    this.artistName,
    this.albumId,
    this.representativeSongId,
    this.songDao,
    this.animateBounce = true,
  });

  /// Factory helper for smooth bottom-to-top modal slide transition.
  static Route<void> route({
    required String albumName,
    String? artistName,
    int? albumId,
    int? representativeSongId,
    SongDao? songDao,
  }) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => AlbumDetailScreen(
        albumName: albumName,
        artistName: artistName,
        albumId: albumId,
        representativeSongId: representativeSongId,
        songDao: songDao,
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

  /// Sanitizes an artist name by stripping accidental category prefixes
  /// like 'Album • ', 'Álbum • ', 'album ', 'song • ', etc.
  static String? sanitizeArtist(String? raw) => sanitizeArtistName(raw);

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen>
    with SingleTickerProviderStateMixin {
  late final SongDao _songDao;
  double _dragOffset = 0.0;
  late final AnimationController _springController;
  Animation<double>? _springAnimation;

  bool _isLoading = true;
  List<Song> _songs = [];
  int? _resolvedRepresentativeId;
  String? _resolvedArtist;
  bool _isPinned = false;
  bool _isFlashingRed = false;

  /// Whether this album is currently pinned to favorites.
  bool get isPinned => _isPinned;

  String get _albumKey => PinnedFavoritesDao.albumKey(
        widget.albumName,
        _resolvedArtist ?? widget.artistName,
      );

  @override
  void initState() {
    super.initState();
    _songDao = widget.songDao ?? SongDao();
    _resolvedRepresentativeId = widget.representativeSongId;
    _resolvedArtist = AlbumDetailScreen.sanitizeArtist(widget.artistName);

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_springAnimation != null) {
          setState(() {
            _dragOffset = _springAnimation!.value;
          });
        }
      });

    _loadAlbumSongs();
    _checkPinnedStatus();
  }

  Future<void> _checkPinnedStatus() async {
    try {
      final pinned = await PinnedFavoritesDao.instance.isPinned(_albumKey);
      if (mounted) {
        setState(() {
          _isPinned = pinned;
        });
      }
    } catch (_) {}
  }

  Future<void> _togglePinned() async {
    try {
      final willPin = !_isPinned;
      HapticFeedback.mediumImpact();

      if (willPin && mounted) {
        setState(() {
          _isFlashingRed = true;
        });
      }

      final newStatus = await PinnedFavoritesDao.instance.togglePin(
        PinnedFavorite(
          itemType: PinnedItemType.album,
          itemKey: _albumKey,
          title: widget.albumName,
          subtitle: _resolvedArtist ?? widget.artistName,
          albumId: widget.albumId,
          representativeSongId: _resolvedRepresentativeId,
          pinnedAt: DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() {
          _isPinned = newStatus;
        });
      }

      if (willPin) {
        await Future.delayed(const Duration(milliseconds: 650));
        if (mounted) {
          setState(() {
            _isFlashingRed = false;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ [AlbumDetailScreen] Error toggling pin: $e');
      if (mounted) {
        setState(() {
          _isFlashingRed = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(double delta) {
    if (_springController.isAnimating) {
      _springController.stop();
    }
    setState(() {
      _dragOffset = math.max(0.0, _dragOffset + delta);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffset > 90.0 || velocity > 320.0) {
      Navigator.of(context).pop();
    } else if (_dragOffset > 0.0) {
      _springAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _springController,
          curve: Curves.easeOutQuad,
        ),
      );
      _springController.forward(from: 0.0);
    }
  }

  void _handleDismiss() {
    Navigator.of(context).pop();
  }

  Future<void> _loadAlbumSongs() async {
    try {
      var songs = await _songDao.getSongsByAlbum(
        widget.albumName,
        artist: _resolvedArtist,
        albumId: widget.albumId,
      );

      // Fallback: if scoped search returned 0 songs, try searching without artist filter
      if (songs.isEmpty && _resolvedArtist != null) {
        final fallback = await _songDao.getSongsByAlbum(
          widget.albumName,
          albumId: widget.albumId,
        );
        if (fallback.isNotEmpty) {
          songs = fallback;
        }
      }

      if (mounted) {
        setState(() {
          _songs = songs;
          if ((_resolvedRepresentativeId == null || _resolvedRepresentativeId == 0) &&
              songs.isNotEmpty) {
            _resolvedRepresentativeId = songs.first.mediaStoreId;
          }
          if (songs.isNotEmpty) {
            String? definitiveAlbumArtist;
            for (final s in songs) {
              if (s.albumArtist != null &&
                  s.albumArtist!.trim().isNotEmpty &&
                  s.albumArtist != '<Desconocido>' &&
                  s.albumArtist != 'Unknown Artist') {
                definitiveAlbumArtist = s.albumArtist!.trim();
                break;
              }
            }

            if (definitiveAlbumArtist != null) {
              _resolvedArtist = AlbumDetailScreen.sanitizeArtist(definitiveAlbumArtist);
            } else if (_resolvedArtist == null ||
                _resolvedArtist!.trim().isEmpty ||
                _resolvedArtist == '<Desconocido>' ||
                _resolvedArtist == 'Unknown Artist') {
              final firstArtist = songs.first.artist;
              if (firstArtist != null &&
                  firstArtist.trim().isNotEmpty &&
                  firstArtist != '<Desconocido>') {
                _resolvedArtist = AlbumDetailScreen.sanitizeArtist(firstArtist);
              }
            }
          }
          _isLoading = false;
        });

        _checkMissingTrackNumbers(songs);
      }
    } catch (e) {
      debugPrint('AlbumDetailScreen error loading album songs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkMissingTrackNumbers(List<Song> songs) async {
    final hasMissing = songs.any((s) => s.trackNumber == null || s.trackNumber! <= 0);
    if (!hasMissing) return;

    try {
      final updatedSongs = await MusicIndexer.instance.resolveMissingTrackNumbers(songs);
      if (mounted && updatedSongs != songs) {
        final reloaded = await _songDao.getSongsByAlbum(
          widget.albumName,
          artist: widget.artistName,
          albumId: widget.albumId,
        );
        if (mounted) {
          setState(() {
            _songs = reloaded;
          });
        }
      }
    } catch (e) {
      debugPrint('Error on-demand resolving track numbers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _songs.fold<int>(0, (sum, s) => sum + s.duration);

    return AnimatedContainer(
      duration: Duration(milliseconds: _isFlashingRed ? 250 : 500),
      curve: _isFlashingRed ? Curves.easeOutCubic : Curves.easeInCubic,
      color: _isFlashingRed ? AppColors.pinnedRedBackground : AppColors.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const SafeArea(
          top: false,
          child: MiniPlayer(),
        ),
        body: SafeArea(
          bottom: false,
          child: Transform.translate(
            offset: Offset(0.0, _dragOffset),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.accent,
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Universal Animated Dismiss Chevron (identical to player and artist)
                        const SizedBox(height: 4.0),
                        ModalDismissIndicator(
                          onDismiss: _handleDismiss,
                          onDragUpdate: _handleDragUpdate,
                          onDragEnd: _handleDragEnd,
                          size: 34.0,
                          color: AppColors.onSurfaceVariant,
                          animate: widget.animateBounce,
                          padding: const EdgeInsets.symmetric(
                            vertical: 6.0,
                            horizontal: 36.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),

                        // 2. Cohesive Album Header: Large Sharp Cover + Title + Artist + Duration + Heart
                        AlbumHeaderView(
                          albumName: widget.albumName,
                          artistName: _resolvedArtist,
                          albumId: widget.albumId,
                          representativeSongId: _resolvedRepresentativeId,
                          songCount: _songs.length,
                          totalDurationMs: totalMs,
                          isPinned: _isPinned,
                          onToggleFavorite: _togglePinned,
                        ),
                      const SizedBox(height: 24.0),

                      // 3. Cohesive Tracks Section: 'TRACKS' header + ordered track tiles
                      AlbumTracksSection(songs: _songs),

                      // Spacing above bottom MiniPlayer
                      const SizedBox(height: 32.0),
                    ],
                  ),
                ),
        ),
      ),
    ),
  );
}
}
