/// File: playlist_cover_picker.dart
/// Description: Interactive cover image picker widget for playlist creation and editing.
/// Displays a stylized generic placeholder or picked custom image with rich shadows,
/// and launches ImagePicker on user interaction.
///
/// Components / Classes / Functions:
/// - PlaylistCoverPicker: Stateful widget managing cover selection.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Cover artwork picker displaying generic placeholder or user-selected photo.
class PlaylistCoverPicker extends StatelessWidget {
  /// Local filesystem path to the currently chosen image, if any.
  final String? coverPath;

  /// Callback when a new cover photo is selected.
  final ValueChanged<String?> onCoverPicked;

  /// Size of the square artwork card. Defaults to 160.0.
  final double size;

  const PlaylistCoverPicker({
    super.key,
    required this.coverPath,
    required this.onCoverPicked,
    this.size = 160.0,
  });

  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      if (file != null) {
        onCoverPicked(file.path);
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistCoverPicker] Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image from gallery'),
            duration: Duration(seconds: 2),
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
              // 1. Artwork Container with Shadow
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.65),
                      blurRadius: 28.0,
                      spreadRadius: 2.0,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: _buildArtworkContent(),
                ),
              ),

              // 2. Camera Badge at Bottom Right
              Positioned(
                right: -6.0,
                bottom: -6.0,
                child: Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: AppColors.navIndicator,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 8.0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.bottomNavBackground,
                      width: 2.0,
                    ),
                  ),
                  child: const Center(
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
        const SizedBox(height: 12.0),

        // 3. Optional "Change photo" action text
        GestureDetector(
          onTap: () => _pickImage(context),
          child: Text(
            coverPath != null ? 'Change photo' : 'Choose cover photo',
            style: _changePhotoStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildArtworkContent() {
    if (coverPath != null && File(coverPath!).existsSync()) {
      return Image.file(
        File(coverPath!),
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    }

    // Generic placeholder
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF282828),
            Color(0xFF161616),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Symbols.queue_music_rounded,
          size: size * 0.42,
          color: AppColors.futuristicWhite.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
