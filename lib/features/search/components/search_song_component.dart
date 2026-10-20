/// File: search_song_component.dart
/// Description: Authentic Spotify-styled modular search component for Songs.
/// Features a prominent Top Result card with Spotify-accurate surface (#181818),
/// square artwork, floating play button, and a clean borderless list of songs (strictly <= 5)
/// with 48x48 album artwork, clear typography hierarchy, and more-options trailing action.
///
/// Components / Classes / Functions:
/// - SearchSongComponent: Main widget presenting song search results.
/// - _SongTopResultCard: Full Spotify-styled Top Result card for a song.
/// - SearchSongTile: Reusable Spotify-styled song row tile.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Spotify-style Song presentation component for search results.
class SearchSongComponent extends StatelessWidget {
  /// The song to display as the prominent Top Result, if any.
  final Song? topResultSong;

  /// Secondary matching songs (strictly limited to at most 5).
  final List<Song> songs;

  /// Callback when a song item or top card is tapped.
  final ValueChanged<Song>? onSongTap;

  /// Whether to render only as the Top Result card.
  final bool isTopResultOnly;

  const SearchSongComponent({
    super.key,
    this.topResultSong,
    this.songs = const [],
    this.onSongTap,
    this.isTopResultOnly = false,
  });

  static final TextStyle _sectionHeaderStyle = GoogleFonts.zenDots(
    fontSize: 13.5,
    letterSpacing: 1.2,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    if (isTopResultOnly && topResultSong != null) {
      return _SongTopResultCard(
        song: topResultSong!,
        onTap: () => onSongTap?.call(topResultSong!),
      );
    }

    if (songs.isEmpty && topResultSong == null) {
      return const SizedBox.shrink();
    }

    // Strict Rule: Constrain to maximum 5 items
    final displaySongs = songs.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topResultSong != null) ...[
          _SongTopResultCard(
            song: topResultSong!,
            onTap: () => onSongTap?.call(topResultSong!),
          ),
          const SizedBox(height: 24.0),
        ],
        if (displaySongs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'SONGS',
              style: _sectionHeaderStyle,
            ),
          ),
          const SizedBox(height: 4.0),
          // Direct Spotify-style borderless song list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: displaySongs.length,
            itemBuilder: (context, index) {
              final song = displaySongs[index];
              return SearchSongTile(
                song: song,
                onTap: () => onSongTap?.call(song),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Full Spotify-styled Top Result card for a Song.
class _SongTopResultCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;

  const _SongTopResultCard({
    required this.song,
    this.onTap,
  });

  static final TextStyle _topResultHeaderStyle = GoogleFonts.zenDots(
    fontSize: 13.5,
    letterSpacing: 1.2,
    color: Colors.white,
  );

  static final TextStyle _songTitleStyle = GoogleFonts.inconsolata(
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

  String _formatDuration(int ms) {
    final int totalSeconds = ms ~/ 1000;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

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
                    // Square Song Cover with subtle shadow
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
                        mediaStoreId: song.mediaStoreId,
                        albumId: song.albumId,
                        width: 84.0,
                        height: 84.0,
                        borderRadius: 6.0,
                        fallbackIcon: Icons.music_note_rounded,
                        isThumbnail: true,
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    // Metadata & Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _songTitleStyle,
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
                                  'SONG',
                                  style: _badgeTextStyle,
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              Flexible(
                                child: Text(
                                  song.artist ?? '<Desconocido>',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _metadataTextStyle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            '${song.album ?? "<Desconocido>"} • ${_formatDuration(song.duration)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

/// Spotify-styled song row tile with borderless surface.
class SearchSongTile extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;

  const SearchSongTile({
    super.key,
    required this.song,
    this.onTap,
  });

  static final TextStyle _titleStyle = GoogleFonts.inconsolata(
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static final TextStyle _artistAlbumStyle = GoogleFonts.inconsolata(
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
  );

  static final TextStyle _durationStyle = GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
  );

  String _formatDuration(int ms) {
    final int totalSeconds = ms ~/ 1000;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF282828),
        highlightColor: const Color(0xFF1E1E1E),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // 48x48 Spotify-style square thumbnail
              AnimaArtworkImage(
                mediaStoreId: song.mediaStoreId,
                albumId: song.albumId,
                width: 48.0,
                height: 48.0,
                borderRadius: 4.0,
                isThumbnail: true,
              ),
              const SizedBox(width: 14.0),
              // Title and Artist/Album
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _titleStyle,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${song.artist ?? '<Desconocido>'} • ${song.album ?? '<Desconocido>'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _artistAlbumStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              // Duration
              Text(
                _formatDuration(song.duration),
                style: _durationStyle,
              ),
              const SizedBox(width: 8.0),
              // Spotify more-options icon
              const Icon(
                Icons.more_vert_rounded,
                size: 20.0,
                color: Color(0xFFB3B3B3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
