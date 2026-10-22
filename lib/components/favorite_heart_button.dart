/// File: favorite_heart_button.dart
/// Description: Premium animated heart toggle button for pinning favorites (Album, Artist, Playlist).
/// Features spring bounce scaling animation, filled white active state, outlined inactive state,
/// and optional translucent dark glass backdrop for overlaying on image banners.
///
/// Components / Classes / Functions:
/// - FavoriteHeartButton: Stateful animated heart button for favorites.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated heart toggle button for pinning albums, artists, and playlists to favorites.
class FavoriteHeartButton extends StatefulWidget {
  /// Whether the item is currently pinned/favorited.
  final bool isPinned;

  /// Callback when the button is pressed.
  final VoidCallback onToggle;

  /// Icon size (defaults to 28.0).
  final double size;

  /// Color when active/pinned (defaults to white).
  final Color activeColor;

  /// Color when inactive/unpinned (defaults to translucent white).
  final Color inactiveColor;

  /// Whether to render a translucent dark glass circular container (ideal for artwork overlays).
  final bool showBackground;

  const FavoriteHeartButton({
    super.key,
    required this.isPinned,
    required this.onToggle,
    this.size = 28.0,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0xB3FFFFFF),
    this.showBackground = false,
  });

  @override
  State<FavoriteHeartButton> createState() => _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends State<FavoriteHeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60.0,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant FavoriteHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isPinned && widget.isPinned) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    if (!widget.isPinned) {
      _controller.forward(from: 0.0);
    }
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final iconWidget = ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        widget.isPinned ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: widget.size,
        color: widget.isPinned ? widget.activeColor : widget.inactiveColor,
        shadows: widget.isPinned
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );

    if (widget.showBackground) {
      return Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _handleTap,
          splashColor: Colors.white.withValues(alpha: 0.20),
          highlightColor: Colors.white.withValues(alpha: 0.10),
          child: Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.60),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.50),
                  blurRadius: 10.0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: iconWidget,
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _handleTap,
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: iconWidget,
        ),
      ),
    );
  }
}
