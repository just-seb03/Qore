/// File: playlist_discard_dialog.dart
/// Description: Material 3 Expressive confirmation dialog presented when the user
/// attempts to dismiss the playlist editor with unsaved changes.
///
/// Components / Classes / Functions:
/// - PlaylistDiscardDialog: Confirmation dialog widget.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Confirmation dialog checking whether user wants to discard unsaved playlist changes.
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

  static TextStyle get _titleStyle => GoogleFonts.inconsolata(
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.onSurface,
  );

  static TextStyle get _contentStyle => GoogleFonts.inconsolata(
    fontSize: 14.0,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );

  static final TextStyle _actionStyle = GoogleFonts.inconsolata(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.playlist;

    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(
          color: AppColors.outline.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      actionsPadding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFFB74D),
            size: 24.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              l10n.discardDialogTitle,
              style: _titleStyle,
            ),
          ),
        ],
      ),
      content: Text(
        l10n.discardDialogMessage,
        style: _contentStyle,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onSurfaceVariant,
          ),
          child: Text(l10n.keepEditingAction, style: _actionStyle),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: Text(l10n.discardAction, style: _actionStyle),
        ),
      ],
    );
  }
}
