/// File: search_artist_component.dart
/// Description: Authentic Spotify-styled modular search component for Artists.
/// Features a native Material Design circular avatar (no album covers), prominent
/// Top Result card with Spotify-accurate surface and floating play button,
/// and secondary horizontal artist carousel with generous 120dp touch targets.
///
/// Components / Classes / Functions:
/// - SearchArtistComponent: Main widget presenting artist search results.
/// - _ArtistTopResultCard: Full Spotify-styled Top Result card.
/// - _ArtistSecondaryCard: Spotify-styled circular artist card for carousel.
/// - _MaterialArtistAvatar: Native Material Design circular avatar.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Spotify-style Artist presentation component using native Material Design avatars.
class SearchArtistComponent extends StatelessWidget {
  /// The artist to display as the prominent Top Result, if any.
  final ArtistDiscoveryItem? topResultArtist;

  /// Secondary artists matching the query or related to the top result.
  final List<ArtistDiscoveryItem> secondaryArtists;

  /// Callback when an artist card is tapped.
  final ValueChanged<ArtistDiscoveryItem>? onArtistTap;

  /// Whether to render only as the Top Result card.
  final bool isTopResultOnly;

  const SearchArtistComponent({
    super.key,
    this.topResultArtist,
    this.secondaryArtists = const [],
    this.onArtistTap,
    this.isTopResultOnly = false,
  });

  static final TextStyle _sectionHeaderStyle = GoogleFonts.zenDots(
    fontSize: 13.5,
    letterSpacing: 1.2,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    if (isTopResultOnly && topResultArtist != null) {
      return _ArtistTopResultCard(
        artist: topResultArtist!,
        onTap: () => onArtistTap?.call(topResultArtist!),
      );
    }

    if (secondaryArtists.isEmpty && topResultArtist == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topResultArtist != null) ...[
          _ArtistTopResultCard(
            artist: topResultArtist!,
            onTap: () => onArtistTap?.call(topResultArtist!),
          ),
          const SizedBox(height: 24.0),
        ],
        if (secondaryArtists.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'ARTISTS',
              style: _sectionHeaderStyle,
            ),
          ),
          const SizedBox(height: 6.0),
          SizedBox(
            height: 164.0,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: secondaryArtists.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16.0),
              itemBuilder: (context, index) {
                final artist = secondaryArtists[index];
                return _ArtistSecondaryCard(
                  artist: artist,
                  onTap: () => onArtistTap?.call(artist),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Native Material Design 3 circular artist avatar.
class _MaterialArtistAvatar extends StatelessWidget {
  final double size;

  const _MaterialArtistAvatar({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF282828),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.54,
          color: const Color(0xFFB3B3B3),
        ),
      ),
    );
  }
}

/// Full Spotify-styled Top Result card for an Artist.
class _ArtistTopResultCard extends StatelessWidget {
  final ArtistDiscoveryItem artist;
  final VoidCallback? onTap;

  const _ArtistTopResultCard({
    required this.artist,
    this.onTap,
  });

  static final TextStyle _topResultHeaderStyle = GoogleFonts.zenDots(
    fontSize: 13.5,
    letterSpacing: 1.2,
    color: Colors.white,
  );

  static final TextStyle _artistNameStyle = GoogleFonts.inconsolata(
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

  static final TextStyle _statsTextStyle = GoogleFonts.inconsolata(
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
                    // Native Material Design Avatar (no album cover)
                    const _MaterialArtistAvatar(size: 84.0),
                    const SizedBox(width: 20.0),
                    // Artist info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            artist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _artistNameStyle,
                          ),
                          const SizedBox(height: 10.0),
                          Row(
                            children: [
                              // Spotify-style dark capsule badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF282828),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Text(
                                  'ARTIST',
                                  style: _badgeTextStyle,
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              Flexible(
                                child: Text(
                                  '${artist.songCount} ${artist.songCount == 1 ? "canción" : "canciones"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _statsTextStyle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    // Spotify circular action play button
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

/// Spotify-styled circular artist card for carousel.
class _ArtistSecondaryCard extends StatelessWidget {
  final ArtistDiscoveryItem artist;
  final VoidCallback? onTap;

  const _ArtistSecondaryCard({
    required this.artist,
    this.onTap,
  });

  static final TextStyle _nameStyle = GoogleFonts.inconsolata(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static final TextStyle _subtitleStyle = GoogleFonts.inconsolata(
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
        borderRadius: BorderRadius.circular(8.0),
        splashColor: const Color(0xFF282828),
        child: SizedBox(
          width: 114.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Native Material 3 circular avatar
              const _MaterialArtistAvatar(size: 96.0),
              const SizedBox(height: 10.0),
              Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _nameStyle,
              ),
              const SizedBox(height: 3.0),
              Text(
                'Artist',
                style: _subtitleStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
