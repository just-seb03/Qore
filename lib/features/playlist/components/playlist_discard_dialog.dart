/// File: playlist_discard_dialog.dart
/// Description: Windows Phone Metro confirmation dialog presented when the user
/// attempts to dismiss the playlist editor with unsaved changes, matching the
/// Space unpin confirmation dialog style.
///
/// Components / Classes / Functions:
/// - PlaylistDiscardDialog: Metro confirmation dialog widget.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Metro confirmation dialog checking whether user wants to discard unsaved playlist changes.
class PlaylistDiscardDialog extends StatelessWidget {
  const PlaylistDiscardDialog({super.key});

  /// Displays the dialog and returns true if user confirmed discarding changes.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => const PlaylistDiscardDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.playlist;

    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Text(
        l10n.discardDialogTitle,
        style: AppFonts.segoe(
          fontWeight: FontWeight.bold,
          color: AppColors.onSurface,
        ),
      ),
      content: Text(
        l10n.discardDialogMessage,
        style: AppFonts.segoe(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.keepEditingAction.toUpperCase(),
            style: AppFonts.segoe(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.discardAction.toUpperCase(),
            style: AppFonts.segoe(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
