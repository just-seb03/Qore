/// File: artist_detail_screen.dart
/// Description: Material Design 3 Expressive Artist Detail Screen featuring
/// large interactive circular avatar with 1:1 image customization, typography hierarchy,
/// user top 3 played tracks, horizontal discography carousel, and assorted chronological songs.
///
/// Components / Classes / Functions:
/// - ArtistDetailScreen: Main artist detail screen widget.
/// - _ArtistHeaderView: Top avatar with pencil edit badge and centered artist name.
/// - _TopTracksSection: Displays the user's top 3 most played songs of this artist.
/// - _DiscographySection: Horizontal scrolling carousel of the artist's albums.
/// - _AssortedSongsSection: Chronological list of up to 10 assorted tracks.
library;

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist/components/artist_avatar_crop_screen.dart';
import 'package:project_anima/features/player/components/mini_player.dart';
import 'package:project_anima/features/search/components/common/material_artist_avatar.dart';

/// Full artist view with profile customization, top tracks, discography, and song assortment.
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
  double _dragOffset = 0.0;
  late final AnimationController _springController;
  Animation<double>? _springAnimation;

  bool _isLoading = true;
  List<Song> _topSongs = [];
  List<AlbumDiscoveryItem> _albums = [];
  List<Song> _assortedSongs = [];

  @override
  void initState() {
    super.initState();
    _songDao = widget.songDao ?? SongDao();
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
      final topFuture = _songDao.getTopSongsByArtist(widget.artistName, limit: 3);
      final albumsFuture = _songDao.getAlbumsByArtist(widget.artistName);
      final assortedFuture =
          _songDao.getAssortedSongsByArtist(widget.artistName, limit: 5);

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
        ArtworkService.instance.getCustomArtistAvatar(widget.artistName) != null;

    if (hasCustomPhoto) {
      _showPhotoOptionsSheet();
    } else {
      await _pickAndCropNewPhoto();
    }
  }

  void _showPhotoOptionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.0,
                  height: 4.0,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
                  title: Text(
                    'Change artist photo',
                    style: GoogleFonts.outfit(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickAndCropNewPhoto();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: Text(
                    'Remove custom photo',
                    style: GoogleFonts.outfit(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await ArtworkService.instance.removeCustomArtistAvatar(widget.artistName);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Artist photo reset to default'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
            .setCustomArtistAvatar(widget.artistName, croppedBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Artist photo updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking or cropping artist photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                      // Downward Animated Dismiss Chevron (lowered down for easy reach)
                      const SizedBox(height: 14.0),
                      Center(
                        child: _ArtistDismissIndicator(
                          onDismiss: _handleDismiss,
                          onDragUpdate: _handleDragUpdate,
                          onDragEnd: _handleDragEnd,
                        ),
                      ),
                      const SizedBox(height: 12.0),

                      // 1. Top Avatar with Glow, Pencil Badge & Artist Name
                      _ArtistHeaderView(
                        artistName: widget.artistName,
                        onEditTap: _handleEditPhoto,
                      ),
                      const SizedBox(height: 30.0),

                      // 2. User Top 3 Most Listened Tracks (Without margin numbers)
                      if (_topSongs.isNotEmpty) ...[
                        _TopTracksSection(
                          topSongs: _topSongs,
                          allArtistSongs: _assortedSongs.isNotEmpty
                              ? _assortedSongs
                              : _topSongs,
                        ),
                        const SizedBox(height: 30.0),
                      ],

                      // 3. Discography Horizontal Carousel with dummy navigation arrow
                      if (_albums.isNotEmpty) ...[
                        _DiscographySection(albums: _albums),
                        const SizedBox(height: 30.0),
                      ],

                      // 4. Assorted Tracks (Up to 5, without covers, compact) with dummy navigation arrow
                      if (_assortedSongs.isNotEmpty) ...[
                        _AssortedSongsSection(
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
    );
  }
}

/// Downward-pointing animated chevron dismiss indicator cueing swipe-down or tap to exit.
class _ArtistDismissIndicator extends StatefulWidget {
  final VoidCallback onDismiss;
  final ValueChanged<double>? onDragUpdate;
  final ValueChanged<DragEndDetails>? onDragEnd;

  const _ArtistDismissIndicator({
    required this.onDismiss,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  State<_ArtistDismissIndicator> createState() => _ArtistDismissIndicatorState();
}

class _ArtistDismissIndicatorState extends State<_ArtistDismissIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onDismiss,
      onVerticalDragUpdate: (details) {
        if (widget.onDragUpdate != null) {
          widget.onDragUpdate!(details.primaryDelta ?? 0.0);
        } else if ((details.primaryDelta ?? 0.0) > 6.0) {
          widget.onDismiss();
        }
      },
      onVerticalDragEnd: (details) {
        if (widget.onDragEnd != null) {
          widget.onDragEnd!(details);
        } else if ((details.primaryVelocity ?? 0.0) > 200.0) {
          widget.onDismiss();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 36.0),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0.0, _bounceAnimation.value),
                child: child,
              );
            },
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 34.0,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Large interactive header featuring circular avatar, atmospheric halo glow,
/// floating pencil edit badge, and centered artist name directly below.
class _ArtistHeaderView extends StatelessWidget {
  final String artistName;
  final VoidCallback onEditTap;

  const _ArtistHeaderView({
    required this.artistName,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Avatar with Atmospheric Halo & Floating Edit Pencil Badge
          Stack(
            alignment: Alignment.center,
            children: [
              // Ambient soft halo
              Container(
                width: 200.0,
                height: 200.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 22.0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: MaterialArtistAvatar(
                      radius: 66.0,
                      artistName: artistName,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      iconColor: AppColors.onSurfaceVariant,
                    ),
                  ),

                  // Sleek Elevated Edit Button
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onEditTap,
                      child: Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 8.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 19.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Artist Name Typography directly below avatar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              artistName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 27.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section rendering the user's top 3 most listened songs of this artist.
/// Displays cover thumbnail, title, and album without rank numbers on the margin.
class _TopTracksSection extends StatelessWidget {
  final List<Song> topSongs;
  final List<Song> allArtistSongs;

  const _TopTracksSection({
    required this.topSongs,
    required this.allArtistSongs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'FEATURED',
            style: GoogleFonts.inconsolata(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: topSongs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6.0),
          itemBuilder: (context, index) {
            final song = topSongs[index];
            return _TopTrackTile(
              song: song,
              allArtistSongs: allArtistSongs,
            );
          },
        ),
      ],
    );
  }
}

/// Track tile for Top 3 most listened songs (cover thumbnail, title, album, duration, no margin rank numbers).
class _TopTrackTile extends StatelessWidget {
  final Song song;
  final List<Song> allArtistSongs;

  const _TopTrackTile({
    required this.song,
    required this.allArtistSongs,
  });

  String _formatDuration(int? ms) {
    if (ms == null || ms <= 0) return '';
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final activeController = PlaybackController.instance;

    return ListenableBuilder(
      listenable: activeController,
      builder: (context, _) {
        final isCurrentTrack =
            activeController.currentSong?.mediaStoreId == song.mediaStoreId;
        final isPlaying = isCurrentTrack && activeController.isPlaying;
        final durationStr = _formatDuration(song.duration);

        return Material(
          color: isCurrentTrack
              ? AppColors.surfaceContainerHigh.withValues(alpha: 0.6)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(14.0),
            onTap: () {
              if (isCurrentTrack) {
                activeController.togglePlayPause();
              } else {
                activeController.playSong(song, queue: allArtistSongs);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Row(
                children: [
                  // Artwork Thumbnail
                  AnimaArtworkImage(
                    mediaStoreId: song.mediaStoreId,
                    albumId: song.albumId,
                    width: 48.0,
                    height: 48.0,
                    borderRadius: 11.0,
                    isThumbnail: true,
                  ),
                  const SizedBox(width: 14.0),

                  // Song Title & Album Name (No play count, no margin numbers)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                            color: isCurrentTrack
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          song.album ?? 'Unknown Album',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inconsolata(
                            fontSize: 12.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Duration text
                  if (durationStr.isNotEmpty && !isCurrentTrack)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                      child: Text(
                        durationStr,
                        style: GoogleFonts.inconsolata(
                          fontSize: 12.0,
                          color: AppColors.onSurfaceDisabled,
                        ),
                      ),
                    ),

                  // Active Play/Pause Indicator Icon
                  if (isCurrentTrack)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22.0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Discography horizontal scrolling list showing albums with dummy navigation arrow.
class _DiscographySection extends StatelessWidget {
  final List<AlbumDiscoveryItem> albums;

  const _DiscographySection({required this.albums});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Text(
                'DISCOGRAPHY',
                style: GoogleFonts.inconsolata(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Dummy navigation arrow indicating full albums view
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13.0,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 192.0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: albums.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14.0),
            itemBuilder: (context, index) {
              final album = albums[index];
              final countStr =
                  '${album.songCount} ${album.songCount == 1 ? "song" : "songs"}';

              return SizedBox(
                width: 134.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimaArtworkImage(
                        mediaStoreId: album.representativeSongId,
                        albumId: album.albumId,
                        width: 134.0,
                        height: 134.0,
                        borderRadius: 16.0,
                        fallbackIcon: Icons.album_rounded,
                        isThumbnail: false,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      album.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      countStr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inconsolata(
                        fontSize: 12.0,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Chronological assorted tracks section showing up to 5 songs without covers, compact styling.
class _AssortedSongsSection extends StatelessWidget {
  final List<Song> songs;
  final List<Song> allArtistSongs;

  const _AssortedSongsSection({
    required this.songs,
    required this.allArtistSongs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Text(
                'SONGS',
                style: GoogleFonts.inconsolata(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Dummy navigation arrow indicating full songs view
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13.0,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: songs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 3.0),
          itemBuilder: (context, index) {
            final song = songs[index];
            return _CompactTrackTile(
              song: song,
              allArtistSongs: allArtistSongs,
            );
          },
        ),
      ],
    );
  }
}

/// Compact track tile without covers, clean typography for the up to 5 assorted tracks list.
class _CompactTrackTile extends StatelessWidget {
  final Song song;
  final List<Song> allArtistSongs;

  const _CompactTrackTile({
    required this.song,
    required this.allArtistSongs,
  });

  String _formatDuration(int? ms) {
    if (ms == null || ms <= 0) return '';
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final activeController = PlaybackController.instance;

    return ListenableBuilder(
      listenable: activeController,
      builder: (context, _) {
        final isCurrentTrack =
            activeController.currentSong?.mediaStoreId == song.mediaStoreId;
        final isPlaying = isCurrentTrack && activeController.isPlaying;
        final durationStr = _formatDuration(song.duration);

        return Material(
          color: isCurrentTrack
              ? AppColors.surfaceContainerHigh.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(10.0),
            onTap: () {
              if (isCurrentTrack) {
                activeController.togglePlayPause();
              } else {
                activeController.playSong(song, queue: allArtistSongs);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
              child: Row(
                children: [
                  // Title & Album only (No cover)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14.0,
                            fontWeight: isCurrentTrack
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isCurrentTrack
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.90),
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          song.album ?? 'Unknown Album',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inconsolata(
                            fontSize: 11.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Duration text
                  if (durationStr.isNotEmpty && !isCurrentTrack)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 2.0),
                      child: Text(
                        durationStr,
                        style: GoogleFonts.inconsolata(
                          fontSize: 11.5,
                          color: AppColors.onSurfaceDisabled,
                        ),
                      ),
                    ),

                  // Active Play/Pause Indicator Icon
                  if (isCurrentTrack)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
