/// File: artist_photo_options_sheet.dart
/// Description: Windows Phone Metro bottom sheet modal providing clean options
/// to change or remove a personalized artist square photo without red highlights or top divider lines.
///
/// Components / Classes / Functions:
/// - ArtistPhotoOptionsSheet: Metro modal sheet widget for artist photo customization.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Metro modal bottom sheet widget presenting photo customization options.
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
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.zero,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MetroSheetOption(
                icon: Icons.photo_library_outlined,
                label: context.l10n.artist.changeArtistPhoto,
                onTap: onChangePhoto,
              ),
              _MetroSheetOption(
                icon: Icons.delete_outline_rounded,
                label: context.l10n.artist.removeCustomPhoto,
                onTap: onRemovePhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetroSheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MetroSheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: Row(
          children: [
            Icon(icon, size: 22.0, color: AppColors.onSurface),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                label,
                style: AppFonts.segoe(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
