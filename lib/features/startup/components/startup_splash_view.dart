/// File: startup_splash_view.dart
/// Description: Animated brand splash view displaying "PROJECT ANIMA" with high-impact
/// typography, smooth entry, dwell, and dynamic exit transition before proceeding to permissions.
///
/// Components / Classes / Functions:
/// - StartupSplashView: Stateful widget handling brand fade-in, dwell, and slide/fade exit.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Animated splash screen showcasing the "PROJECT ANIMA" brand title
/// before gracefully transitioning out into the onboarding sequence.
class StartupSplashView extends StatefulWidget {
  /// Callback triggered when the splash animation completes its sequence or is tapped.
  final VoidCallback onCompleted;

  /// Total duration of the splash sequence (entrance, hold, exit).
  final Duration duration;

  const StartupSplashView({
    super.key,
    required this.onCompleted,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<StartupSplashView> createState() => _StartupSplashViewState();
}

class _StartupSplashViewState extends State<StartupSplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeInAnimation;
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

    // Entrance phase: 0.0 -> 0.35
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    // Exit phase: 0.65 -> 1.0 ("como se va")
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.18),
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeInOutCubic),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _triggerCompleted,
      child: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            final double currentOpacity = _fadeInAnimation.value * _fadeOutAnimation.value;
            final double currentScale = _scaleAnimation.value;
            final Offset currentSlide = _slideOutAnimation.value;

            return Opacity(
              opacity: currentOpacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0.0, currentSlide.dy * 100),
                child: Transform.scale(
                  scale: currentScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minimalist branding line
                      Container(
                        width: 36.0,
                        height: 3.0,
                        decoration: BoxDecoration(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      // Core brand name in high-impact Inconsolata
                      Text(
                        context.l10n.startup.appTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inconsolata(
                          fontSize: 26.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 5.0,
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
