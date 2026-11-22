/// File: song_delete_dialog.dart
/// Description: Confirmation dialog displayed before permanently deleting a song
/// from the library and database.
///
/// Components / Classes / Functions:
/// - SongDeleteDialog: Modal dialog confirming song deletion.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Modal dialog confirming track deletion from the user library.
class SongDeleteDialog extends StatelessWidget {
  final String songTitle;

  const SongDeleteDialog({
    super.key,
    required this.songTitle,
  });

  /// Displays the dialog and returns true if user confirmed deletion.
  static Future<bool> show(BuildContext context, {required String songTitle}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => SongDeleteDialog(songTitle: songTitle),
    );
    return result ?? false;
  }

  static TextStyle get _titleStyle => AppFonts.light(
    fontSize: 20.0,
    letterSpacing: 0.5,
    color: AppColors.onSurface,
  );

  static TextStyle get _contentStyle => AppFonts.segoe(
    fontSize: 14.0,
    fontWeight: FontWeight.w300,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );

  static final TextStyle _actionStyle = AppFonts.segoe(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
  );

  @override
  Widget build(BuildContext context) {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(
          color: AppColors.accent.withValues(alpha: 0.65),
          width: 1.5,
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
              isSpanish ? 'Eliminar canción' : 'Delete track',
              style: _titleStyle,
            ),
          ),
        ],
      ),
      content: Text(
        isSpanish
            ? '¿Estás seguro de que quieres eliminar "$songTitle"? Esta acción la quitará de tu biblioteca.'
            : 'Are you sure you want to delete "$songTitle"? This will remove it from your library.',
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
          key: const ValueKey('confirm_delete_song_button'),
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
