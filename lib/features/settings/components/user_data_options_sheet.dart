/// File: user_data_options_sheet.dart
/// Description: Windows Phone Metro bottom sheet modal providing options to
/// import, export, or clear user statistics and Space data.
///
/// Components / Classes / Functions:
/// - UserDataOptionsSheet: Metro modal sheet widget for user data management.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Metro modal bottom sheet widget presenting user data management options.
class UserDataOptionsSheet extends StatelessWidget {
  final VoidCallback onImportData;
  final VoidCallback onExportData;
  final VoidCallback onClearData;

  const UserDataOptionsSheet({
    super.key,
    required this.onImportData,
    required this.onExportData,
    required this.onClearData,
  });

  /// Displays the Metro user data management sheet.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onImportData,
    required VoidCallback onExportData,
    required VoidCallback onClearData,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (sheetContext) {
        return UserDataOptionsSheet(
          onImportData: () {
            Navigator.of(sheetContext).pop();
            onImportData();
          },
          onExportData: () {
            Navigator.of(sheetContext).pop();
            onExportData();
          },
          onClearData: () {
            Navigator.of(sheetContext).pop();
            onClearData();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

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
              _MetroDataSheetOption(
                key: const ValueKey('user_data_import_option'),
                icon: Icons.file_download_outlined,
                label: isSpanish
                    ? 'Importar datos de usuario'
                    : 'Import user data',
                onTap: onImportData,
              ),
              _MetroDataSheetOption(
                key: const ValueKey('user_data_export_option'),
                icon: Icons.file_upload_outlined,
                label: isSpanish
                    ? 'Exportar datos de usuario'
                    : 'Export user data',
                onTap: onExportData,
              ),
              _MetroDataSheetOption(
                key: const ValueKey('user_data_clear_option'),
                icon: Icons.delete_outline_rounded,
                label: isSpanish
                    ? 'Borrar datos de usuario'
                    : 'Clear user data',
                isDestructive: true,
                onTap: onClearData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetroDataSheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MetroDataSheetOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : AppColors.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: Row(
          children: [
            Icon(icon, size: 22.0, color: color),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                label,
                style: AppFonts.segoe(
                  fontSize: 16.0,
                  fontWeight: isDestructive ? FontWeight.w500 : FontWeight.w400,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

