/// File: playlist_edit_screen.dart
/// Description: Dedicated full-screen modal coordinator for creating and editing playlists.
/// Features a Space-style 2:1 hero banner photo box with interactive draggable text, real-time
/// parallel name input, 2-per-row Google Fonts typography selector (8 curated fonts), solid and
/// dual-color gradient text color pickers, discard confirmation dialog, and floating Save action.
/// Song addition fields have been removed to give optimal breathing room for typography and design.
///
/// Components / Classes / Functions:
/// - PlaylistEditScreen: Full-screen playlist editor widget.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/search/fuzzy_search_engine.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/playlist/components/playlist_color_picker_dialog.dart';
import 'package:project_anima/features/playlist/components/playlist_discard_dialog.dart';
import 'package:project_anima/features/playlist/components/playlist_text_banner.dart';
import 'package:project_anima/features/playlist/utils/playlist_effect_helper.dart';
import 'package:project_anima/features/playlist/utils/playlist_font_helper.dart';

const int _kDefaultGradientColor2 = 0xFFFF007A; // Default gradient end color

/// Screen widget for creating or editing user playlists.
class PlaylistEditScreen extends StatefulWidget {
  /// Existing playlist to edit, or null when creating a new playlist.
  final Playlist? initialPlaylist;

  /// Optional initial songs when editing.
  final List<Song>? initialSongs;

  /// Optional PlaylistDao for dependency injection.
  final PlaylistDao? playlistDao;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional FuzzySearchEngine for dependency injection.
  final FuzzySearchEngine? fuzzySearchEngine;

  /// Whether to run continuous floating bounce animation on top dismiss arrow (defaults to true).
  final bool animateBounce;

  const PlaylistEditScreen({
    super.key,
    this.initialPlaylist,
    this.initialSongs,
    this.playlistDao,
    this.songDao,
    this.fuzzySearchEngine,
    this.animateBounce = true,
  });

