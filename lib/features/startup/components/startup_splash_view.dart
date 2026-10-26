/// File: startup_splash_view.dart
/// Description: Animated brand splash view displaying "Bienvenido a Anima" with high-impact
/// Inconsolata typography, animating in from bottom to top, holding, and gracefully departing
/// upward before transitioning into the permissions onboarding menu.
///
/// Components / Classes / Functions:
/// - StartupSplashView: Stateful widget handling brand entrance, dwell, and slide/fade upward exit.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Animated splash screen showcasing "Bienvenido / A / Anima"
/// with bottom-to-top entrance and upward exit transition before the onboarding menu.
class StartupSplashView extends StatefulWidget {
  /// Callback triggered when the splash animation completes its sequence or is tapped.
  final VoidCallback onCompleted;

  /// Total duration of the splash sequence (entrance, hold, exit).
  final Duration duration;

  const StartupSplashView({
    super.key,
    required this.onCompleted,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<StartupSplashView> createState() => _StartupSplashViewState();
}

class _StartupSplashViewState extends State<StartupSplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeInAnimation;
  late final Animation<Offset> _slideInAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeOutAnimation;
  late final Animation<Offset> _slideOutAnimation;
  bool _completedCalled = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 1. Entrance phase: 0.0 -> 0.38 (slide from bottom to center + fade in)
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    _slideInAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.40),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Exit phase: 0.68 -> 1.0 (depart smoothly upward + fade out)
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.68, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.40),
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.68, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerCompleted();
      }
    });

    _animController.forward();
  }

  void _triggerCompleted() {
    if (_completedCalled) return;
    _completedCalled = true;
    widget.onCompleted();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.startup;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _triggerCompleted,
      child: Align(
        alignment: const Alignment(0.0, -0.16),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            final double currentOpacity =
                (_fadeInAnimation.value * _fadeOutAnimation.value).clamp(0.0, 1.0);
            final double currentScale = _scaleAnimation.value;
            final Offset currentSlide =
                _slideInAnimation.value + _slideOutAnimation.value;

            return Opacity(
              opacity: currentOpacity,
              child: Transform.translate(
                offset: Offset(0.0, currentSlide.dy * 120),
                child: Transform.scale(
                  scale: currentScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Line 1: Bienvenido
                      Text(
                        l10n.welcomeLine1,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inconsolata(
                          fontSize: 24.0,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 4.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      // Line 2: A
                      Text(
                        l10n.welcomeLine2,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inconsolata(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3.5,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      // Line 3: Anima (larger than the rest, at bottom)
                      Text(
                        l10n.welcomeLine3,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inconsolata(
                          fontSize: 48.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6.0,
                          color: AppColors.futuristicWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
