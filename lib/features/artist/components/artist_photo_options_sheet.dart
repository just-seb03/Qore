/// File: artist_photo_options_sheet.dart
/// Description: Material Design 3 Expressive bottom sheet modal providing options
/// to change or remove a personalized artist avatar image.
///
/// Components / Classes / Functions:
/// - ArtistPhotoOptionsSheet: Modal sheet widget for artist photo customization.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Modal bottom sheet widget presenting photo customization options.
class ArtistPhotoOptionsSheet extends StatelessWidget {
  /// Callback invoked when the user selects the change photo option.
  final VoidCallback onChangePhoto;

  /// Callback invoked when the user selects the remove photo option.
  final VoidCallback onRemovePhoto;

  const ArtistPhotoOptionsSheet({
    super.key,
    required this.onChangePhoto,
    required this.onRemovePhoto,
  });

  /// Static helper to display the options sheet.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onChangePhoto,
    required VoidCallback onRemovePhoto,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (sheetContext) {
        return ArtistPhotoOptionsSheet(
          onChangePhoto: () {
            Navigator.of(sheetContext).pop();
            onChangePhoto();
          },
          onRemovePhoto: () {
            Navigator.of(sheetContext).pop();
            onRemovePhoto();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.0,
              height: 4.0,
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
              title: Text(
                'Change artist photo',
                style: GoogleFonts.outfit(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              onTap: onChangePhoto,
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text(
                'Remove custom photo',
                style: GoogleFonts.outfit(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.redAccent,
                ),
              ),
              onTap: onRemovePhoto,
            ),
          ],
        ),
      ),
    );
  }
}
