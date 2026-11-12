/// File: artist_photo_options_sheet.dart
/// Description: Material Design 3 Expressive bottom sheet modal providing options
/// to change or remove a personalized artist avatar image.
///
/// Components / Classes / Functions:
/// - ArtistPhotoOptionsSheet: Modal sheet widget for artist photo customization.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
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
      backgroundColor: AppColors.bottomNavBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
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
    return Material(
      color: AppColors.bottomNavBackground,
      shape: Border(
        top: BorderSide(
          color: AppColors.accent,
          width: 2.5,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppColors.onSurface),
                title: Text(
                  context.l10n.artist.changeArtistPhoto,
                  style: AppFonts.segoe(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurface,
                  ),
                ),
                onTap: onChangePhoto,
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: Text(
                  context.l10n.artist.removeCustomPhoto,
                  style: AppFonts.segoe(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: onRemovePhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
