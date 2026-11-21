/// File: scroll_edge_fade_mask.dart
/// Description: Lightweight edge fade overlay blending scrolling boundaries into the backdrop
/// using pointer-ignored linear gradient strips driven by [ValueNotifier]s, eliminating
/// full-viewport [ShaderMask] saveLayers and per-frame widget rebuilds during scroll.
///
/// Components / Classes / Functions:
/// - ScrollEdgeFadeMask: Stateful coordinator rendering top and bottom edge fade strips.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Edge fade overlay applying smooth linear gradients at top and bottom scroll boundaries
/// without offscreen [ShaderMask] render targets or child subtree rebuilds.
class ScrollEdgeFadeMask extends StatefulWidget {
  /// The scrollable child widget (e.g. ListView, GridView, CustomScrollView).
  final Widget child;

  /// Maximum extent of the top fade in logical pixels. Defaults to 24.0.
  final double topFadeExtent;

  /// Maximum extent of the bottom fade in logical pixels. Defaults to 24.0.
  final double bottomFadeExtent;

  /// Optional ScrollController to synchronize initial offset if already scrolled.
  final ScrollController? scrollController;

  const ScrollEdgeFadeMask({
    super.key,
    required this.child,
    this.topFadeExtent = 24.0,
    this.bottomFadeExtent = 24.0,
    this.scrollController,
  });

  @override
  State<ScrollEdgeFadeMask> createState() => _ScrollEdgeFadeMaskState();
}

class _ScrollEdgeFadeMaskState extends State<ScrollEdgeFadeMask> {
  final ValueNotifier<double> _topFactor = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _bottomFactor = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null && widget.scrollController!.hasClients) {
      _evaluateOffset(
        widget.scrollController!.offset,
        widget.scrollController!.position.maxScrollExtent,
      );
    }
  }

  @override
  void dispose() {
    _topFactor.dispose();
    _bottomFactor.dispose();
    super.dispose();
  }

  void _evaluateOffset(double offset, double maxScroll) {
    final newTop =
        (offset / math.max(1.0, widget.topFadeExtent)).clamp(0.0, 1.0);

    final remaining = maxScroll - offset;
    final newBottom = maxScroll <= 0.0
        ? 0.0
        : (remaining / math.max(1.0, widget.bottomFadeExtent)).clamp(0.0, 1.0);

    if ((newTop - _topFactor.value).abs() > 0.02) {
      _topFactor.value = newTop;
    }
    if ((newBottom - _bottomFactor.value).abs() > 0.02) {
      _bottomFactor.value = newBottom;
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

  Widget _buildEdgeStrip({
    required ValueNotifier<double> factorNotifier,
    required double extent,
    required Alignment begin,
    required Alignment end,
  }) {
    if (extent <= 0.0) return const SizedBox.shrink();
    return ValueListenableBuilder<double>(
      valueListenable: factorNotifier,
      builder: (context, factor, _) {
        if (factor <= 0.01) return const SizedBox.shrink();
        final baseColor = AppColors.bottomNavBackground;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: [
                baseColor.withValues(alpha: factor * 0.92),
                baseColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (widget.topFadeExtent > 0.0)
            Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              height: widget.topFadeExtent,
              child: IgnorePointer(
                child: _buildEdgeStrip(
                  factorNotifier: _topFactor,
                  extent: widget.topFadeExtent,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          if (widget.bottomFadeExtent > 0.0)
            Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              height: widget.bottomFadeExtent,
              child: IgnorePointer(
                child: _buildEdgeStrip(
                  factorNotifier: _bottomFactor,
                  extent: widget.bottomFadeExtent,
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
