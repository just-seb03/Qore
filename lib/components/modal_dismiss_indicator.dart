/// File: modal_dismiss_indicator.dart
/// Description: Universal animated downward-pointing "V" chevron dismiss indicator used
/// across modal screens (Player, Artist Detail, Album Detail) with zero-cost RepaintBoundary
/// isolation, gentle vertical floating animation, and interactive swipe/tap gesture handling.
///
/// Components / Classes / Functions:
/// - ModalDismissIndicator: Universal animated chevron dismiss indicator widget.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Universal animated downward-pointing chevron cueing swipe-down or tap to dismiss.
class ModalDismissIndicator extends StatefulWidget {
  /// Callback triggered when the indicator is tapped or swiped down past threshold.
  final VoidCallback onDismiss;

  /// Optional callback to notify parent during an interactive vertical pull down.
  final ValueChanged<double>? onDragUpdate;

  /// Optional callback when an interactive drag completes.
  final ValueChanged<DragEndDetails>? onDragEnd;

  /// Visual size of the chevron icon. Defaults to 32.0.
  final double size;

  /// Color of the chevron icon. Defaults to [AppColors.onSurfaceVariant].
  final Color? color;

  /// Whether to run continuous floating bounce animation (set to false in headless tests).
  final bool animate;

  /// Outer padding around the hit target. Defaults to 4.0 vertical, 24.0 horizontal.
  final EdgeInsetsGeometry padding;

  const ModalDismissIndicator({
    super.key,
    required this.onDismiss,
    this.onDragUpdate,
    this.onDragEnd,
    this.size = 32.0,
    this.color,
    this.animate = true,
    this.padding = const EdgeInsets.symmetric(vertical: 4.0, horizontal: 24.0),
  });

  @override
  State<ModalDismissIndicator> createState() => _ModalDismissIndicatorState();
}

class _ModalDismissIndicatorState extends State<ModalDismissIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _bounceAnimation;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutSine,
      ),
    );

    if (widget.animate) {
      _playEntranceHint();
    }
  }

  Future<void> _playEntranceHint() async {
    try {
      for (int i = 0; i < 2; i++) {
        if (!mounted || _isDisposed) return;
        await _animController.forward();
        if (!mounted || _isDisposed) return;
        await _animController.reverse();
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant ModalDismissIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _playEntranceHint();
      } else {
        _animController.stop();
        _animController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onDismiss,
      onVerticalDragUpdate: (details) {
        if (widget.onDragUpdate != null) {
          widget.onDragUpdate!(details.primaryDelta ?? 0.0);
        } else if ((details.primaryDelta ?? 0.0) > 6.0) {
          widget.onDismiss();
        }
      },
      onVerticalDragEnd: (details) {
        if (widget.onDragEnd != null) {
          widget.onDragEnd!(details);
        } else if ((details.primaryVelocity ?? 0.0) > 200.0) {
          widget.onDismiss();
        }
      },
      child: Padding(
        padding: widget.padding,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0.0, _bounceAnimation.value),
                child: child,
              );
            },
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: widget.size,
              color: widget.color ?? AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
