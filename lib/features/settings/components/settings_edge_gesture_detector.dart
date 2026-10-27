/// File: settings_edge_gesture_detector.dart
/// Description: Gesture coordinator listening to rightward horizontal swipe gestures in Space.
/// Drives the Material 3 Expressive edge bump indicator ("montañita") and triggers the
/// lateral settings side sheet upon release when threshold is exceeded.
///
/// Components / Classes / Functions:
/// - SettingsEdgeGestureDetector: Stateful gesture wrapper and indicator renderer.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/features/settings/components/settings_edge_bump.dart';
import 'package:project_anima/features/settings/controls/settings_controller.dart';

/// Wraps Space content to detect rightward horizontal drags and trigger the Settings side sheet.
class SettingsEdgeGestureDetector extends StatefulWidget {
  /// The underlying Space screen content.
  final Widget child;

  /// Optional custom activation threshold in logical pixels. Defaults to 72.0.
  final double triggerThreshold;

  /// Optional controller override for dependency injection in tests.
  final SettingsController? controller;

  const SettingsEdgeGestureDetector({
    super.key,
    required this.child,
    this.triggerThreshold = 72.0,
    this.controller,
  });

  @override
  State<SettingsEdgeGestureDetector> createState() =>
      _SettingsEdgeGestureDetectorState();
}

class _SettingsEdgeGestureDetectorState
    extends State<SettingsEdgeGestureDetector>
    with SingleTickerProviderStateMixin {
  SettingsController get _controller =>
      widget.controller ?? SettingsController.instance;

  double _startX = 0.0;
  double _currentY = 320.0;
  double _progress = 0.0;
  bool _isDragging = false;
  bool _hasHapticFired = false;

  late final AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        setState(() {
          _progress = _snapAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (_controller.isSheetOpen) return;
    _snapController.stop();
    _startX = details.globalPosition.dx;
    _currentY = details.globalPosition.dy;
    _isDragging = true;
    _hasHapticFired = false;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _controller.isSheetOpen) return;

    final double deltaX = details.globalPosition.dx - _startX;
    if (deltaX < 0) {
      if (_progress > 0) {
        setState(() => _progress = 0.0);
      }
      return;
    }

    final double rawProgress = (deltaX / widget.triggerThreshold).clamp(0.0, 1.25);
    final double screenHeight = MediaQuery.of(context).size.height;

    setState(() {
      _progress = rawProgress.clamp(0.0, 1.0);
      _currentY = details.globalPosition.dy.clamp(90.0, screenHeight - 120.0);
    });

    if (_progress >= 0.95 && !_hasHapticFired) {
      _hasHapticFired = true;
      HapticFeedback.lightImpact();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0.0;
    final bool shouldOpen = _progress >= 0.8 || velocity > 260.0;

    if (shouldOpen) {
      setState(() => _progress = 0.0);
      _controller.openSheet();
    } else {
      _snapAnimation = Tween<double>(begin: _progress, end: 0.0).animate(
        CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
      );
      _snapController.forward(from: 0.0);
    }
  }

  void _onDragCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    _snapAnimation = Tween<double>(begin: _progress, end: 0.0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,

          // Organic Material 3 Expressive edge bump indicator
          if (_progress > 0.001)
            Positioned.fill(
              child: IgnorePointer(
                child: SettingsEdgeBump(
                  progress: _progress,
                  currentY: _currentY,
                  isActivating: _progress >= 0.9,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
