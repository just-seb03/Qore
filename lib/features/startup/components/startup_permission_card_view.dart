/// File: startup_permission_card_view.dart
/// Description: Full-screen staged permission onboarding view presented directly on the background
/// (without bounding card containers) with top-to-bottom layout: centered icon badge, explanatory prompt,
/// animated < 1 > / < 2 > indicators, bottom-docked Next button, screen dimming during system requests,
/// and in-place monochrome alert handling on denial.
///
/// Components / Classes / Functions:
/// - StartupPermissionCardView: Full-screen staged permission onboarding widget.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Full-screen staged onboarding view guiding the user through audio and notification
/// permissions with content directly on the background and bottom-docked navigation action.
class StartupPermissionCardView extends StatefulWidget {
  /// Callback triggered when user accepts and requests device permissions.
  final FutureOr<dynamic> Function() onRequestPermissions;

  /// Optional initial sub-step page (1 or 2). Defaults to 1.
  final int initialPage;

  /// Optional initial denied state override. Defaults to false.
  final bool initialDenied;

  /// External forced denied state from parent controller.
  final bool? isDenied;

  const StartupPermissionCardView({
    super.key,
    required this.onRequestPermissions,
    this.initialPage = 1,
    this.initialDenied = false,
    this.isDenied,
  });

  @override
  State<StartupPermissionCardView> createState() => _StartupPermissionCardViewState();
}

class _StartupPermissionCardViewState extends State<StartupPermissionCardView>
    with SingleTickerProviderStateMixin {
  late int _page;
  late bool _isDenied;
  bool _isDarkened = false;

  late final AnimationController _indicatorController;
  late final Animation<double> _chevronOffsetAnimation;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _isDenied = widget.isDenied ?? widget.initialDenied;

    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _chevronOffsetAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _indicatorController,
        curve: Curves.easeInOutSine,
      ),
    );

    final isTest = Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _indicatorController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant StartupPermissionCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDenied != null && widget.isDenied != _isDenied) {
      setState(() {
        _isDenied = widget.isDenied!;
      });
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_page == 1 && !_isDenied) {
      setState(() {
        _page = 2;
      });
      return;
    }

    // Page 2 or retrying after denial: darken screen and launch runtime permission requests
    setState(() {
      _isDarkened = true;
    });

    // Pacing delay to let screen dim smoothly
    await Future.delayed(const Duration(milliseconds: 260));

    try {
      final dynamic res = await widget.onRequestPermissions();
      if (!mounted) return;

      setState(() {
        _isDarkened = false;
        final bool granted = res is bool ? res : true;
        if (!granted) {
          _isDenied = true;
        } else {
          _isDenied = false;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDarkened = false;
        _isDenied = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.startup;

    // Resolve active icon, badge border, and text based on current sub-step & denial state
    final IconData activeIcon;
    final String activeText;
    final String activeKeyId;

    if (_isDenied) {
      activeIcon = Icons.warning_amber_rounded;
      activeText = l10n.permissionDeniedPrompt;
      activeKeyId = 'permission_denied_state';
    } else if (_page == 1) {
      activeIcon = Icons.music_note_rounded;
      activeText = l10n.musicAccessPrompt;
      activeKeyId = 'permission_page_1';
    } else {
      activeIcon = Icons.notifications_active_rounded;
      activeText = l10n.notificationAccessPrompt;
      activeKeyId = 'permission_page_2';
    }

    return Stack(
      children: [
        // Content laid out directly on the background (no bounding box)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top spacing: flex 3 places the icon slightly above vertical center
                const Spacer(flex: 3),

                // 1. Icon Badge (Music, Notification, or Monochrome Alert)
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Container(
                      key: ValueKey('icon_badge_$activeKeyId'),
                      width: 72.0,
                      height: 72.0,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isDenied
                              ? AppColors.futuristicWhite.withValues(alpha: 0.7)
                              : AppColors.outline.withValues(alpha: 0.45),
                          width: _isDenied ? 1.5 : 1.0,
                        ),
                      ),
                      child: Icon(
                        activeIcon,
                        size: 34.0,
                        color: AppColors.futuristicWhite,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                // 2. Explanatory / Error Text directly on background
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Text(
                      activeText,
                      key: ValueKey('text_$activeKeyId'),
                      textAlign: TextAlign.center,
                      style: AppFonts.segoe(
                        fontSize: 14.5,
                        fontWeight: _isDenied ? FontWeight.w500 : FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 0.4,
                        color: _isDenied
                            ? AppColors.futuristicWhite
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28.0),

                // 3. Animated Indicator < 1 > or < 2 > (Hidden on Denied state)
                if (!_isDenied) ...[
                  Semantics(
                    label: '< $_page >',
                    child: AnimatedBuilder(
                      animation: _chevronOffsetAnimation,
                      builder: (context, _) {
                        final offset = _chevronOffsetAnimation.value;
                        return Row(
                          key: ValueKey('startup_indicator_page_$_page'),
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: Offset(-offset, 0),
                              child: Text(
                                '<',
                                style: AppFonts.segoe(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(opacity: anim, child: child),
                              child: Text(
                                '$_page',
                                key: ValueKey('page_number_$_page'),
                                style: AppFonts.segoe(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.futuristicWhite,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Transform.translate(
                              offset: Offset(offset, 0),
                              child: Text(
                                '>',
                                style: AppFonts.segoe(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],

                // Bottom spacing: flex 4 pushes the Next button to the bottom of the screen
                const Spacer(flex: 4),

                // 4. Action Button docked at the bottom of the screen
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey('startup_permissions_next_button'),
                    onTap: _isDarkened ? null : _handleNext,
                    borderRadius: BorderRadius.zero,
                    child: Ink(
                      height: 50.0,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Center(
                        child: Text(
                          l10n.nextAction,
                          style: AppFonts.segoe(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                            color: AppColors.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 5. Screen Darkening Scrim while permission dialogs are requested
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_isDarkened,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              color: _isDarkened
                  ? Colors.black.withValues(alpha: 0.72)
                  : Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
