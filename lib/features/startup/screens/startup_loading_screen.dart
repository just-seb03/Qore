/// File: startup_loading_screen.dart
/// Description: Initial launch screen coordinating the modern 4-step startup onboarding experience:
/// 1. Animated brand splash ("PROJECT ANIMA" with graceful exit)
/// 2. Permissions request card (Audio files & notification access with action trigger)
/// 3. Theme selector preview (Centered slightly above Y-axis, "Monochrome" title, 5 constituent color circles, accept button)
/// 4. Dynamic library loading sequence (Wavy progress bar & status labels)
/// followed by seamless transition into the primary application interface.
///
/// Components / Classes / Functions:
/// - StartupLoadingScreen: Main stateful orchestrator switching smoothly across startup steps.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/controls/menu_transition_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/components/startup_loading_view.dart';
import 'package:project_anima/features/startup/components/startup_permission_card_view.dart';
import 'package:project_anima/features/startup/components/startup_permission_view.dart';
import 'package:project_anima/features/startup/components/startup_splash_view.dart';
import 'package:project_anima/features/startup/components/startup_theme_selector_view.dart';
import 'package:project_anima/features/startup/controls/startup_controller.dart';
import 'package:project_anima/features/startup/models/startup_stage.dart';
import 'package:project_anima/features/startup/models/startup_step.dart';

/// The entry screen mounted on app initialization to guide the user through
/// branding, permission grant, theme confirmation, and audio library indexing.
class StartupLoadingScreen extends StatefulWidget {
  /// Optional injected controller for testing or custom orchestration.
  final StartupController? controller;

  /// Optional target screen destination upon completion. Defaults to [MenuTransitionControl].
  final Widget? destinationScreen;

  /// Optional initial step override (defaults to [StartupStep.splash]).
  final StartupStep? initialStep;

  const StartupLoadingScreen({
    super.key,
    this.controller,
    this.destinationScreen,
    this.initialStep,
  });

  @override
  State<StartupLoadingScreen> createState() => _StartupLoadingScreenState();
}

class _StartupLoadingScreenState extends State<StartupLoadingScreen> {
  late final StartupController _controller;
  bool _internalController = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _internalController = false;
    } else {
      _controller = StartupController();
      _internalController = true;
    }

    if (widget.initialStep != null) {
      _controller.goToStep(widget.initialStep!);
    }

    _controller.addListener(_onControllerStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerStateChanged() {
    if (_controller.state.stage == StartupStage.ready && !_hasNavigated && mounted) {
      _hasNavigated = true;
      // Brief aesthetic pause to celebrate completion
      Future.delayed(const Duration(milliseconds: 380), () {
        if (!mounted) return;
        final target = widget.destinationScreen ?? const MenuTransitionControl();
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) => target,
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: child,
              );
            },
          ),
        );
      });
    }
  }

  Widget _buildStepWidget(BuildContext context, StartupState state) {
    // If runtime permission was denied in legacy retry flow, show dedicated permission view
    if (state.stage == StartupStage.permissionDenied) {
      return StartupPermissionView(
        key: const ValueKey('startup_permission_denied_view'),
        onRequestPermission: _controller.requestPermissionAndRetry,
      );
    }

    switch (state.step) {
      case StartupStep.splash:
        return StartupSplashView(
          key: const ValueKey('startup_splash_view'),
          onCompleted: _controller.proceedFromSplash,
        );

      case StartupStep.permissions:
        return StartupPermissionCardView(
          key: const ValueKey('startup_permission_card_view'),
          onRequestPermissions: _controller.requestPermissionsAndProceed,
        );

      case StartupStep.themeSelector:
        return StartupThemeSelectorView(
          key: const ValueKey('startup_theme_selector_view'),
          onAccept: _controller.acceptThemeAndStartScanning,
        );

      case StartupStep.loading:
        return StartupLoadingView(
          key: const ValueKey('startup_loading_view'),
          state: state,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final state = _controller.state;

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.04),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: _buildStepWidget(context, state),
            );
          },
        ),
      ),
    );
  }
}
