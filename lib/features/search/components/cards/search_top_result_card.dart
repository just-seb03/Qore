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
import 'package:project_anima/features/search/components/common/material_artist_avatar.dart';
import 'package:project_anima/features/search/components/common/search_badge.dart';
import 'package:project_anima/features/search/components/common/search_play_button.dart';
import 'package:project_anima/features/search/components/common/search_section_header.dart';

/// Spotify-style prominent Top Result card widget.
class SearchTopResultCard extends StatelessWidget {
  /// Leading visual widget (Artwork image or Material avatar).
  final Widget leading;

  /// Primary title (song title, album name, or artist name).
  final String title;

  /// Badge text (e.g. 'SONG', 'ALBUM', 'ARTIST').
  final String badgeLabel;

  /// Primary subtitle next to badge (e.g. artist name).
  final String subtitle;

  /// Optional secondary subtitle line (e.g. 'Album • 3:45' or '12 canciones').
  final String? secondarySubtitle;

  /// Tap callback when card is activated.
  final VoidCallback? onTap;

  /// Whether to render the section header ("TOP RESULT") above the card.
  final bool showHeader;

  const SearchTopResultCard({
    super.key,
    required this.leading,
    required this.title,
    required this.badgeLabel,
    required this.subtitle,
    this.secondarySubtitle,
    this.onTap,
    this.showHeader = true,
  });

  /// Factory constructor for a dominant [Song] top result.
  factory SearchTopResultCard.song({
    Key? key,
    required Song song,
    VoidCallback? onTap,
    bool showHeader = true,
  }) {
    final int totalSeconds = song.duration ~/ 1000;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final durationStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

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
      badgeLabel: 'SONG',
      subtitle: song.artist ?? '<Desconocido>',
      secondarySubtitle: '${song.album ?? "<Desconocido>"} • $durationStr',
      onTap: onTap,
      showHeader: showHeader,
    );
  }

  /// Factory constructor for a dominant [AlbumDiscoveryItem] top result.
  factory SearchTopResultCard.album({
    Key? key,
    required AlbumDiscoveryItem album,
    VoidCallback? onTap,
    bool showHeader = true,
  }) {
    final songCountStr =
        '${album.songCount} ${album.songCount == 1 ? "canción" : "canciones"}';

    return SearchTopResultCard(
      key: key,
      leading: AnimaArtworkImage(
        mediaStoreId: album.representativeSongId,
        albumId: album.albumId,
        width: 84.0,
        height: 84.0,
        borderRadius: 6.0,
        fallbackIcon: Icons.album_rounded,
        isThumbnail: false,
      ),
      title: album.name,
      badgeLabel: 'ALBUM',
      subtitle: album.artist,
      secondarySubtitle: songCountStr,
      onTap: onTap,
      showHeader: showHeader,
    );
  }

  /// Factory constructor for a dominant [ArtistDiscoveryItem] top result.
  factory SearchTopResultCard.artist({
    Key? key,
    required ArtistDiscoveryItem artist,
    VoidCallback? onTap,
    bool showHeader = true,
  }) {
    return SearchTopResultCard(
      key: key,
      leading: const MaterialArtistAvatar(
        radius: 42.0,
      ),
      title: artist.name,
      badgeLabel: 'ARTIST',
      subtitle: 'Artista',
      secondarySubtitle: null,
      onTap: onTap,
      showHeader: showHeader,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) ...[
          const SearchSectionHeader(title: 'TOP RESULT'),
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

                      // 2. Metadata & Badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _titleStyle,
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                SearchBadge(label: badgeLabel),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _subtitleStyle,
                                  ),
                                ),
                              ],
                            ),
                            if (secondarySubtitle != null) ...[
                              const SizedBox(height: 6.0),
                              Text(
                                secondarySubtitle!,
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
                      const SearchPlayButton(),
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
