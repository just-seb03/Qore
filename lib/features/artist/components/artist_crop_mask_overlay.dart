/// File: artist_crop_mask_overlay.dart
/// Description: CustomPainter component rendering a 1:1 square cropping guideline mask,
/// rule-of-thirds grid, corner brackets, and subtle circular avatar reference boundary.
///
/// Components / Classes / Functions:
/// - ArtistCropMaskOverlay: CustomPainter drawing the 1:1 square crop overlay.
library;

import 'package:flutter/material.dart';

/// CustomPainter rendering a 1:1 square crop frame with corner accents and avatar reference.
class ArtistCropMaskOverlay extends CustomPainter {
  /// Size of the 1:1 square viewport.
  final double viewportSize;

  ArtistCropMaskOverlay({required this.viewportSize});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0.5, 0.5, size.width - 1.0, size.height - 1.0);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2.0;

    // 1. Subtle rule of thirds guidelines inside the 1:1 square
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final step = size.width / 3.0;
    canvas.drawLine(Offset(step, 0), Offset(step, size.height), gridPaint);
    canvas.drawLine(Offset(step * 2, 0), Offset(step * 2, size.height), gridPaint);
    canvas.drawLine(Offset(0, step), Offset(size.width, step), gridPaint);
    canvas.drawLine(Offset(0, step * 2), Offset(size.width, step * 2), gridPaint);

    // 2. Subtle circular reference guide indicating avatar framing area
    final circleRefPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, circleRefPaint);

    // 3. 1:1 Square boundary border
    final squareBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(rect, squareBorderPaint);

    // 4. Solid corner cropper brackets (classic framing accents)
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;

    const cornerLength = 18.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant ArtistCropMaskOverlay oldDelegate) =>
      oldDelegate.viewportSize != viewportSize;
}
