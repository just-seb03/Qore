/// File: artist_avatar_crop_screen.dart
/// Description: Full-screen modal route for interactive 1:1 artist avatar photo cropping and alignment,
/// delegating viewport rendering to ArtistAvatarCropView and utilizing GPU RepaintBoundary rasterization.
///
/// Components / Classes / Functions:
/// - ArtistAvatarCropScreen: Full-screen interactive 1:1 avatar cropping screen.
library;

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist/components/artist_avatar_crop_view.dart';

/// Interactive 1:1 avatar cropper screen for artist photo personalization.
class ArtistAvatarCropScreen extends StatefulWidget {
  /// File of the picked image to crop.
  final File imageFile;

  const ArtistAvatarCropScreen({
    super.key,
    required this.imageFile,
  });

  /// Factory helper for smooth bottom-to-top modal route presentation.
  static MaterialPageRoute<Uint8List?> route({required File imageFile}) {
    return MaterialPageRoute<Uint8List?>(
      builder: (_) => ArtistAvatarCropScreen(imageFile: imageFile),
      fullscreenDialog: true,
    );
  }

  @override
  State<ArtistAvatarCropScreen> createState() => _ArtistAvatarCropScreenState();
}

class _ArtistAvatarCropScreenState extends State<ArtistAvatarCropScreen> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  bool _isProcessing = false;

  static final TextStyle _titleStyle = AppFonts.segoe(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static final TextStyle _buttonStyle = AppFonts.segoe(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmCrop(double viewportSize) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final boundary =
          _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Navigator.of(context).pop(null);
        return;
      }

      final pixelRatio = 512.0 / viewportSize;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData != null && mounted) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        Navigator.of(context).pop(pngBytes);
      } else if (mounted) {
        Navigator.of(context).pop(null);
      }
    } catch (e) {
      debugPrint('Error cropping artist avatar: $e');
      if (mounted) Navigator.of(context).pop(null);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double viewportSize = (screenSize.width - 48.0).clamp(240.0, 360.0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null),
          tooltip: 'Cancel',
        ),
        title: Text('Adjust Photo', style: _titleStyle),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isProcessing
                ? const Center(
                    child: SizedBox(
                      width: 22.0,
                      height: 22.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: () => _handleConfirmCrop(viewportSize),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    child: Text('Save', style: _buttonStyle),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // 1. Interactive 1:1 Viewport with Circular Mask Guide
            ArtistAvatarCropView(
              cropKey: _cropKey,
              transformController: _transformController,
              imageFile: widget.imageFile,
              viewportSize: viewportSize,
            ),

            const Spacer(),

            // 2. Helpful Guidance & Reset Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 18.0,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Pinch & drag to adjust',
                        style: AppFonts.segoe(
                          fontSize: 13.0,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _transformController.value = Matrix4.identity();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16.0),
                    label: const Text('Center'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
          ],
        ),
      ),
    );
  }
}
