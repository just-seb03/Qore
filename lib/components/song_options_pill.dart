/// File: song_options_pill.dart
/// Description: Horizontal expanding pill menu replacing separate favorite and queue buttons
/// across song list tiles. Features a vertical 3-dots button beside the track duration.
/// When tapped, an animated pill expands horizontally from the 3-dots towards the left,
/// revealing 4 clean action icons without text:
/// 1. Add to playlist
/// 2. Favorites toggle (reactive heart)
/// 3. Add to beginning of queue (Play Next)
/// 4. Add to end of queue
///
/// Components / Classes / Functions:
/// - SongOptionsPillCoordinator: Singleton coordinator ensuring only one song options pill is open at a time,
///   and dismissing open pills automatically upon playback changes.
/// - SongOptionsPill: Stateful animated pill widget for track options.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/player/components/song_playlist_picker_sheet.dart';

/// Global coordinator managing single-active pill state across all track items.
class SongOptionsPillCoordinator extends ChangeNotifier {
  static final SongOptionsPillCoordinator instance = SongOptionsPillCoordinator._internal();

  SongOptionsPillCoordinator._internal() {
    // Automatically close any open options pill whenever playback starts or active song changes
    PlaybackController.instance.addListener(_onPlaybackChanged);
  }

  int? _activeSongMediaStoreId;

  /// Targeted notifier emitting the active song mediaStoreId for selective row updates.
  final ValueNotifier<int?> activeSongNotifier = ValueNotifier<int?>(null);

  /// Currently expanded song mediaStoreId, or null if all are collapsed.
  int? get activeSongMediaStoreId => _activeSongMediaStoreId;

  /// Whether the options pill for [mediaStoreId] is currently expanded.
  bool isExpanded(int mediaStoreId) => _activeSongMediaStoreId == mediaStoreId;

  void _onPlaybackChanged() {
    close();
  }

  /// Opens the options pill for [mediaStoreId], closing any other opened pill.
  void open(int mediaStoreId) {
    if (_activeSongMediaStoreId != mediaStoreId) {
      _activeSongMediaStoreId = mediaStoreId;
      activeSongNotifier.value = mediaStoreId;
      notifyListeners();
    }
  }

  /// Closes the options pill for [mediaStoreId], or all pills if [mediaStoreId] is null.
  void close([int? mediaStoreId]) {
    if (mediaStoreId == null || _activeSongMediaStoreId == mediaStoreId) {
      if (_activeSongMediaStoreId != null) {
        _activeSongMediaStoreId = null;
        activeSongNotifier.value = null;
        notifyListeners();
      }
    }
  }

  /// Toggles expansion for [mediaStoreId].
  void toggle(int mediaStoreId) {
    if (_activeSongMediaStoreId == mediaStoreId) {
      close(mediaStoreId);
    } else {
      open(mediaStoreId);
    }
  }

  /// Resets coordinator state (useful for tests).
  @visibleForTesting
  void reset() {
    _activeSongMediaStoreId = null;
    activeSongNotifier.value = null;
    notifyListeners();
  }
}

/// Animated pill menu for song row items.
class SongOptionsPill extends StatefulWidget {
  /// The song this options pill controls.
  final Song song;

  /// Formatted duration string to show beside the 3 dots when collapsed.
  final String? durationText;

  /// Optional override for Add to Playlist action.
  final VoidCallback? onPlaylistAdd;

  /// Optional override for Favorite toggle action.
  final VoidCallback? onFavoriteToggle;

  /// Optional override for Add to Front of Queue action.
  final VoidCallback? onQueueFirst;

  /// Optional override for Add to End of Queue action.
  final VoidCallback? onQueueEnd;

  /// Whether the pill starts expanded (useful for testing).
  final bool initialExpanded;

  const SongOptionsPill({
    super.key,
    required this.song,
    this.durationText,
    this.onPlaylistAdd,
    this.onFavoriteToggle,
    this.onQueueFirst,
    this.onQueueEnd,
    this.initialExpanded = false,
  });

  @override
  State<SongOptionsPill> createState() => _SongOptionsPillState();
}

class _SongOptionsPillState extends State<SongOptionsPill> {
  bool _isExpanded = false;
  bool _keepAnimatedWrapper = false;

  @override
  void initState() {
    super.initState();
    _isExpanded =
        SongOptionsPillCoordinator.instance.isExpanded(widget.song.mediaStoreId);
    _keepAnimatedWrapper = _isExpanded;
    SongOptionsPillCoordinator.instance.activeSongNotifier
        .addListener(_onActiveSongChanged);

    if (widget.initialExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SongOptionsPillCoordinator.instance.open(widget.song.mediaStoreId);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant SongOptionsPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.song.mediaStoreId != oldWidget.song.mediaStoreId) {
      final bool nextExpanded =
          SongOptionsPillCoordinator.instance.isExpanded(widget.song.mediaStoreId);
      _isExpanded = nextExpanded;
      if (nextExpanded) {
        _keepAnimatedWrapper = true;
      }
    }
  }

