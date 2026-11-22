/// File: settings_screen.dart
/// Description: Windows Phone Metro Settings screen providing real-time Theme switching
/// (Dark / Light), Language selection (System / Spanish / English), Quick Library Rescan,
/// and User Data Reset — restarting only the UI tree (preserving active music playback)
/// when heavy library/data changes occur.
///
/// Components / Classes / Functions:
/// - SettingsScreen: Main Metro Settings coordinator screen.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/app_metadata_dao.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/localization/app_locale.dart';
import 'package:project_anima/core/localization/localization_controller.dart';
import 'package:project_anima/core/navigation/app_route_tracker.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/scanner/models/indexing_result.dart';
import 'package:project_anima/core/scanner/music_indexer.dart';
import 'package:project_anima/core/search/recent_search_controller.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/settings/components/user_data_options_sheet.dart';
import 'package:project_anima/features/settings/services/user_data_backup_service.dart';
import 'package:project_anima/main.dart';

/// Windows Phone Metro Settings screen.
class SettingsScreen extends StatefulWidget {
  /// Optional AppDatabase override for dependency injection in tests.
  final AppDatabase? appDatabase;

  /// Optional custom rescan callback for testing.
  final Future<IndexingResult> Function()? onQuickRescan;

  /// Optional custom reset user data callback for testing.
  final Future<void> Function()? onResetUserData;

  /// Optional custom export user data callback for testing.
  final Future<bool> Function(String jsonContent)? onExportUserData;

  /// Optional custom import user data callback for testing.
  final Future<String?> Function()? onImportUserData;

  /// Optional callback invoked instead of AnimaApp.restart in isolated tests.
  final VoidCallback? onUiRestartRequested;

  const SettingsScreen({
    super.key,
    this.appDatabase,
    this.onQuickRescan,
    this.onResetUserData,
    this.onExportUserData,
    this.onImportUserData,
    this.onUiRestartRequested,
  });

  /// Clears user-generated SQLite tables while preserving the scanned audio library.
  static Future<void> resetUserData({AppDatabase? appDatabase}) async {
    final db = await (appDatabase ?? AppDatabase.instance).database;
    await db.transaction((txn) async {
      await txn.delete('playback_history');
      await txn.delete('recent_searches');
      await txn.delete('playlist_songs');
      await txn.delete('playlists');
      await txn.delete('pinned_favorites');
      await txn.delete('favorite_songs');
      await txn.delete(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [AppMetadataDao.totalListeningTimeMsKey],
      );
    });

    PlaybackController.instance.resetListeningTime();
    await FavoriteSongsDao.instance.ensureLoaded();
    await RecentSearchController.instance.init();
    SongDao.notifyPlaybackHistoryChanged();
  }

