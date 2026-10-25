/// File: playlist_cover_picker.dart
/// Description: Interactive hero banner image picker widget for playlist creation and editing.
/// Displays a stylized 1920x620 hero banner placeholder or custom picked image with rich shadows,
/// launching ImagePicker on user interaction.
///
/// Components / Classes / Functions:
/// - PlaylistCoverPicker: Stateless widget managing playlist hero banner selection.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Hero banner picker displaying a 1920x620 placeholder or user-selected photo.
class PlaylistCoverPicker extends StatelessWidget {
  /// Local filesystem path to the currently chosen image, if any.
  final String? coverPath;

  /// Callback when a new cover photo is selected.
  final ValueChanged<String?> onCoverPicked;

  /// Optional width constraint (defaults to double.infinity).
  final double? width;

  const PlaylistCoverPicker({
    super.key,
    required this.coverPath,
    required this.onCoverPicked,
    this.width,
  });

  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 98,
        maxWidth: 2560,
        maxHeight: 1440,
      );
      if (file != null) {
        onCoverPicked(file.path);
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistCoverPicker] Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.playlist.galleryPickError),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  static final TextStyle _changePhotoStyle = GoogleFonts.inconsolata(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    color: AppColors.futuristicWhite,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _pickImage(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Hero Artwork Container with 1920x620 Aspect Ratio
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 125.0),
                child: AspectRatio(
                  aspectRatio: 1920 / 620,
                  child: Container(
                  width: width ?? double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 24.0,
                        spreadRadius: 2.0,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8.0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.outline.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                  child: ClipRect(
                    child: _buildArtworkContent(context),
                  ),
                ),
              ),
              ),

              // 2. Camera Badge at Bottom Right
              Positioned(
                right: 8.0,
                bottom: 8.0,
                child: Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: AppColors.navIndicator,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 8.0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.bottomNavBackground,
                      width: 2.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 19.0,
                      color: AppColors.futuristicWhite,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10.0),

        // 3. "Change photo" action text
        GestureDetector(
          onTap: () => _pickImage(context),
          child: Text(
            coverPath != null
                ? context.l10n.playlist.changeCover
                : context.l10n.playlist.addCover,
            style: _changePhotoStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildArtworkContent(BuildContext context) {
    if (coverPath != null && File(coverPath!).existsSync()) {
      return Image.file(
        File(coverPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.high,
      );
    }

    // Generic placeholder banner
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF242436),
            Color(0xFF161622),
            Color(0xFF101018),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.queue_music_rounded,
              size: 44.0,
              color: AppColors.futuristicWhite.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 6.0),
            Text(
              context.l10n.playlist.heroBannerPlaceholder,
              style: GoogleFonts.inconsolata(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: AppColors.futuristicWhite.withValues(alpha: 0.40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
