/// File: playlist_text_banner.dart
/// Description: 2:1 widescreen hero banner for playlists in Library, Space, and PlaylistEditScreen.
/// Displays full-space unrounded cover artwork with customizable interactive/static text positioning,
/// custom Google Fonts typography, solid or dual-color gradient shaders, and high-contrast shadows.
///
/// Components / Classes / Functions:
/// - PlaylistTextBanner: Reusable 2:1 aspect ratio playlist banner widget.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/playlist/utils/playlist_effect_helper.dart';
import 'package:project_anima/features/playlist/utils/playlist_font_helper.dart';

/// 2:1 AspectRatio Playlist banner rendering custom positioned, custom styled title over artwork.
class PlaylistTextBanner extends StatelessWidget {
  /// Display title of the playlist.
  final String title;

  /// Optional local filesystem path to custom picked image.
  final String? coverPath;

  /// Fallback representative song media store id.
  final int? representativeSongId;

  /// Custom typography font family (e.g. 'UnifrakturMaguntia', 'Permanent Marker', etc.).
  final String? fontFamily;

  /// Horizontal text alignment in range [-1.0, 1.0].
  final double textAlignX;

  /// Vertical text alignment in range [-1.0, 1.0].
  final double textAlignY;

  /// Primary 32-bit ARGB color integer for text.
  final int textColor;

  /// Optional secondary 32-bit ARGB color integer for dual-color gradient.
  final int? textGradientColor;

  /// Whether the user can drag the text around interactively (used in PlaylistEditScreen).
  final bool isInteractive;

  /// Callback when user drags the text to a new position.
  final ValueChanged<Offset>? onPositionChanged;

  /// Callback when user taps the banner (e.g. to change photo in editor, or open playlist in card).
  final VoidCallback? onTap;

  /// Whether to show the camera badge at bottom-right (for editor).
  final bool showCameraBadge;

  /// Base font size for the title text (defaults to 26.0).
  final double fontSize;

  /// Visual styling effect identifier (e.g. 'none', 'shadow', 'neon', 'glitch', 'outline', 'retro3d').
  final String textEffect;

  const PlaylistTextBanner({
    super.key,
    required this.title,
    this.coverPath,
    this.representativeSongId,
    this.fontFamily,
    this.textAlignX = 0.0,
    this.textAlignY = 0.0,
    this.textColor = 0xFFFFFFFF,
    this.textGradientColor,
    this.isInteractive = false,
    this.onPositionChanged,
    this.onTap,
    this.showCameraBadge = false,
    this.fontSize = 26.0,
    this.textEffect = 'none',
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.0, // Strict 2:1 aspect ratio matching Space
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.zero, // Strict 90-degree unrounded corners
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Cover Artwork or Stylized Fallback
            _buildBackground(context),

            // 2. Interactive or Static Positioned Text Overlay
            _buildTextOverlay(context),

            // 3. Optional Camera Badge (bottom-right)
            if (showCameraBadge)
              Positioned(
                right: 8.0,
                bottom: 8.0,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: AppColors.navIndicator,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 8.0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.bottomNavBackground,
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 18.0,
                        color: AppColors.futuristicWhite,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    if (coverPath != null && File(coverPath!).existsSync()) {
      final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.5;
      final screenW = MediaQuery.maybeSizeOf(context)?.width ?? 400.0;
      final cacheW = (screenW * dpr).round().clamp(400, 1000);
      final cacheH = (cacheW * 0.5).round();

      return Image.file(
        File(coverPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: cacheW,
        cacheHeight: cacheH,
        filterQuality: FilterQuality.medium,
      );
    }

    if (representativeSongId != null && representativeSongId! > 0) {
      return AnimaArtworkImage(
        mediaStoreId: representativeSongId!,
        width: double.infinity,
        height: double.infinity,
        borderRadius: 0.0,
        fit: BoxFit.cover,
        fallbackIcon: Icons.queue_music_rounded,
        isThumbnail: false,
      );
    }

    // Default dark futuristic gradient placeholder
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF242436),
            Color(0xFF161622),
            Color(0xFF101018),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Symbols.queue_music_rounded,
          size: 48.0,
          color: AppColors.futuristicWhite.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildTextOverlay(BuildContext context) {
    final displayTitle = title.trim().isEmpty ? 'Mi Playlist' : title.trim();

    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
    );

    final resolvedStyle = getPlaylistTitleFont(fontFamily, baseStyle: baseStyle);
    final shadows = getPlaylistTextEffectShadows(textEffect, textColor: textColor);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;

        final alignment = Alignment(
          textAlignX.clamp(-0.96, 0.96),
          textAlignY.clamp(-0.94, 0.94),
        );

        final Widget textContent;
        if (textGradientColor != null) {
          textContent = Stack(
            alignment: Alignment.center,
            children: [
              if (shadows.isNotEmpty)
                Text(
                  displayTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: resolvedStyle.copyWith(
                    color: Colors.transparent,
                    shadows: shadows,
                  ),
                ),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(textColor),
                      Color(textGradientColor!),
                    ],
                  ).createShader(bounds);
                },
                child: Text(
                  displayTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: resolvedStyle.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        } else {
          textContent = Text(
            displayTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: resolvedStyle.copyWith(
              color: Color(textColor),
              shadows: shadows.isNotEmpty ? shadows : null,
            ),
          );
        }

        if (isInteractive) {
          return Align(
            alignment: alignment,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                if (onPositionChanged != null && w > 0 && h > 0) {
                  final double deltaX = details.delta.dx / (w / 2);
                  final double deltaY = details.delta.dy / (h / 2);
                  final double newX = (textAlignX + deltaX).clamp(-0.96, 0.96);
                  final double newY = (textAlignY + deltaY).clamp(-0.94, 0.94);
                  onPositionChanged!(Offset(newX, newY));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.40),
                    width: 1.0,
                  ),
                  color: Colors.black.withValues(alpha: 0.20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.open_with_rounded,
                      size: 14.0,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4.0),
                    Flexible(child: textContent),
                  ],
                ),
              ),
            ),
          );
        }

        return Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: textContent,
          ),
        );
      },
    );
  }
}
