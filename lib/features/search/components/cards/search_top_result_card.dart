/// File: search_top_result_card.dart
/// Description: Spotify-styled unified Top Result card component supporting Songs,
/// Albums, and Artists with consistent surface styling (#181818), typography hierarchy,
/// category badges, and floating play action.
///
/// Components / Classes / Functions:
/// - SearchTopResultCard: Main Top Result card widget with dedicated constructors for each entity type.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/features/search/components/common/material_artist_avatar.dart';
import 'package:project_anima/features/search/components/common/search_play_button.dart';
import 'package:project_anima/features/search/components/common/search_section_header.dart';

/// Spotify-style prominent Top Result card widget.
class SearchTopResultCard extends StatelessWidget {
  /// Leading visual widget (Artwork image or Material avatar).
  final Widget leading;

  /// Primary title (song title, album name, or artist name).
  final String title;

  /// Primary subtitle (e.g. artist name). Null for artist results.
  final String? subtitle;

  /// Optional secondary subtitle line (e.g. song count for albums).
  final String? secondarySubtitle;

  /// Optional song count for pluralized album subtitle.
  final int? songCount;

  /// Tap callback when card is activated.
  final VoidCallback? onTap;

  /// Callback when the floating play button is activated.
  final VoidCallback? onPlayTap;

  /// Whether to render the section header ("TOP RESULT") above the card.
  final bool showHeader;

  /// Optional custom header title. Defaults to localized 'TOP RESULT'.
  final String? headerTitle;

  const SearchTopResultCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.secondarySubtitle,
    this.songCount,
    this.onTap,
    this.onPlayTap,
    this.showHeader = true,
    this.headerTitle,
  });

  /// Factory constructor for a dominant [Song] top result.
  factory SearchTopResultCard.song({
    Key? key,
    required Song song,
    VoidCallback? onTap,
    VoidCallback? onPlayTap,
    bool showHeader = true,
    String? headerTitle,
  }) {
    final artistStr = (song.artist != null &&
            song.artist!.trim().isNotEmpty &&
            song.artist != '<Desconocido>' &&
            song.artist != 'Unknown Artist')
        ? song.artist!.trim()
        : 'Unknown Artist';

    return SearchTopResultCard(
      key: key,
      leading: AnimaArtworkImage(
        mediaStoreId: song.mediaStoreId,
        albumId: song.albumId,
        width: 84.0,
        height: 84.0,
        borderRadius: 6.0,
        fallbackIcon: Icons.music_note_rounded,
        isThumbnail: false,
      ),
      title: song.title,
      subtitle: artistStr,
      secondarySubtitle: null,
      onTap: onTap,
      onPlayTap: onPlayTap,
      showHeader: showHeader,
      headerTitle: headerTitle,
    );
  }

  /// Factory constructor for a dominant [AlbumDiscoveryItem] top result.
  factory SearchTopResultCard.album({
    Key? key,
    required AlbumDiscoveryItem album,
    VoidCallback? onTap,
    VoidCallback? onPlayTap,
    bool showHeader = true,
    String? headerTitle,
  }) {
    final artistStr = album.artist.isEmpty ||
            album.artist == '<Desconocido>' ||
            album.artist == 'Unknown Artist'
        ? 'Unknown Artist'
        : album.artist;

    return SearchTopResultCard(
      key: key,
      leading: AnimaArtworkImage(
        mediaStoreId: album.representativeSongId,
        albumId: album.albumId,
        albumName: album.name,
        artistName: album.artist,
        width: 84.0,
        height: 84.0,
        borderRadius: 6.0,
        fallbackIcon: Icons.album_rounded,
        isThumbnail: false,
      ),
      title: album.name,
      subtitle: artistStr,
      songCount: album.songCount,
      onTap: onTap,
      onPlayTap: onPlayTap,
      showHeader: showHeader,
      headerTitle: headerTitle,
    );
  }

  /// Factory constructor for a dominant [ArtistDiscoveryItem] top result.
  factory SearchTopResultCard.artist({
    Key? key,
    required ArtistDiscoveryItem artist,
    VoidCallback? onTap,
    VoidCallback? onPlayTap,
    bool showHeader = true,
    String? headerTitle,
  }) {
    return SearchTopResultCard(
      key: key,
      leading: MaterialArtistAvatar(
        radius: 42.0,
        artistName: artist.name,
      ),
      title: artist.name,
      subtitle: null,
      secondarySubtitle: null,
      onTap: onTap,
      onPlayTap: onPlayTap,
      showHeader: showHeader,
      headerTitle: headerTitle,
    );
  }

  static final TextStyle _titleStyle = GoogleFonts.inconsolata(
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.2,
  );

  static final TextStyle _subtitleStyle = GoogleFonts.inconsolata(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
  );

  static final TextStyle _secondarySubtitleStyle = GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
  );

  @override
  Widget build(BuildContext context) {
    final effectiveSubtitle = (subtitle == 'Unknown Artist' || subtitle == '<Desconocido>')
        ? context.l10n.common.unknownArtist
        : subtitle;
    final effectiveSecondary = songCount != null
        ? context.l10n.search.songCount(songCount!)
        : secondarySubtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) ...[
          SearchSectionHeader(
            title: headerTitle ?? context.l10n.search.topResultHeader,
          ),
          const SizedBox(height: 6.0),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Material(
              color: const Color(0xFF181818),
              child: InkWell(
                onTap: onTap,
                splashColor: const Color(0xFF282828),
                highlightColor: const Color(0xFF1E1E1E),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // 1. Artwork / Avatar
                      leading,
                      const SizedBox(width: 20.0),

                      // 2. Metadata (No badges!)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _titleStyle,
                            ),
                            if (effectiveSubtitle != null &&
                                effectiveSubtitle.trim().isNotEmpty) ...[
                              const SizedBox(height: 4.0),
                              Text(
                                effectiveSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _subtitleStyle,
                              ),
                            ],
                            if (effectiveSecondary != null &&
                                effectiveSecondary.trim().isNotEmpty) ...[
                              const SizedBox(height: 3.0),
                              Text(
                                effectiveSecondary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _secondarySubtitleStyle,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 14.0),

                      // 3. Floating Play Button
                      SearchPlayButton(
                        onTap: onPlayTap,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