  /// Factory helper for smooth bottom-to-top modal slide transition.
  static Route<Playlist?> route({
    Playlist? initialPlaylist,
    List<Song>? initialSongs,
    PlaylistDao? playlistDao,
    SongDao? songDao,
    FuzzySearchEngine? fuzzySearchEngine,
    bool animateBounce = true,
  }) {
    return PageRouteBuilder<Playlist?>(
      pageBuilder: (context, animation, secondaryAnimation) => PlaylistEditScreen(
        initialPlaylist: initialPlaylist,
        initialSongs: initialSongs,
        playlistDao: playlistDao,
        songDao: songDao,
        fuzzySearchEngine: fuzzySearchEngine,
        animateBounce: animateBounce,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
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
  State<PlaylistEditScreen> createState() => _PlaylistEditScreenState();
}

class _PlaylistEditScreenState extends State<PlaylistEditScreen> {
  late final PlaylistDao _playlistDao;

  late final TextEditingController _nameController;

  String? _coverPath;
  String? _selectedFontFamily;
  double _textAlignX = 0.0;
  double _textAlignY = 0.0;
  int _textColor = 0xFFFFFFFF;
  int? _textGradientColor;
  bool _isGradientMode = false;
  double _fontSize = 26.0;
  String _textEffect = 'none';

  final List<Song> _playlistSongs = [];
  bool _isSaving = false;

  static TextStyle get _nameHintStyle => GoogleFonts.outfit(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant.withValues(alpha: 0.45),
    letterSpacing: -0.3,
  );

  static TextStyle get _sectionHeaderStyle => GoogleFonts.inconsolata(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle get _saveButtonStyle => GoogleFonts.inconsolata(
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: AppColors.onSurface,
  );

  @override
  void initState() {
    super.initState();
    _playlistDao = widget.playlistDao ?? PlaylistDao();

    _nameController = TextEditingController(
      text: widget.initialPlaylist?.name ?? '',
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _coverPath = widget.initialPlaylist?.coverPath;
    _selectedFontFamily = widget.initialPlaylist?.fontFamily ?? availablePlaylistFonts.first.id;
    _textAlignX = widget.initialPlaylist?.textAlignX ?? 0.0;
    _textAlignY = widget.initialPlaylist?.textAlignY ?? 0.0;
    _textColor = widget.initialPlaylist?.textColor ?? 0xFFFFFFFF;
    _textGradientColor = widget.initialPlaylist?.textGradientColor;
    _isGradientMode = _textGradientColor != null;
    _fontSize = widget.initialPlaylist?.fontSize ?? 26.0;
    _textEffect = widget.initialPlaylist?.textEffect ?? 'none';

    if (widget.initialSongs != null) {
      _playlistSongs.addAll(widget.initialSongs!);
    } else if (widget.initialPlaylist?.id != null) {
      _loadExistingSongs(widget.initialPlaylist!.id!);
    }
  }

  Future<void> _loadExistingSongs(int playlistId) async {
    try {
      final songs = await _playlistDao.getPlaylistSongs(playlistId);
      if (mounted) {
        setState(() {
          _playlistSongs.clear();
          _playlistSongs.addAll(songs);
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistEditScreen] Error loading songs: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final initialName = widget.initialPlaylist?.name ?? '';
    final currentName = _nameController.text.trim();
    if (currentName != initialName && currentName.isNotEmpty) return true;
    if (_coverPath != widget.initialPlaylist?.coverPath) return true;
    if (_selectedFontFamily != widget.initialPlaylist?.fontFamily) return true;
    if (_textAlignX != (widget.initialPlaylist?.textAlignX ?? 0.0)) return true;
    if (_textAlignY != (widget.initialPlaylist?.textAlignY ?? 0.0)) return true;
    if (_textColor != (widget.initialPlaylist?.textColor ?? 0xFFFFFFFF)) return true;
    if (_textGradientColor != widget.initialPlaylist?.textGradientColor) return true;
    if (_fontSize != (widget.initialPlaylist?.fontSize ?? 26.0)) return true;
    return false;
  }

  Future<void> _handleDismiss() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await PlaylistDiscardDialog.show(context);
    if (confirmed && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 98,
        maxWidth: 2560,
        maxHeight: 1440,
      );
      if (file != null && mounted) {
        setState(() {
          _coverPath = file.path;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistEditScreen] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.playlist.galleryPickError),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _savePlaylist() async {
    final name = _nameController.text.trim().isEmpty
        ? context.l10n.playlist.defaultPlaylistName
        : _nameController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      Playlist savedPlaylist;
      if (widget.initialPlaylist?.id != null) {
        await _playlistDao.updatePlaylist(
          widget.initialPlaylist!.id!,
          name: name,
          coverPath: _coverPath,
          fontFamily: _selectedFontFamily,
          textAlignX: _textAlignX,
          textAlignY: _textAlignY,
          textColor: _textColor,
          textGradientColor: _isGradientMode ? _textGradientColor : null,
          fontSize: _fontSize,
          textEffect: _textEffect,
          clearGradient: !_isGradientMode,
          songs: _playlistSongs,
        );
        savedPlaylist = widget.initialPlaylist!.copyWith(
          name: name,
          coverPath: _coverPath,
          fontFamily: _selectedFontFamily,
          textAlignX: _textAlignX,
          textAlignY: _textAlignY,
          textColor: _textColor,
          textGradientColor: _isGradientMode ? _textGradientColor : null,
          fontSize: _fontSize,
          textEffect: _textEffect,
          clearGradient: !_isGradientMode,
          songCount: _playlistSongs.length,
        );
      } else {
        savedPlaylist = await _playlistDao.createPlaylist(
          name,
          coverPath: _coverPath,
          fontFamily: _selectedFontFamily,
          textAlignX: _textAlignX,
          textAlignY: _textAlignY,
          textColor: _textColor,
          textGradientColor: _isGradientMode ? _textGradientColor : null,
          fontSize: _fontSize,
          textEffect: _textEffect,
          songs: _playlistSongs,
        );
      }

      PinnedFavoritesDao.revision.value++;

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).clearSnackBars();
        Navigator.of(context).pop(savedPlaylist);
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistEditScreen] Error saving playlist: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.playlist.savePlaylistError(e.toString())),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleDismiss();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bottomNavBackground,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Main Screen Column: Fixed Top Preview + Scrollable Options
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Exit Chevron Arrow (Fixed)
                  ModalDismissIndicator(
                    onDismiss: _handleDismiss,
                    animate: widget.animateBounce,
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  ),

                  // Top 2:1 Hero Photo Box (Fixed at top)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Stack(
                      children: [
                        PlaylistTextBanner(
                          title: _nameController.text,
                          coverPath: _coverPath,
                          representativeSongId: widget.initialPlaylist?.firstMediaStoreId,
                          fontFamily: _selectedFontFamily,
                          textAlignX: _textAlignX,
                          textAlignY: _textAlignY,
                          textColor: _textColor,
                          textGradientColor: _isGradientMode ? _textGradientColor : null,
                          fontSize: _fontSize,
                          textEffect: _textEffect,
                          isInteractive: true,
                          showCameraBadge: true,
                          onTap: _pickImage,
                          onPositionChanged: (offset) {
                            setState(() {
                              _textAlignX = offset.dx;
                              _textAlignY = offset.dy;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4.0),

                  // "Cambiar foto" action button (Fixed under photo box)
                  Center(
                    child: TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined, size: 15.0),
                      label: Text(
                        _coverPath != null
                            ? context.l10n.playlist.changeCover
                            : context.l10n.playlist.addCover,
                        style: GoogleFonts.inconsolata(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4.0),

                  // Scrollable Options Menu with Top & Bottom Transparency
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.05, 0.94, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8.0, bottom: 120.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Playlist Name Input Container
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(16.0),
                                  border: Border.all(
                                    color: AppColors.outline.withValues(alpha: 0.4),
                                    width: 1.0,
                                  ),
                                ),
                                child: TextField(
                                  controller: _nameController,
                                  textAlign: TextAlign.center,
                                  style: getPlaylistTitleFont(
                                    _selectedFontFamily,
                                    baseStyle: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  cursorColor: AppColors.accent,
                                  decoration: InputDecoration(
                                    hintText: context.l10n.playlist.playlistNameHint,
                                    hintStyle: _nameHintStyle,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18.0),

                            // 2. Typography Section (moved above color)
                            _buildTypographySection(context),
                            const SizedBox(height: 18.0),

                            // 3. Color & Gradient Customization Section
                            _buildColorSection(context),
                            const SizedBox(height: 18.0),

                            // 4. Text Visual Effects Section (under color system)
                            _buildEffectsSection(context),
                            const SizedBox(height: 18.0),

                            // 5. Font Size Slider Section
                            _buildFontSizeSection(context),
                            const SizedBox(height: 30.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Floating Save Button
              Positioned(
                left: 24.0,
                right: 24.0,
                bottom: MediaQuery.paddingOf(context).bottom + 20.0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 18.0,
                          spreadRadius: 1.0,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _savePlaylist,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navIndicator,
                        foregroundColor: AppColors.futuristicWhite,
                        minimumSize: const Size(180.0, 50.0),
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          side: BorderSide(
                            color: AppColors.outline.withValues(alpha: 0.5),
                            width: 1.0,
                          ),
                        ),
                      ),
                      icon: _isSaving
                          ? SizedBox(
                              width: 18.0,
                              height: 18.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: AppColors.accent,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 20.0),
                      label: Text(
                        context.l10n.playlist.saveAction,
                        style: _saveButtonStyle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _colorToHex(int colorVal) {
    return (colorVal & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  Future<void> _pickCustomColor({required bool isPrimary}) async {
    final initial = isPrimary
        ? Color(_textColor)
        : Color(_textGradientColor ?? _kDefaultGradientColor2);
    final title = isPrimary
        ? (_isGradientMode ? 'COLOR INICIAL (1)' : 'PERSONALIZAR COLOR')
        : 'COLOR FINAL (2)';

    final picked = await PlaylistColorPickerDialog.show(
      context,
      initialColor: initial,
      title: title,
    );

    if (picked != null && mounted) {
      setState(() {
        if (isPrimary) {
          _textColor = picked.toARGB32();
        } else {
          _textGradientColor = picked.toARGB32();
        }
      });
    }
  }

  Widget _buildTypographySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.playlist.typographySection,
            style: _sectionHeaderStyle,
          ),
          const SizedBox(height: 10.0),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: availablePlaylistFonts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 3.2,
            ),
            itemBuilder: (context, index) {
              final font = availablePlaylistFonts[index];
              final isSelected = (_selectedFontFamily ?? '').toLowerCase() == font.id.toLowerCase();
              return Material(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.surfaceContainerHigh.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () {
                    setState(() {
                      _selectedFontFamily = font.id;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.onAccent
                            : AppColors.outline.withValues(alpha: 0.35),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      font.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: getPlaylistTitleFont(
                        font.id,
                        baseStyle: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? AppColors.onAccent : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'COLOR DEL TEXTO',
                style: _sectionHeaderStyle,
              ),
              const Spacer(),
              // Solid vs Gradient Mode Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                padding: const EdgeInsets.all(2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleChip(
                      label: 'SÓLIDO',
                      isActive: !_isGradientMode,
                      onTap: () {
                        setState(() {
                          _isGradientMode = false;
                        });
                      },
                    ),
                    _buildToggleChip(
                      label: 'GRADIENTE',
                      isActive: _isGradientMode,
                      onTap: () {
                        setState(() {
                          _isGradientMode = true;
                          _textGradientColor ??= _kDefaultGradientColor2;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Palette Content
          if (!_isGradientMode) ...[
            // Solid Color Custom Picker Card
            _buildSolidColorPickerCard(),
          ] else ...[
            // Gradient Dual Custom Pickers Card + Preview
            _buildGradientColorPickersCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildSolidColorPickerCard() {
    final currentColor = Color(_textColor);
    final hexStr = _colorToHex(_textColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38.0,
            height: 38.0,
            decoration: BoxDecoration(
              color: currentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: currentColor.withValues(alpha: 0.45),
                  blurRadius: 10.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'COLOR ACTUAL',
                style: GoogleFonts.inconsolata(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                '#$hexStr',
                style: GoogleFonts.inconsolata(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: () => _pickCustomColor(isPrimary: true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHighest,
              foregroundColor: AppColors.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: BorderSide(
                  color: AppColors.outline.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
            ),
            icon: const Icon(Icons.palette_outlined, size: 16.0),
            label: Text(
              'Personalizar',
              style: GoogleFonts.inconsolata(
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientColorPickersCard() {
    final c1 = Color(_textColor);
    final c2 = Color(_textGradientColor ?? _kDefaultGradientColor2);
    final hex1 = _colorToHex(_textColor);
    final hex2 = _colorToHex(_textGradientColor ?? _kDefaultGradientColor2);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Gradient Preview Bar
          Container(
            height: 24.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              gradient: LinearGradient(
                colors: [c1, c2],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: c1.withValues(alpha: 0.35),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // Two Color Pickers side by side with Swap in the middle
          Row(
            children: [
              // Color 1
              Expanded(
                child: InkWell(
                  onTap: () => _pickCustomColor(isPrimary: true),
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24.0,
                          height: 24.0,
                          decoration: BoxDecoration(
                            color: c1,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COLOR 1',
                                style: GoogleFonts.inconsolata(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '#$hex1',
                                style: GoogleFonts.inconsolata(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.palette_outlined, size: 16.0, color: AppColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6.0),

              // Swap Button
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, size: 20.0),
                color: AppColors.accent,
                tooltip: 'Invertir colores',
                splashRadius: 18.0,
                onPressed: () {
                  setState(() {
                    final temp = _textColor;
                    _textColor = _textGradientColor ?? _kDefaultGradientColor2;
                    _textGradientColor = temp;
                  });
                },
              ),
              const SizedBox(width: 6.0),

              // Color 2
              Expanded(
                child: InkWell(
                  onTap: () => _pickCustomColor(isPrimary: false),
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24.0,
                          height: 24.0,
                          decoration: BoxDecoration(
                            color: c2,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COLOR 2',
                                style: GoogleFonts.inconsolata(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '#$hex2',
                                style: GoogleFonts.inconsolata(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.palette_outlined, size: 16.0, color: AppColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEffectsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EFECTOS DE TEXTO',
            style: _sectionHeaderStyle,
          ),
          const SizedBox(height: 10.0),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: availablePlaylistEffects.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 3.2,
            ),
            itemBuilder: (context, index) {
              final effect = availablePlaylistEffects[index];
              final isSelected = _textEffect.toLowerCase() == effect.id.toLowerCase();
              final effectShadows = getPlaylistTextEffectShadows(effect.id, textColor: _textColor);

              return Material(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.surfaceContainerHigh.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () {
                    setState(() {
                      _textEffect = effect.id;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.onAccent
                            : AppColors.outline.withValues(alpha: 0.35),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      effect.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inconsolata(
                        fontSize: 14.0,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.onAccent : AppColors.onSurface,
                        shadows: isSelected ? null : effectShadows,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TAMAÑO DE LA LETRA',
                style: _sectionHeaderStyle,
              ),
              Text(
                '${_fontSize.toInt()} px',
                style: GoogleFonts.inconsolata(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.text_decrease_rounded, size: 20.0),
                  color: AppColors.onSurfaceVariant,
                  tooltip: 'Reducir tamaño',
                  splashRadius: 18.0,
                  onPressed: _fontSize > 14.0
                      ? () {
                          setState(() {
                            _fontSize = (_fontSize - 2.0).clamp(14.0, 52.0);
                          });
                        }
                      : null,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.surfaceContainerHighest,
                      thumbColor: AppColors.accent,
                      overlayColor: AppColors.accent.withValues(alpha: 0.2),
                      trackHeight: 4.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                    ),
                    child: Slider(
                      value: _fontSize,
                      min: 14.0,
                      max: 52.0,
                      divisions: 38,
                      onChanged: (val) {
                        setState(() {
                          _fontSize = val;
                        });
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase_rounded, size: 20.0),
                  color: AppColors.onSurfaceVariant,
                  tooltip: 'Aumentar tamaño',
                  splashRadius: 18.0,
                  onPressed: _fontSize < 52.0
                      ? () {
                          setState(() {
                            _fontSize = (_fontSize + 2.0).clamp(14.0, 52.0);
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: Text(
          label,
          style: GoogleFonts.inconsolata(
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: isActive ? AppColors.onAccent : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
