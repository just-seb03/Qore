/// File: artist_crop_mask_overlay.dart
/// Description: CustomPainter component rendering a circular guideline mask, rule-of-thirds grid,
/// and darkened vignette outside the 1:1 circular cropping boundary.
///
/// Components / Classes / Functions:
/// - ArtistCropMaskOverlay: CustomPainter drawing the circular crop overlay.
library;

import 'package:flutter/material.dart';

/// CustomPainter that renders a transparent circle in the center and darkens the exterior.
class ArtistCropMaskOverlay extends CustomPainter {
  /// Size of the circular viewport.
  final double viewportSize;

  ArtistCropMaskOverlay({required this.viewportSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 1.0;

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.60)
      ..style = PaintingStyle.fill;

    // Draw dark background with circular hole
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // Draw circular guideline border
    final circleBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, circleBorderPaint);

    // Subtle rule of thirds guidelines inside the circle
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final step = size.width / 3.0;
    canvas.drawLine(Offset(step, 0), Offset(step, size.height), gridPaint);
    canvas.drawLine(Offset(step * 2, 0), Offset(step * 2, size.height), gridPaint);
    canvas.drawLine(Offset(0, step), Offset(size.width, step), gridPaint);
    canvas.drawLine(Offset(0, step * 2), Offset(size.width, step * 2), gridPaint);
  }

  @override
  bool shouldRepaint(covariant ArtistCropMaskOverlay oldDelegate) =>
      oldDelegate.viewportSize != viewportSize;
}
