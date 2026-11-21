/// File: playlist_text_banner.dart
/// Description: 2:1 widescreen Metro hero banner for playlists in Library, Space,
/// PlaylistDetailScreen, and PlaylistEditScreen.
/// Displays sharp 90-degree cover artwork with a subtle bottom gradient scrim and
/// the playlist name rendered cleanly in the app's standard Segoe UI typography.
///
/// Components / Classes / Functions:
/// - PlaylistTextBanner: Reusable 2:1 aspect ratio Metro playlist banner widget.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/theme/theme.dart';

/// 2:1 AspectRatio Metro playlist banner rendering the cover and clean Segoe UI title.
class PlaylistTextBanner extends StatelessWidget {
  /// Display title of the playlist.
  final String title;

  /// Optional local filesystem path to custom picked image.
  final String? coverPath;

  /// Fallback representative song media store id.
  final int? representativeSongId;

  /// Optional tap callback (e.g. to pick cover in editor, or open playlist).
  final VoidCallback? onTap;

  /// Whether to show the Metro camera action badge at bottom-right (for editor).
  final bool showCameraBadge;

  const PlaylistTextBanner({
    super.key,
    required this.title,
    this.coverPath,
    this.representativeSongId,
    this.onTap,
    this.showCameraBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.trim().isEmpty ? 'Mi Playlist' : title.trim();

    return AspectRatio(
      aspectRatio: 2.0, // Strict 2:1 aspect ratio matching Space
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.zero, // Strict 90-degree Metro corners
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Cover Artwork or Minimalist Metro Fallback
            _buildBackground(context),

            // 2. Subtle Bottom Gradient Scrim for Title Legibility
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 76.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black87,
                      Colors.black38,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 3. Playlist Name in App's Standard Typography (bottom-left)
            Positioned(
              left: 14.0,
              right: showCameraBadge ? 56.0 : 14.0,
              bottom: 12.0,
              child: Text(
                displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.segoe(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
            ),

            // 4. Optional Metro Camera Badge (bottom-right, for editor)
            if (showCameraBadge)
              Positioned(
                right: 10.0,
                bottom: 10.0,
                child: Material(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.92),
                  shape: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.7),
                    width: 1.0,
                  ),
                  child: InkWell(
                    onTap: onTap,
                    child: SizedBox(
                      width: 36.0,
                      height: 36.0,
                      child: Center(
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 18.0,
                          color: AppColors.futuristicWhite,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    if (coverPath != null && File(coverPath!).existsSync()) {
      final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.5;
      final screenW = MediaQuery.maybeSizeOf(context)?.width ?? 400.0;
      final cacheW = (screenW * dpr).round().clamp(400, 1000);
      final cacheH = (cacheW * 0.5).round();

      return Image.file(
        File(coverPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        cacheWidth: cacheW,
        cacheHeight: cacheH,
        filterQuality: FilterQuality.medium,
      );
    }

    if (representativeSongId != null && representativeSongId! > 0) {
      return AnimaArtworkImage(
        mediaStoreId: representativeSongId!,
        width: double.infinity,
        height: double.infinity,
        borderRadius: 0.0,
        fit: BoxFit.cover,
        fallbackIcon: Icons.queue_music_rounded,
        isThumbnail: false,
      );
    }

    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Symbols.queue_music_rounded,
          size: 48.0,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.30),
        ),
      ),
    );
  }
}
