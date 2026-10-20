/// File: search_album_component.dart
/// Description: Authentic Spotify-styled modular search component for Albums.
/// Features a prominent Top Result card with Spotify-accurate surface (#181818),
/// square artwork, floating play button, and a horizontal carousel with 130dp square album cards.
///
/// Components / Classes / Functions:
/// - SearchAlbumComponent: Main widget presenting album search results.
/// - _AlbumTopResultCard: Full Spotify-styled Top Result card for an album.
/// - _AlbumSecondaryCard: Spotify-styled square album card for carousel.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Spotify-style Album presentation component for search results.
class SearchAlbumComponent extends StatelessWidget {
  /// The album to display as the prominent Top Result, if any.
  final AlbumDiscoveryItem? topResultAlbum;

  /// Secondary albums matching the query or related to the top result.
  final List<AlbumDiscoveryItem> secondaryAlbums;

  /// Callback when an album card is tapped.
  final ValueChanged<AlbumDiscoveryItem>? onAlbumTap;

  /// Whether to render only as the Top Result card.
  final bool isTopResultOnly;

  const SearchAlbumComponent({
    super.key,
    this.topResultAlbum,
    this.secondaryAlbums = const [],
    this.onAlbumTap,
    this.isTopResultOnly = false,
  });

  static final TextStyle _sectionHeaderStyle = GoogleFonts.zenDots(
    fontSize: 13.5,
    letterSpacing: 1.2,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    if (isTopResultOnly && topResultAlbum != null) {
      return _AlbumTopResultCard(
        album: topResultAlbum!,
        onTap: () => onAlbumTap?.call(topResultAlbum!),
      );
    }

    if (secondaryAlbums.isEmpty && topResultAlbum == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topResultAlbum != null) ...[
          _AlbumTopResultCard(
            album: topResultAlbum!,
            onTap: () => onAlbumTap?.call(topResultAlbum!),
          ),
          const SizedBox(height: 24.0),
        ],
        if (secondaryAlbums.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'ALBUMS',
              style: _sectionHeaderStyle,
            ),
          ),
          const SizedBox(height: 6.0),
          SizedBox(
            height: 188.0,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: secondaryAlbums.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16.0),
              itemBuilder: (context, index) {
                final album = secondaryAlbums[index];
                return _AlbumSecondaryCard(
                  album: album,
                  onTap: () => onAlbumTap?.call(album),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Full Spotify-styled Top Result card for an Album.
class _AlbumTopResultCard extends StatelessWidget {
  final AlbumDiscoveryItem album;
  final VoidCallback? onTap;

  const _AlbumTopResultCard({
    required this.album,
    this.onTap,
  });

  static final TextStyle _topResultHeaderStyle = GoogleFonts.zenDots(
    fontSize: 13.5,
    letterSpacing: 1.2,
    color: Colors.white,
  );

  static final TextStyle _albumTitleStyle = GoogleFonts.inconsolata(
    fontSize: 25.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: Colors.white,
  );

  static final TextStyle _badgeTextStyle = GoogleFonts.inconsolata(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: Colors.white,
  );

  static final TextStyle _metadataTextStyle = GoogleFonts.inconsolata(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'TOP RESULT',
              style: _topResultHeaderStyle,
            ),
          ),
          Material(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(10.0),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10.0),
              splashColor: const Color(0xFF282828),
              highlightColor: const Color(0xFF222222),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  children: [
                    // Square Album Cover with subtle drop shadow
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimaArtworkImage(
                        mediaStoreId: album.representativeSongId,
                        albumId: album.albumId,
                        width: 84.0,
                        height: 84.0,
                        borderRadius: 6.0,
                        fallbackIcon: Icons.album_rounded,
                        isThumbnail: true,
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    // Album metadata & Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            album.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _albumTitleStyle,
                          ),
                          const SizedBox(height: 10.0),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF282828),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Text(
                                  'ALBUM',
                                  style: _badgeTextStyle,
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              Flexible(
                                child: Text(
                                  album.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _metadataTextStyle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            '${album.songCount} ${album.songCount == 1 ? "canción" : "canciones"}',
                            style: _metadataTextStyle.copyWith(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    // Spotify circular play button
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: AppColors.futuristicWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFF121212),
                          size: 30.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Spotify-styled square album card for carousel.
class _AlbumSecondaryCard extends StatelessWidget {
  final AlbumDiscoveryItem album;
  final VoidCallback? onTap;

  const _AlbumSecondaryCard({
    required this.album,
    this.onTap,
  });

  static final TextStyle _titleStyle = GoogleFonts.inconsolata(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static final TextStyle _artistStyle = GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.0),
        splashColor: const Color(0xFF282828),
        child: SizedBox(
          width: 128.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Square Album Cover with subtle shadow
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8.0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: AnimaArtworkImage(
                  mediaStoreId: album.representativeSongId,
                  albumId: album.albumId,
                  width: 128.0,
                  height: 128.0,
                  borderRadius: 6.0,
                  fallbackIcon: Icons.album_rounded,
                  isThumbnail: true,
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                album.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _titleStyle,
              ),
              const SizedBox(height: 3.0),
              Text(
                album.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _artistStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
