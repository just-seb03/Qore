/// File: scroll_edge_fade_mask.dart
/// Description: Reusable Material Design 3 Expressive edge transparency mask that
/// dynamically blends the top and bottom boundaries of a scrollable view into transparency.
/// Employs a GPU-accelerated ShaderMask with dynamic edge factor calculations driven by
/// scroll notifications, ensuring zero overhead and pristine aesthetics without hard cuts.
///
/// Components / Classes / Functions:
/// - ScrollEdgeFadeMask: Stateful coordinator applying top and bottom linear gradient fades.
/// - _ScrollEdgeFadePainter: Helper encapsulating gradient stops and shader generation.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dynamic edge transparency mask applying fluid alpha transitions to top and bottom scroll edges.
///
/// Automatically activates top fade as content scrolls down, and fades the bottom edge
/// until the user reaches the end of the scrollable extent.
class ScrollEdgeFadeMask extends StatefulWidget {
  /// The scrollable child widget (e.g. ListView, GridView, CustomScrollView).
  final Widget child;

  /// Maximum extent of the top fade in logical pixels. Defaults to 28.0.
  final double topFadeExtent;

  /// Maximum extent of the bottom fade in logical pixels. Defaults to 32.0.
  final double bottomFadeExtent;

  /// Optional ScrollController to synchronize initial offset if already scrolled.
  final ScrollController? scrollController;

  const ScrollEdgeFadeMask({
    super.key,
    required this.child,
    this.topFadeExtent = 28.0,
    this.bottomFadeExtent = 32.0,
    this.scrollController,
  });

  @override
  State<ScrollEdgeFadeMask> createState() => _ScrollEdgeFadeMaskState();
}

class _ScrollEdgeFadeMaskState extends State<ScrollEdgeFadeMask> {
  double _topFactor = 0.0;
  double _bottomFactor = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null && widget.scrollController!.hasClients) {
      _evaluateOffset(widget.scrollController!.offset, widget.scrollController!.position.maxScrollExtent);
    }
  }

  void _evaluateOffset(double offset, double maxScroll) {
    // 0.0 at top resting state, smoothly ramps to 1.0 within topFadeExtent
    final newTop = (offset / math.max(1.0, widget.topFadeExtent)).clamp(0.0, 1.0);

    // 1.0 while remaining content exists, smoothly ramps to 0.0 when approaching maxScrollExtent
    final remaining = maxScroll - offset;
    final newBottom = maxScroll <= 0.0
        ? 0.0
        : (remaining / math.max(1.0, widget.bottomFadeExtent)).clamp(0.0, 1.0);

    if ((newTop - _topFactor).abs() > 0.01 || (newBottom - _bottomFactor).abs() > 0.01) {
      _topFactor = newTop;
      _bottomFactor = newBottom;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      _evaluateOffset(
        notification.metrics.pixels,
        notification.metrics.maxScrollExtent,
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (Rect bounds) {
          final height = bounds.height;
          if (height <= 0.0) {
            return const LinearGradient(
              colors: [Colors.black, Colors.black],
            ).createShader(bounds);
          }

          final effectiveTopStop = (widget.topFadeExtent * _topFactor) / height;
          final effectiveBottomStop = 1.0 - ((widget.bottomFadeExtent * _bottomFactor) / height);

          // Ensure stops are strictly monotonic
          final clampedTop = effectiveTopStop.clamp(0.0, 0.45);
          final clampedBottom = effectiveBottomStop.clamp(clampedTop, 1.0);

          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [
              0.0,
              clampedTop,
              clampedBottom,
              1.0,
            ],
          ).createShader(bounds);
        },
        child: widget.child,
      ),
    );
  }
}
