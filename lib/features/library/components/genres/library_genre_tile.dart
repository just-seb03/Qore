/// File: library_genre_tile.dart
/// Description: Individual genre row widget for the Library genres list.
/// Renders sharp 90-degree Metro square artwork/icon, genre name, and song count.
///
/// Components / Classes / Functions:
/// - LibraryGenreTile: Stateless list tile rendering genre summary.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/database/models/genre_discovery_item.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Row tile presenting a genre in the Library genres list.
class LibraryGenreTile extends StatelessWidget {
  /// Strict fixed tile height matching virtualized ListView itemExtent.
  static const double tileHeight = 68.0;

  /// Aggregated genre data.
  final GenreDiscoveryItem genre;

  /// Callback when this genre is tapped.
  final VoidCallback? onTap;

  const LibraryGenreTile({
    super.key,
    required this.genre,
    this.onTap,
  });

  static TextStyle get _nameStyle => AppFonts.segoe(
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        letterSpacing: 0.1,
      );

  static TextStyle get _subtitleStyle => AppFonts.segoe(
        fontSize: 12.5,
        fontWeight: FontWeight.w300,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 0.1,
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: tileHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
          highlightColor:
              AppColors.surfaceContainerHighest.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // 1. Sharp 90-degree square Metro genre icon (no photo)
                Container(
                  width: 50.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    border: Border.all(
                      color: AppColors.outlineVariant,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    size: 24.0,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16.0),

                // 2. Genre Name and Song Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        genre.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _nameStyle,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        context.l10n.library.songCount(genre.songCount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _subtitleStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
