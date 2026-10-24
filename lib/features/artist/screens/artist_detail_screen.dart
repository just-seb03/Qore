/// File: artist_detail_screen.dart
/// Description: Material Design 3 Expressive Artist Detail Screen coordinating
/// artist profile customization, top played tracks, horizontal discography, and assorted songs.
/// Decoupled into specialized component views for high cohesion and low coupling.
///
/// Components / Classes / Functions:
/// - ArtistDetailScreen: Main artist detail coordinator screen widget.
/// - _ArtistDetailScreenState: State managing drag-down dismiss, async queries, and photo picking.
library;

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist/components/artist_assorted_songs_section.dart';
import 'package:project_anima/features/artist/components/artist_discography_section.dart';
import 'package:project_anima/features/artist/components/artist_header_view.dart';
import 'package:project_anima/features/artist/components/artist_photo_options_sheet.dart';
import 'package:project_anima/features/artist/components/artist_top_tracks_section.dart';
import 'package:project_anima/features/artist/screens/artist_avatar_crop_screen.dart';
import 'package:project_anima/features/player/components/mini_player.dart';

/// Full artist view coordinating profile customization, top tracks, discography, and song assortment.
class ArtistDetailScreen extends StatefulWidget {
  /// Name of the artist to display.
  final String artistName;

  /// Optional custom SongDao instance for dependency injection.
  final SongDao? songDao;

  const ArtistDetailScreen({
    super.key,
    required this.artistName,
    this.songDao,
  });

  /// Factory helper for smooth bottom-to-top modal slide transition.
  static Route<void> route(String artistName) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ArtistDetailScreen(artistName: artistName),
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
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen>
    with SingleTickerProviderStateMixin {
  late final SongDao _songDao;
  late final String _resolvedArtistName;
  double _dragOffset = 0.0;
  late final AnimationController _springController;
  Animation<double>? _springAnimation;

  bool _isLoading = true;
  List<Song> _topSongs = [];
  List<AlbumDiscoveryItem> _albums = [];
  List<Song> _assortedSongs = [];
  bool _isPinned = false;
  bool _isFlashingRed = false;

  /// Whether this artist is currently pinned to favorites.
  bool get isPinned => _isPinned;

  String get _artistKey => PinnedFavoritesDao.artistKey(_resolvedArtistName);

  @override
  void initState() {
    super.initState();
    _songDao = widget.songDao ?? SongDao();
    _resolvedArtistName = sanitizeArtistName(widget.artistName) ?? widget.artistName.trim();
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
    _loadArtistData();
    _checkPinnedStatus();
  }

  Future<void> _checkPinnedStatus() async {
    try {
      final pinned = await PinnedFavoritesDao.instance.isPinned(_artistKey);
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
          itemType: PinnedItemType.artist,
          itemKey: _artistKey,
          title: _resolvedArtistName,
          subtitle: 'Artist',
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
      debugPrint('⚠️ [ArtistDetailScreen] Error toggling pin: $e');
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
          curve: Curves.easeOutCubic,
        ),
      );
      _springController.forward(from: 0.0);
    }
  }

  void _handleDismiss() {
    Navigator.of(context).pop();
  }

  Future<void> _loadArtistData() async {
    setState(() => _isLoading = true);

    try {
      final topFuture = _songDao.getTopSongsByArtist(_resolvedArtistName, limit: 3);
      final albumsFuture = _songDao.getAlbumsByArtist(_resolvedArtistName);
      final assortedFuture =
          _songDao.getAssortedSongsByArtist(_resolvedArtistName, limit: 5);

      final results = await Future.wait([topFuture, albumsFuture, assortedFuture]);

      if (mounted) {
        setState(() {
          _topSongs = results[0] as List<Song>;
          _albums = results[1] as List<AlbumDiscoveryItem>;
          _assortedSongs = results[2] as List<Song>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ArtistDetailScreen error loading artist data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEditPhoto() async {
    final hasCustomPhoto =
        ArtworkService.instance.getCustomArtistAvatar(_resolvedArtistName) != null;

    if (hasCustomPhoto) {
      ArtistPhotoOptionsSheet.show(
        context,
        onChangePhoto: _pickAndCropNewPhoto,
        onRemovePhoto: _removeCustomPhoto,
      );
    } else {
      await _pickAndCropNewPhoto();
    }
  }

  Future<void> _removeCustomPhoto() async {
    await ArtworkService.instance.removeCustomArtistAvatar(_resolvedArtistName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artist photo reset to default'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {});
    }
  }

  Future<void> _pickAndCropNewPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (pickedFile == null || !mounted) return;

      final file = File(pickedFile.path);
      final Uint8List? croppedBytes = await Navigator.of(context).push<Uint8List?>(
        ArtistAvatarCropScreen.route(imageFile: file),
      );

      if (croppedBytes != null && mounted) {
        await ArtworkService.instance
            .setCustomArtistAvatar(_resolvedArtistName, croppedBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Artist photo updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error picking or cropping artist photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Downward Animated Dismiss Chevron
                        const SizedBox(height: 4.0),
                        Center(
                          child: ModalDismissIndicator(
                            onDismiss: _handleDismiss,
                            onDragUpdate: _handleDragUpdate,
                            onDragEnd: _handleDragEnd,
                            size: 34.0,
                            color: AppColors.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 36.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),

                        // 1. Top Avatar with Glow, Pencil Badge & Artist Name
                        ArtistHeaderView(
                          artistName: _resolvedArtistName,
                          onEditTap: _handleEditPhoto,
                          isPinned: _isPinned,
                          onToggleFavorite: _togglePinned,
                        ),
                        const SizedBox(height: 30.0),

                        // 2. User Top 3 Most Listened Tracks
                        if (_topSongs.isNotEmpty) ...[
                          ArtistTopTracksSection(
                            topSongs: _topSongs,
                            allArtistSongs: _assortedSongs.isNotEmpty
                                ? _assortedSongs
                                : _topSongs,
                          ),
                          const SizedBox(height: 30.0),
                        ],

                        // 3. Discography Horizontal Carousel
                        if (_albums.isNotEmpty) ...[
                          ArtistDiscographySection(albums: _albums),
                          const SizedBox(height: 30.0),
                        ],

                        // 4. Assorted Tracks
                        if (_assortedSongs.isNotEmpty) ...[
                          ArtistAssortedSongsSection(
                            songs: _assortedSongs,
                            allArtistSongs: _assortedSongs,
                          ),
                        ],

                        // Spacing above bottom MiniPlayer
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
