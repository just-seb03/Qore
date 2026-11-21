/// File: player_marquee_text.dart
/// Description: Lightweight smooth horizontal marquee widget for long song titles and
/// album names in the expanded player. Remains centered and static when the text fits.
///
/// Components / Classes / Functions:
/// - PlayerMarqueeText: Auto-scrolling single-line text widget for overflowing labels.
library;

import 'package:flutter/material.dart';

/// Displays [text] centered and static when it fits; gently scrolls horizontally when it overflows.
class PlayerMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double velocityPxPerSec;
  final Duration pauseDuration;

  const PlayerMarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.velocityPxPerSec = 26.0,
    this.pauseDuration = const Duration(milliseconds: 1400),
  });

  @override
  State<PlayerMarqueeText> createState() => _PlayerMarqueeTextState();
}

class _PlayerMarqueeTextState extends State<PlayerMarqueeText>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _controller;
  double _maxScroll = 0.0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(() {
        if (_scrollController.hasClients && _maxScroll > 0) {
          _scrollController.jumpTo(_controller.value * _maxScroll);
        }
      });
  }

  @override
  void didUpdateWidget(PlayerMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _stopAndReset();
    }
  }

  void _stopAndReset() {
    _isAnimating = false;
    _controller.stop();
    _controller.value = 0.0;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  Future<void> _startMarqueeLoop(double maxScroll) async {
    if (_isAnimating || !mounted) return;
    _isAnimating = true;
    _maxScroll = maxScroll;

    final int scrollMs =
        ((maxScroll / widget.velocityPxPerSec) * 1000).round().clamp(1200, 12000);
    _controller.duration = Duration(milliseconds: scrollMs);

    while (mounted && _isAnimating && _maxScroll > 0) {
      await Future.delayed(widget.pauseDuration);
      if (!mounted || !_isAnimating) break;
      try {
        await _controller.forward(from: 0.0);
      } catch (_) {
        break;
      }
      if (!mounted || !_isAnimating) break;
      await Future.delayed(widget.pauseDuration);
      if (!mounted || !_isAnimating) break;
      try {
        await _controller.reverse(from: 1.0);
      } catch (_) {
        break;
      }
    }
  }

  @override
  void dispose() {
    _isAnimating = false;
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite || maxWidth <= 0) {
          return Text(
            widget.text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }

        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout();

        final double overflow = painter.width - maxWidth;
        if (overflow <= 2.0) {
          if (_isAnimating) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _stopAndReset();
            });
          }
          return Text(
            widget.text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }

        if (!_isAnimating || (_maxScroll - overflow).abs() > 2.0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _startMarqueeLoop(overflow);
            }
          });
        }

        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Text(
            widget.text,
            maxLines: 1,
            softWrap: false,
            style: widget.style,
          ),
        );
      },
    );
  }
}
