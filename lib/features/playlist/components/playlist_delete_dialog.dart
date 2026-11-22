/// File: playlist_delete_dialog.dart
/// Description: Material 3 Expressive confirmation dialog presented when the user
/// long-presses a playlist card in the Library, prompting confirmation for permanent deletion.
///
/// Components / Classes / Functions:
/// - PlaylistDeleteDialog: Confirmation dialog widget for playlist deletion.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Confirmation dialog checking whether user wants to delete a playlist.
class PlaylistDeleteDialog extends StatelessWidget {
  final String playlistName;

  const PlaylistDeleteDialog({
    super.key,
    required this.playlistName,
  });

  /// Displays the dialog and returns true if user confirmed deletion.
  static Future<bool> show(BuildContext context, {required String playlistName}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => PlaylistDeleteDialog(playlistName: playlistName),
    );
    return result ?? false;
  }

  static TextStyle get _titleStyle => AppFonts.segoe(
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.onSurface,
  );

  static TextStyle get _contentStyle => AppFonts.segoe(
    fontSize: 14.0,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );

  static final TextStyle _actionStyle = AppFonts.segoe(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
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
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
            size: 24.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              isSpanish ? 'Eliminar playlist' : 'Delete playlist',
              style: _titleStyle,
            ),
          ),
        ],
      ),
      content: Text(
        isSpanish
            ? '¿Estás seguro de que quieres eliminar "$playlistName"? Esta acción no se puede deshacer.'
            : 'Are you sure you want to delete "$playlistName"? This action cannot be undone.',
        style: _contentStyle,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            isSpanish ? 'CANCELAR' : 'CANCEL',
            style: _actionStyle.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        TextButton(
          key: const ValueKey('confirm_delete_playlist_button'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            isSpanish ? 'ELIMINAR' : 'DELETE',
            style: _actionStyle.copyWith(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
