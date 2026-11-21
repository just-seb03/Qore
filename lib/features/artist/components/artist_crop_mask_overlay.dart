/// File: artist_crop_mask_overlay.dart
/// Description: CustomPainter component rendering a 1:1 square cropping guideline mask,
/// rule-of-thirds grid, corner brackets, and subtle circular avatar reference boundary.
///
/// Components / Classes / Functions:
/// - ArtistCropMaskOverlay: CustomPainter drawing the 1:1 square crop overlay.
library;

import 'package:flutter/material.dart';

/// CustomPainter rendering a 1:1 square crop frame with corner accents.
class ArtistCropMaskOverlay extends CustomPainter {
  /// Size of the 1:1 square viewport.
  final double viewportSize;

  static final Paint _gridPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.16)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  static final Paint _squareBorderPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.60)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint _cornerPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.square;

  ArtistCropMaskOverlay({required this.viewportSize});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0.5, 0.5, size.width - 1.0, size.height - 1.0);

    // 1. Subtle rule of thirds guidelines inside the 1:1 square
    final step = size.width / 3.0;
    canvas.drawLine(Offset(step, 0), Offset(step, size.height), _gridPaint);
    canvas.drawLine(Offset(step * 2, 0), Offset(step * 2, size.height), _gridPaint);
    canvas.drawLine(Offset(0, step), Offset(size.width, step), _gridPaint);
    canvas.drawLine(Offset(0, step * 2), Offset(size.width, step * 2), _gridPaint);

    // 2. 1:1 Square boundary border
    canvas.drawRect(rect, _squareBorderPaint);

    // 4. Solid corner cropper brackets (classic framing accents)
    const cornerLength = 18.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), _cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), _cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), _cornerPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), _cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), _cornerPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), _cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), _cornerPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), _cornerPaint);
  }

  @override
  bool shouldRepaint(covariant ArtistCropMaskOverlay oldDelegate) =>
      oldDelegate.viewportSize != viewportSize;
}
