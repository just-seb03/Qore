/// File: player_artwork_view.dart
/// Description: Full-width giant square album artwork component covering the entire
/// upper portion of the screen, featuring high-resolution decoding, top vignette scrim,
/// and overlaid dismiss chevron.
///
/// Components / Classes / Functions:
/// - PlayerArtworkView: Edge-to-edge square artwork container for the maximized player.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';

/// Full-width edge-to-edge square artwork view occupying the upper screen.
/// Proactively pre-decodes adjacent queue covers into Flutter's [ImageCache]
/// so skipping tracks in the expanded player transitions immediately without blank frames.
class PlayerArtworkView extends StatefulWidget {
  /// The song whose artwork is to be displayed.
  final Song? song;

  /// Target height for the artwork container.
  final double? height;

  /// Target width for the artwork container.
  final double? width;

  /// Optional callback to notify parent during an interactive vertical pull down.
  final ValueChanged<double>? onDragUpdate;

  /// Optional callback when an interactive drag completes.
  final ValueChanged<DragEndDetails>? onDragEnd;

  const PlayerArtworkView({
    super.key,
    required this.song,
    this.height,
    this.width,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  State<PlayerArtworkView> createState() => _PlayerArtworkViewState();
}

class _PlayerArtworkViewState extends State<PlayerArtworkView> {
  int? _lastPrecachedSongId;

  @override
  void initState() {
    super.initState();
    PlaybackController.instance.addListener(_onQueueOrTrackChanged);
    ArtworkService.instance.addListener(_onArtworkUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precacheAdjacentCovers();
    });
  }

  @override
  void didUpdateWidget(covariant PlayerArtworkView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.song?.mediaStoreId != oldWidget.song?.mediaStoreId ||
        widget.width != oldWidget.width) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _precacheAdjacentCovers(force: true);
      });
    }
  }

  @override
  void dispose() {
    PlaybackController.instance.removeListener(_onQueueOrTrackChanged);
    ArtworkService.instance.removeListener(_onArtworkUpdated);
    super.dispose();
  }

  void _onQueueOrTrackChanged() {
    if (mounted) {
      _precacheAdjacentCovers();
    }
  }

  void _onArtworkUpdated() {
    if (mounted) {
      _precacheAdjacentCovers(force: true);
    }
  }

  void _precacheAdjacentCovers({bool force = false}) {
    if (!mounted) return;
    final activeSong = widget.song;
    if (!force &&
        activeSong != null &&
        _lastPrecachedSongId == activeSong.mediaStoreId) {
      return;
    }
    _lastPrecachedSongId = activeSong?.mediaStoreId;

    final screenWidth = MediaQuery.maybeSizeOf(context)?.width ?? 400.0;
    final double effectiveWidth = widget.width ?? screenWidth;

    final controller = PlaybackController.instance;
    final queue = controller.queue;
    final int idx = controller.currentIndex;

    final List<Song> candidates = [];
    if (activeSong != null) candidates.add(activeSong);

    if (queue.isNotEmpty && idx >= 0 && idx < queue.length) {
      for (final offset in const [1, -1, 2]) {
        int neighborIdx = idx + offset;
        if (neighborIdx >= queue.length) {
          neighborIdx = neighborIdx % queue.length;
        } else if (neighborIdx < 0) {
          neighborIdx = (neighborIdx % queue.length + queue.length) % queue.length;
        }
        final neighbor = queue[neighborIdx];
        if (!candidates.any((s) => s.mediaStoreId == neighbor.mediaStoreId)) {
          candidates.add(neighbor);
        }
      }
    }

    if (candidates.isEmpty) return;

    // Prioritize extraction if any neighbor lacks cached cover art
    ArtworkService.instance
        .prioritizeSongIds(candidates.map((s) => s.mediaStoreId).toList());

    for (final candidate in candidates) {
      unawaited(
        AnimaArtworkImage.precacheSongArtwork(
          context,
          mediaStoreId: candidate.mediaStoreId,
          albumId: candidate.albumId,
          albumName: candidate.album,
          artistName: candidate.albumArtist ?? candidate.artist,
          width: effectiveWidth,
          isThumbnail: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double effectiveWidth = widget.width ?? screenWidth;
    final double effectiveHeight = widget.height ?? screenWidth;
    final song = widget.song;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: widget.onDragUpdate != null
          ? (details) => widget.onDragUpdate!(details.primaryDelta ?? 0.0)
          : null,
      onVerticalDragEnd: widget.onDragEnd,
      child: SizedBox(
        width: effectiveWidth,
        height: effectiveHeight, // Edge-to-edge giant square covering full width
        child: song != null
            ? AnimaArtworkImage(
                mediaStoreId: song.mediaStoreId,
                albumId: song.albumId,
                albumName: song.album,
                artistName: song.albumArtist ?? song.artist,
                width: effectiveWidth,
                height: effectiveHeight,
                borderRadius: 0.0,
                isThumbnail: false,
                fit: BoxFit.cover,
                fallbackIcon: Icons.music_note_rounded,
              )
            : Container(
                color: const Color(0xFF141417),
                child: const Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 96.0,
                    color: Color(0xFF4A4A52),
                  ),
                ),
              ),
      ),
    );
  }
}
