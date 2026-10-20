/// File: player_dismiss_indicator.dart
/// Description: Animated downward-pointing "V" chevron dismiss indicator located below
/// the player controls. Features a subtle, highly-optimized vertical floating animation,
/// zero-cost RepaintBoundary isolation, and tap / swipe-to-dismiss gesture handling.
///
/// Components / Classes / Functions:
/// - PlayerDismissIndicator: Animated chevron widget signaling swipe-down / tap dismissal.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Animated downward-pointing "V" chevron cueing swipe-down or tap to dismiss.
class PlayerDismissIndicator extends StatefulWidget {
  /// Callback triggered when the indicator is tapped or swiped down past threshold.
  final VoidCallback onDismiss;

  /// Optional callback to notify parent during an interactive vertical pull down.
  final ValueChanged<double>? onDragUpdate;

  /// Optional callback when an interactive drag completes.
  final ValueChanged<DragEndDetails>? onDragEnd;

  const PlayerDismissIndicator({
    super.key,
    required this.onDismiss,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  State<PlayerDismissIndicator> createState() => _PlayerDismissIndicatorState();
}

class _PlayerDismissIndicatorState extends State<PlayerDismissIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
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
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 24.0),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0.0, _bounceAnimation.value),
                child: child,
              );
            },
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 32.0,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
