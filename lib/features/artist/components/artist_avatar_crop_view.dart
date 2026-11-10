/// File: artist_avatar_crop_view.dart
/// Description: Interactive 1:1 square viewport with pinch-to-zoom, pan alignment,
/// RepaintBoundary capture target, and circular mask guide overlay.
///
/// Components / Classes / Functions:
/// - ArtistAvatarCropView: Viewport widget for avatar image scaling and alignment.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project_anima/features/artist/components/artist_crop_mask_overlay.dart';

/// Interactive 1:1 image viewport for avatar alignment and cropping.
class ArtistAvatarCropView extends StatelessWidget {
  /// GlobalKey attached to the RepaintBoundary for rasterization.
  final GlobalKey cropKey;

  /// TransformationController managing translation and scaling matrix.
  final TransformationController transformController;

  /// The local image file to align and crop.
  final File imageFile;

  /// The square viewport dimension (width and height).
  final double viewportSize;

  const ArtistAvatarCropView({
    super.key,
    required this.cropKey,
    required this.transformController,
    required this.imageFile,
    required this.viewportSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: viewportSize,
        height: viewportSize,
        child: ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // RepaintBoundary capturing the exact 1:1 transformed image
              RepaintBoundary(
                key: cropKey,
                child: Container(
                  width: viewportSize,
                  height: viewportSize,
                  color: Colors.black,
                  child: InteractiveViewer(
                    transformationController: transformController,
                    minScale: 0.8,
                    maxScale: 5.0,
                    panEnabled: true,
                    scaleEnabled: true,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      cacheWidth: 1600,
                      cacheHeight: 1600,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),

              // Overlay Mask (Darkens outer corners, shows circular boundary)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: ArtistCropMaskOverlay(viewportSize: viewportSize),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
