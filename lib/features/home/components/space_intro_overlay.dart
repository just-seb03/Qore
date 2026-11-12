/// File: space_intro_overlay.dart
/// Description: First-time onboarding overlay for Space screen.
/// Darkens the background, displays the native Symbols.moon_stars_rounded badge,
/// steps through three explanatory messages with fluid transitions on tap anywhere,
/// displays an animated downward bouncing cue arrow, and exits with a transformation transition.
/// Persisted in SQLite so it only appears the first time the user visits Space.
///
/// Components / Classes / Functions:
/// - SpaceIntroOverlay: Full-screen interactive onboarding tour for Space.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:project_anima/controls/navigation_controller.dart';
import 'package:project_anima/core/database/dao/app_metadata_dao.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Interactive first-time onboarding overlay presented over the Space screen.
class SpaceIntroOverlay extends StatefulWidget {
  /// Callback triggered when the intro overlay has completed its exit transition.
  final VoidCallback? onDismissed;

  /// Optional override to force showing the intro (useful for testing and previews).
  final bool? forceShow;

  const SpaceIntroOverlay({
    super.key,
    this.onDismissed,
    this.forceShow,
  });

  @override
  State<SpaceIntroOverlay> createState() => _SpaceIntroOverlayState();
}

class _SpaceIntroOverlayState extends State<SpaceIntroOverlay>
    with TickerProviderStateMixin {
  AnimationController? _fadeController;
  AnimationController? _bounceController;
  AnimationController? _exitController;

  Animation<double>? _dimAnimation;
  Animation<double>? _bounceAnimation;
  Animation<double>? _exitScaleAnimation;
  Animation<double>? _exitOpacityAnimation;

  int _step = 0;
  bool _isActive = false;
  bool _isExiting = false;
  bool _isDismissed = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  void _checkInitialState() {
    final shouldShow = widget.forceShow ?? !AppMetadataDao.instance.hasSeenSpaceIntroSync;
    if (!shouldShow) {
      _isDismissed = true;
      return;
    }

    _initControllers();

    // Check if Space is already active
    if (NavigationController.instance.currentIndex == 0) {
      _startIntro();
    } else {
      NavigationController.instance.addListener(_onNavigationChanged);
    }
  }

  void _initControllers() {
    if (_controllersInitialized) return;
    _controllersInitialized = true;

    final isTest = Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');

    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: isTest ? 10 : 450),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: isTest ? 10 : 380),
    );

    _dimAnimation = CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeOutCubic,
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _bounceController!,
        curve: Curves.easeInOutSine,
      ),
    );

    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _exitController!,
        curve: Curves.easeInOutCubic,
      ),
    );

    _exitOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController!,
        curve: Curves.easeInCubic,
      ),
    );

    if (!isTest) {
      _bounceController!.repeat(reverse: true);
    }

    _exitController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        AppMetadataDao.instance.setSpaceIntroSeen(seen: true);
        if (mounted) {
          setState(() {
            _isDismissed = true;
          });
        }
        widget.onDismissed?.call();
      }
    });
  }

  void _onNavigationChanged() {
    if (NavigationController.instance.currentIndex == 0 && !_isActive && !_isDismissed) {
      NavigationController.instance.removeListener(_onNavigationChanged);
      _startIntro();
    }
  }

  void _startIntro() {
    if (_isActive || _isDismissed) return;
    if (!_controllersInitialized) {
      _initControllers();
    }
    setState(() {
      _isActive = true;
    });
    _fadeController?.forward();
  }

  @override
  void dispose() {
    NavigationController.instance.removeListener(_onNavigationChanged);
    if (_controllersInitialized) {
      _fadeController?.dispose();
      _bounceController?.dispose();
      _exitController?.dispose();
    }
    super.dispose();
  }

  void _onTapNext() {
    if (!_isActive || _isExiting || _isDismissed || !_controllersInitialized) return;

    HapticFeedback.lightImpact();

    if (_step < 2) {
      setState(() {
        _step++;
      });
    } else {
      // Third tap: trigger smooth transformation exit
      setState(() {
        _isExiting = true;
      });
      _exitController?.forward();
      _fadeController?.reverse();
    }
  }

  Widget _buildStepText(BuildContext context) {
    final baseStyle = AppFonts.segoe(
      fontSize: 15.0,
      fontWeight: FontWeight.w500,
      height: 1.45,
      letterSpacing: 0.3,
      color: AppColors.onSurface,
    );

    switch (_step) {
      case 0:
        return Text(
          context.l10n.home.spaceIntroWelcome,
          key: const ValueKey('space_intro_text_step_0'),
          textAlign: TextAlign.center,
          style: baseStyle,
        );
      case 1:
        final isEs = Localizations.localeOf(context).languageCode == 'es';
        return Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              TextSpan(
                text: isEs
                    ? 'Aquí todo el contenido que tengas guardado con un '
                    : 'Here, all content you have saved with a ',
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 19.0,
                    color: AppColors.accent,
                  ),
                ),
              ),
              TextSpan(
                text: isEs ? 'aparecerá anclado' : 'will appear pinned',
              ),
            ],
          ),
          key: const ValueKey('space_intro_text_step_1'),
          textAlign: TextAlign.center,
        );
      case 2:
      default:
        return Text(
          context.l10n.home.spaceIntroDirectAccess,
          key: const ValueKey('space_intro_text_step_2'),
          textAlign: TextAlign.center,
          style: baseStyle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed || !_isActive || !_controllersInitialized) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_dimAnimation!, _exitOpacityAnimation!]),
      builder: (context, _) {
        final dimOpacity = (_dimAnimation!.value * _exitOpacityAnimation!.value)
            .clamp(0.0, 1.0);

        if (!_isActive || dimOpacity <= 0.0) {
          return const SizedBox.shrink();
        }

        final isDark = ThemeController.instance.isDarkMode;
        final overlayColor = (isDark ? Colors.black : Colors.white)
            .withValues(alpha: 0.88 * dimOpacity);

        return Positioned.fill(
          child: GestureDetector(
            key: const ValueKey('space_intro_tap_target'),
            behavior: HitTestBehavior.opaque,
            onTap: _onTapNext,
            child: Container(
              color: overlayColor,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: ScaleTransition(
                    scale: _exitScaleAnimation!,
                    child: FadeTransition(
                      opacity: _exitOpacityAnimation!,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 3),

                          // 1. Native Moon Stars Icon Badge in elevated rounded container
                          Center(
                            child: Container(
                              width: 72.0,
                              height: 72.0,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh.withValues(alpha: isDark ? 0.60 : 0.85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.outline.withValues(alpha: 0.45),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                                    blurRadius: 18.0,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Symbols.moon_stars_rounded,
                                size: 34.0,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24.0),

                          // 2. Staged Explanatory Text with Animated Switcher Transition
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              transitionBuilder: (child, animation) {
                                final slide = Tween<Offset>(
                                  begin: const Offset(0.0, 0.20),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                );
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: slide,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildStepText(context),
                            ),
                          ),
                          const SizedBox(height: 36.0),

                          // 3. Animated Downward Cue Arrow (floating bounce cue)
                          Center(
                            child: RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _bounceAnimation!,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0.0, _bounceAnimation!.value),
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 32.0,
                                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.80),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(flex: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