  @override
  void dispose() {
    SongOptionsPillCoordinator.instance.activeSongNotifier
        .removeListener(_onActiveSongChanged);
    super.dispose();
  }

  void _onActiveSongChanged() {
    final bool nextExpanded =
        SongOptionsPillCoordinator.instance.activeSongNotifier.value ==
            widget.song.mediaStoreId;
    if (nextExpanded != _isExpanded && mounted) {
      setState(() {
        _isExpanded = nextExpanded;
        if (_isExpanded) {
          _keepAnimatedWrapper = true;
        }
      });
    }
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    SongOptionsPillCoordinator.instance.toggle(widget.song.mediaStoreId);
  }

  void _close() {
    SongOptionsPillCoordinator.instance.close(widget.song.mediaStoreId);
  }

  Widget _buildIconButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.zero,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 6.0),
            child: Icon(
              icon,
              size: 19.0,
              color: color ?? AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPill(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.30),
          width: 0.8,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Add to Playlist
            _buildIconButton(
              key: ValueKey('song_pill_playlist_${widget.song.mediaStoreId}'),
              icon: Icons.playlist_add_rounded,
              tooltip: context.l10n.playlist.addToPlaylistTooltip,
              onTap: () {
                _close();
                if (widget.onPlaylistAdd != null) {
                  widget.onPlaylistAdd!();
                } else {
                  SongPlaylistPickerSheet.show(context, song: widget.song);
                }
              },
            ),

            // 2. Favorites Toggle (Reactive)
            ListenableBuilder(
              listenable: FavoriteSongsDao.instance.favoritesRevision,
              builder: (context, _) {
                final isFav =
                    FavoriteSongsDao.instance.isFavorite(widget.song.mediaStoreId);
                return _buildIconButton(
                  key: ValueKey('song_pill_favorite_${widget.song.mediaStoreId}'),
                  icon: isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.accent : AppColors.onSurfaceVariant,
                  tooltip: isFav
                      ? context.l10n.common.removeFromFavorites
                      : context.l10n.common.addToFavorites,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (widget.onFavoriteToggle != null) {
                      widget.onFavoriteToggle!();
                    } else {
                      FavoriteSongsDao.instance.toggleFavorite(widget.song);
                    }
                  },
                );
              },
            ),

            // 3. Add to Front of Queue (Play Next)
            _buildIconButton(
              key: ValueKey('song_pill_queue_first_${widget.song.mediaStoreId}'),
              icon: Icons.queue_play_next_rounded,
              tooltip: 'Reproducir a continuación',
              onTap: () {
                _close();
                HapticFeedback.lightImpact();
                if (widget.onQueueFirst != null) {
                  widget.onQueueFirst!();
                } else {
                  PlaybackController.instance.addToQueueFirst(widget.song);
                }
              },
            ),

            // 4. Add to End of Queue
            _buildIconButton(
              key: ValueKey('song_pill_queue_end_${widget.song.mediaStoreId}'),
              icon: Icons.add_to_queue_rounded,
              tooltip: 'Añadir al final de la cola',
              onTap: () {
                _close();
                HapticFeedback.lightImpact();
                if (widget.onQueueEnd != null) {
                  widget.onQueueEnd!();
                } else {
                  PlaybackController.instance.addToQueueEnd(widget.song);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final durationStr = widget.durationText;

    final triggerButton = IconButton(
      key: ValueKey('song_options_button_${widget.song.mediaStoreId}'),
      icon: Icon(
        _isExpanded ? Icons.close_rounded : Icons.more_vert_rounded,
        size: 20.0,
        color: _isExpanded ? AppColors.accent : AppColors.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30.0, minHeight: 30.0),
      splashRadius: 18.0,
      tooltip: _isExpanded ? 'Cerrar opciones' : 'Más opciones',
      onPressed: _toggle,
    );

    if (!_isExpanded && !_keepAnimatedWrapper) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (durationStr != null && durationStr.isNotEmpty) ...[
            Text(
              durationStr,
              style: AppFonts.segoe(
                fontSize: 12.0,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 2.0),
          ],
          triggerButton,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Horizontal Animated Pill (mounted only while expanded or collapsing)
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerRight,
          onEnd: () {
            if (!_isExpanded && _keepAnimatedWrapper && mounted) {
              setState(() {
                _keepAnimatedWrapper = false;
              });
            }
          },
          child: _isExpanded
              ? _buildExpandedPill(context)
              : const SizedBox.shrink(),
        ),

        // 2. Track Duration (visible when pill is collapsed)
        if (!_isExpanded && durationStr != null && durationStr.isNotEmpty) ...[
          Text(
            durationStr,
            style: AppFonts.segoe(
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 2.0),
        ],

        // 3. The 3 Dots Trigger Button (morphs to Close when expanded)
        triggerButton,
      ],
    );
  }
}
