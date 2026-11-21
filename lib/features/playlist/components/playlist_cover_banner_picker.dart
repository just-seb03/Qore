/// File: playlist_cover_banner_picker.dart
/// Description: Photo-only 2:1 Metro cover picker for playlist creation and editing.
/// Tapping anywhere on the banner selects a photo from the gallery; when a custom
/// photo is active, a compact top-right Metro clear button allows removing it without
/// extra action rows below the banner.
///
/// Components / Classes / Functions:
/// - PlaylistCoverBannerPicker: Stateless photo-only 2:1 cover picker widget.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/features/playlist/components/playlist_text_banner.dart';

/// Photo-only 2:1 Metro cover picker without text overlay or bottom action buttons.
class PlaylistCoverBannerPicker extends StatelessWidget {
  final String? coverPath;
  final int? representativeSongId;
  final VoidCallback onPickCover;
  final VoidCallback? onClearCover;

  const PlaylistCoverBannerPicker({
    super.key,
    required this.coverPath,
    this.representativeSongId,
    required this.onPickCover,
    this.onClearCover,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onPickCover,
          child: PlaylistTextBanner(
            title: '',
            coverPath: coverPath,
            representativeSongId: representativeSongId,
            showTitle: false,
            showCameraBadge: true,
            onTap: onPickCover,
          ),
        ),
        if (coverPath != null && onClearCover != null)
          Positioned(
            top: 8.0,
            right: 8.0,
            child: Material(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.zero,
              child: InkWell(
                key: const ValueKey('playlist_clear_cover_button'),
                onTap: onClearCover,
                child: Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16.0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