  /// Slide route to present SettingsScreen.
  static Route<void> route() {
    return PageRouteBuilder<void>(
      settings: const RouteSettings(name: AppRouteTracker.settingsRouteName),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SettingsScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isScanning = false;
  bool _isResetting = false;
  bool _isManagingData = false;
  bool _trimSilenceEnabled = AppMetadataDao.instance.isTrimSilenceEnabledSync;

  @override
  void initState() {
    super.initState();
    _loadTrimSilencePref();
  }

  Future<void> _loadTrimSilencePref() async {
    final enabled = await AppMetadataDao.instance.getTrimSilenceEnabled(
      appDatabase: widget.appDatabase,
    );
    if (mounted && enabled != _trimSilenceEnabled) {
      setState(() => _trimSilenceEnabled = enabled);
    }
  }

  Future<void> _toggleTrimSilence() async {
    final next = !_trimSilenceEnabled;
    setState(() => _trimSilenceEnabled = next);
    await AppMetadataDao.instance.setTrimSilenceEnabled(
      next,
      appDatabase: widget.appDatabase,
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppFonts.segoe(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
      ),
    );
  }

  Future<void> _handleExportUserData() async {
    if (_isScanning || _isResetting || _isManagingData) return;
    setState(() => _isManagingData = true);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    try {
      final json = await UserDataBackupService.exportToJson(
        appDatabase: widget.appDatabase,
      );
      final saved = widget.onExportUserData != null
          ? await widget.onExportUserData!(json)
          : await UserDataBackupService.exportWithSystemPicker(json);
      if (!mounted) return;
      setState(() => _isManagingData = false);
      if (saved) {
        _showSnackBar(
          isSpanish
              ? 'Datos exportados correctamente'
              : 'User data exported successfully',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [SettingsScreen] Error exporting user data: $e');
      if (mounted) {
        setState(() => _isManagingData = false);
        _showSnackBar(
          isSpanish
              ? 'No se pudieron exportar los datos'
              : 'Could not export user data',
        );
      }
    }
  }

  Future<void> _handleImportUserData() async {
    if (_isScanning || _isResetting || _isManagingData) return;
    setState(() => _isManagingData = true);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    try {
      final json = widget.onImportUserData != null
          ? await widget.onImportUserData!()
          : await UserDataBackupService.importWithSystemPicker();
      if (json == null || json.trim().isEmpty) {
        if (mounted) setState(() => _isManagingData = false);
        return;
      }
      final result = await UserDataBackupService.importFromJson(
        json,
        appDatabase: widget.appDatabase,
      );
      if (!mounted) return;
      setState(() => _isManagingData = false);
      _showSnackBar(
        isSpanish
            ? 'Importados: ${result.restoredPlays} reprod., ${result.restoredSpacePins} Space'
            : 'Imported: ${result.restoredPlays} plays, ${result.restoredSpacePins} Space',
      );
      if (result.totalRestored > 0) {
        _triggerUiRestart();
      }
    } catch (e) {
      debugPrint('⚠️ [SettingsScreen] Error importing user data: $e');
      if (mounted) {
        setState(() => _isManagingData = false);
        _showSnackBar(
          isSpanish
              ? 'Archivo de respaldo inválido'
              : 'Invalid backup file',
        );
      }
    }
  }

  void _openUserDataSheet() {
    if (_isScanning || _isResetting || _isManagingData) return;
    UserDataOptionsSheet.show(
      context,
      onImportData: _handleImportUserData,
      onExportData: _handleExportUserData,
      onClearData: _handleResetUserData,
    );
  }

  void _triggerUiRestart() {
    if (widget.onUiRestartRequested != null) {
      widget.onUiRestartRequested!();
    } else if (mounted) {
      AnimaApp.restart(context);
    }
  }

  Future<void> _handleQuickRescan() async {
    if (_isScanning || _isResetting) return;
    setState(() => _isScanning = true);

    try {
      final result = widget.onQuickRescan != null
          ? await widget.onQuickRescan!()
          : await MusicIndexer.instance.syncWithDevice();

      if (widget.onQuickRescan == null) {
        unawaited(MusicIndexer.instance.analyzeMissingBpms());
      }

      if (!mounted) return;
      setState(() => _isScanning = false);

      if (result.addedCount > 0 || result.updatedCount > 0 || result.deletedCount > 0) {
        _triggerUiRestart();
      } else {
        final isSpanish = Localizations.localeOf(context).languageCode == 'es';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSpanish
                  ? 'Biblioteca actualizada (${result.totalSongs} canciones)'
                  : 'Library up to date (${result.totalSongs} tracks)',
              style: AppFonts.segoe(color: AppColors.onSurface),
            ),
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _handleResetUserData() async {
    if (_isScanning || _isResetting) return;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.65),
            width: 1.5,
          ),
        ),
        title: Text(
          isSpanish ? 'Restaurar datos de usuario' : 'Reset user data',
          style: AppFonts.light(
            fontSize: 20.0,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          isSpanish
              ? 'Se borrarán tu historial de reproducción, favoritos, playlists y búsquedas recientes. Tus archivos de música no se eliminarán.'
              : 'Your playback history, favorites, playlists, and recent searches will be cleared. Your audio files will not be deleted.',
          style: AppFonts.segoe(
            fontSize: 14.0,
            fontWeight: FontWeight.w300,
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text(
              isSpanish ? 'CANCELAR' : 'CANCEL',
              style: AppFonts.segoe(
                fontSize: 14.0,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('confirm_reset_user_data_button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text(
              isSpanish ? 'RESTAURAR' : 'RESET',
              style: AppFonts.segoe(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isResetting = true);
    try {
      if (widget.onResetUserData != null) {
        await widget.onResetUserData!();
      } else {
        await SettingsScreen.resetUserData(appDatabase: widget.appDatabase);
      }

      if (!mounted) return;
      setState(() => _isResetting = false);
      _triggerUiRestart();
    } catch (e) {
      debugPrint('⚠️ [SettingsScreen] Error resetting user data: $e');
      if (mounted) {
        setState(() => _isResetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = ThemeController.instance;
    final locCtrl = LocalizationController.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([themeCtrl, locCtrl]),
      builder: (context, _) {
        final isSpanish = locCtrl.currentLocale.languageCode == 'es';
        final isDark = themeCtrl.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.bottomNavBackground,
          body: Stack(
            children: [
              const AmbientParticlesCanvas(),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Metro Header with Back Button
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12.0,
                        right: 20.0,
                        top: 10.0,
                        bottom: 10.0,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            key: const ValueKey('settings_back_button'),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.onBackground,
                              size: 26.0,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              isSpanish ? 'Ajustes' : 'Settings',
                              style: AppFonts.segoe(
                                fontSize: 40.0,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.5,
                                color: AppColors.onBackground,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Metro Settings List
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 18.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Section: Theme
                            _buildSectionHeader(
                              isSpanish ? 'TEMA' : 'THEME',
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildOptionTile(
                                    key: const ValueKey('settings_theme_dark'),
                                    label: isSpanish ? 'Oscuro' : 'Dark',
                                    icon: Icons.dark_mode_outlined,
                                    isSelected: isDark,
                                    onTap: () {
                                      if (!themeCtrl.isDarkMode) {
                                        themeCtrl.setDarkMode(true);
                                        _triggerUiRestart();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: _buildOptionTile(
                                    key: const ValueKey('settings_theme_light'),
                                    label: isSpanish ? 'Claro' : 'Light',
                                    icon: Icons.light_mode_outlined,
                                    isSelected: !isDark,
                                    onTap: () {
                                      if (themeCtrl.isDarkMode) {
                                        themeCtrl.setDarkMode(false);
                                        _triggerUiRestart();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),

                            // Section: Language
                            _buildSectionHeader(
                              isSpanish ? 'IDIOMA' : 'LANGUAGE',
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildOptionTile(
                                    key: const ValueKey('settings_lang_es'),
                                    label: 'Español',
                                    isSelected:
                                        locCtrl.currentAppLocale == AppLocale.es,
                                    onTap: () => locCtrl.setLocale(AppLocale.es),
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: _buildOptionTile(
                                    key: const ValueKey('settings_lang_en'),
                                    label: 'English',
                                    isSelected:
                                        locCtrl.currentAppLocale == AppLocale.en,
                                    onTap: () => locCtrl.setLocale(AppLocale.en),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),

                            // Section: Library
                            _buildSectionHeader(
                              isSpanish ? 'BIBLIOTECA' : 'LIBRARY',
                            ),
                            const SizedBox(height: 10.0),
                            _buildActionTile(
                              key: const ValueKey('settings_quick_rescan'),
                              icon: Icons.refresh_rounded,
                              title: isSpanish
                                  ? 'Reescaneo rápido'
                                  : 'Quick rescan',
                              subtitle: isSpanish
                                  ? 'Busca nuevas canciones y analiza BPM sin detener la música'
                                  : 'Scan new tracks and analyze BPM without stopping playback',
                              isLoading: _isScanning,
                              onTap: _handleQuickRescan,
                            ),
                            const SizedBox(height: 10.0),
                            _buildMetroToggleTile(
                              key: const ValueKey('settings_trim_silence_toggle'),
                              title: isSpanish
                                  ? 'Recortar silencio inicial'
                                  : 'Trim leading silence',
                              subtitle: isSpanish
                                  ? 'Salta el silencio al inicio en MP3, FLAC y más'
                                  : 'Skip leading dead air in MP3, FLAC, and more',
                              value: _trimSilenceEnabled,
                              isSpanish: isSpanish,
                              onTap: _toggleTrimSilence,
                            ),
                            const SizedBox(height: 24.0),

                            // Section: User Data
                            _buildSectionHeader(
                              isSpanish ? 'DATOS DE USUARIO' : 'USER DATA',
                            ),
                            const SizedBox(height: 10.0),
                            _buildActionTile(
                              key: const ValueKey('settings_manage_user_data'),
                              icon: Icons.storage_rounded,
                              title: isSpanish
                                  ? 'Gestionar datos'
                                  : 'Manage data',
                              subtitle: isSpanish
                                  ? 'Importar, exportar o borrar estadísticas y Space'
                                  : 'Import, export, or clear stats and Space',
                              isLoading: _isResetting || _isManagingData,
                              onTap: _openUserDataSheet,
                            ),
                            const SizedBox(height: 40.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppFonts.segoe(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildOptionTile({
    Key? key,
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.16)
              : AppColors.surfaceContainer.withValues(alpha: 0.85),
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : AppColors.outline.withValues(alpha: 0.30),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.zero,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.zero,
            splashColor: AppColors.accent.withValues(alpha: 0.15),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18.0,
                      color: isSelected ? AppColors.accent : AppColors.onSurface,
                    ),
                    const SizedBox(width: 8.0),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.segoe(
                        fontSize: 14.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.accent : AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetroToggleTile({
    Key? key,
    required String title,
    required String subtitle,
    required bool value,
    required bool isSpanish,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.zero,
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.zero,
          splashColor: AppColors.accent.withValues(alpha: 0.15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppFonts.segoe(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle,
                        style: AppFonts.segoe(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w300,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14.0),
                // Authentic Windows Phone Metro rectangular ToggleSwitch
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value
                          ? (isSpanish ? 'Activado' : 'On')
                          : (isSpanish ? 'Desactivado' : 'Off'),
                      style: AppFonts.segoe(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: value ? AppColors.accent : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Container(
                      width: 52.0,
                      height: 24.0,
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        color: value
                            ? AppColors.accent.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: value
                              ? AppColors.accent
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.75),
                          width: 1.5,
                        ),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOutCubic,
                        alignment:
                            value ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 14.0,
                          height: 14.0,
                          decoration: BoxDecoration(
                            color: value
                                ? AppColors.accent
                                : AppColors.onSurface,
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    final accentColor = isDestructive ? Colors.redAccent : AppColors.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.zero,
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.zero,
          splashColor: AppColors.accent.withValues(alpha: 0.15),
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                if (isLoading)
                  SizedBox(
                    width: 22.0,
                    height: 22.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: AppColors.accent,
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 22.0,
                    color: accentColor,
                  ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppFonts.segoe(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w400,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle,
                        style: AppFonts.segoe(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w300,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
