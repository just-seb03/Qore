/// File: profile_stats_widgets.dart
/// Description: Windows Phone Metro stat tiles for ProfileScreen: total listening time
/// indicators (days, hours, minutes), top artists, top albums, and favorite genre tile.
///
/// Components / Classes / Functions:
/// - ProfileListeningTimeRow: Three Metro counters for days, hours, and minutes.
/// - ProfileTopArtistTile: Metro artist row with square portrait and navigation.
/// - ProfileTopAlbumTile: Metro album row with square artwork and navigation.
/// - ProfileFavoriteGenreTile: Metro tile displaying the user's favorite genre.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';

/// Three Windows Phone Metro numeric tiles showing total playback time in days, hours, and minutes.
class ProfileListeningTimeRow extends StatelessWidget {
  final int totalPlaybackMs;
  final bool isSpanish;

  const ProfileListeningTimeRow({
    super.key,
    required this.totalPlaybackMs,
    required this.isSpanish,
  });

  @override
  Widget build(BuildContext context) {
    final int totalMinutes = totalPlaybackMs > 0 ? totalPlaybackMs ~/ 60000 : 0;
    final int days = totalMinutes ~/ (24 * 60);
    final int hours = (totalMinutes % (24 * 60)) ~/ 60;
    final int minutes = totalMinutes % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _MetroTimeCell(
              key: const ValueKey('profile_time_days'),
              value: days.toString(),
              label: isSpanish ? 'DÍAS' : 'DAYS',
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: _MetroTimeCell(
              key: const ValueKey('profile_time_hours'),
              value: hours.toString(),
              label: isSpanish ? 'HORAS' : 'HOURS',
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: _MetroTimeCell(
              key: const ValueKey('profile_time_minutes'),
              value: minutes.toString(),
              label: isSpanish ? 'MINUTOS' : 'MINUTES',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetroTimeCell extends StatelessWidget {
  final String value;
  final String label;

  const _MetroTimeCell({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.28),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.light(
              fontSize: 30.0,
              color: AppColors.accent,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.segoe(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Metro artist row with sharp square portrait and navigation to ArtistDetailScreen.
class ProfileTopArtistTile extends StatelessWidget {
  final ArtistDiscoveryItem artist;
  final int rank;
  final bool isSpanish;

  const ProfileTopArtistTile({
    super.key,
    required this.artist,
    required this.rank,
    required this.isSpanish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.85),
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.28),
            width: 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.zero,
          child: InkWell(
            borderRadius: BorderRadius.zero,
            splashColor: AppColors.accent.withValues(alpha: 0.15),
            onTap: () {
              Navigator.of(context).push(
                ArtistDetailScreen.route(artist.name),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 24.0,
                    child: Text(
                      '0$rank',
                      style: AppFonts.segoe(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: rank == 1
                            ? AppColors.accent
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  _SquareArtistThumb(artistName: artist.name),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.light(
                        fontSize: 19.0,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 20.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareArtistThumb extends StatelessWidget {
  final String artistName;

  const _SquareArtistThumb({required this.artistName});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ArtworkService.instance,
      builder: (context, _) {
        final customSquare =
            ArtworkService.instance.getCustomArtistSquarePhoto(artistName);
        final hasPhoto =
            customSquare != null && File(customSquare).existsSync();
        final version =
            ArtworkService.instance.getArtistAvatarVersion(artistName);

        return Container(
          width: 48.0,
          height: 48.0,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.zero,
          ),
          clipBehavior: Clip.antiAlias,
          child: hasPhoto
              ? Image(
                  key: ValueKey('${customSquare}_v$version'),
                  image: ResizeImage(
                    FileImage(File(customSquare)),
                    width: 120,
                    height: 120,
                    policy: ResizeImagePolicy.fit,
                  ),
                  fit: BoxFit.cover,
                  width: 48.0,
                  height: 48.0,
                )
              : Icon(
                  Icons.person_rounded,
                  size: 26.0,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.65),
                ),
        );
      },
    );
  }
}

/// Metro album row with sharp square artwork and navigation to AlbumDetailScreen.
class ProfileTopAlbumTile extends StatelessWidget {
  final AlbumDiscoveryItem album;
  final int rank;

  const ProfileTopAlbumTile({
    super.key,
    required this.album,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.85),
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.28),
            width: 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.zero,
          child: InkWell(
            borderRadius: BorderRadius.zero,
            splashColor: AppColors.accent.withValues(alpha: 0.15),
            onTap: () {
              Navigator.of(context).push(
                AlbumDetailScreen.route(
                  albumName: album.name,
                  artistName: album.artist,
                  albumId: album.albumId,
                  representativeSongId: album.representativeSongId,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 24.0,
                    child: Text(
                      '0$rank',
                      style: AppFonts.segoe(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: rank == 1
                            ? AppColors.accent
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  AnimaArtworkImage(
                    mediaStoreId: album.representativeSongId,
                    albumId: album.albumId,
                    albumName: album.name,
                    artistName: album.artist,
                    width: 48.0,
                    height: 48.0,
                    borderRadius: 0.0,
                    isThumbnail: true,
                    fallbackIcon: Icons.album_rounded,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          album.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.light(
                            fontSize: 18.0,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          album.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.segoe(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w300,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 20.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Metro tile displaying the user's most played genre.
class ProfileFavoriteGenreTile extends StatelessWidget {
  final String genre;

  const ProfileFavoriteGenreTile({
    super.key,
    required this.genre,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.85),
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.28),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 22.0,
              color: AppColors.accent,
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Text(
                genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.light(
                  fontSize: 20.0,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
