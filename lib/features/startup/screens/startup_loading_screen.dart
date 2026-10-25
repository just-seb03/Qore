/// File: startup_loading_screen.dart
/// Description: Initial launch screen coordinating silent permission evaluation,
/// permission request view if missing, and fluid Material 3 Expressive wavy progress sequence
/// ("Scanning library...", "Saving your tracks...", "Saving covers...", "Finalizing setup...", "All set!")
/// before transitioning into the main application.
///
/// Components / Classes / Functions:
/// - StartupLoadingScreen: Main stateful screen coordinating permission gate, startup progress, and navigation.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/controls/menu_transition_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/components/startup_header.dart';
import 'package:project_anima/features/startup/components/startup_permission_view.dart';
import 'package:project_anima/features/startup/components/startup_progress_bar.dart';
import 'package:project_anima/features/startup/components/startup_status_view.dart';
import 'package:project_anima/features/startup/controls/startup_controller.dart';
import 'package:project_anima/features/startup/models/startup_stage.dart';

/// The entry screen mounted on app initialization to index audio and extract covers.
class StartupLoadingScreen extends StatefulWidget {
  /// Optional injected controller for testing.
  final StartupController? controller;

  /// Optional target screen destination upon completion. Defaults to [MenuTransitionControl].
  final Widget? destinationScreen;

  const StartupLoadingScreen({
    super.key,
    this.controller,
    this.destinationScreen,
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

    _controller.addListener(_onControllerStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.start();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final state = _controller.state;

            // 1. Initial silent check: render blank background to prevent layout flashes
            if (state.stage == StartupStage.checkingPermission) {
              return const SizedBox.expand();
            }

            // 2. Permission denied / required: render dedicated permission view
            if (state.stage == StartupStage.permissionDenied) {
              return StartupPermissionView(
                onRequestPermission: _controller.requestPermissionAndRetry,
              );
            }

            // 3. Active scanning & indexing: render brand header and M3 Expressive wavy progress bar
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Center(
                key: const ValueKey('active_startup_content'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      // Brand title: PROJECT ANIMA in Inconsolata
                      const StartupHeader(),
                      const Spacer(flex: 2),
                      // Material 3 Expressive sinusoidal wavy progress bar
                      StartupProgressBar(
                        progress: state.progress,
                        width: 260.0,
                        height: 36.0,
                      ),
                      const SizedBox(height: 16.0),
                      // Status label: "Scanning...", "Saving your tracks...", "Saving covers...", etc.
                      StartupStatusView(
                        stage: state.stage,
                        statusText: state.statusText,
                        progress: state.progress,
                        totalSongs: state.totalSongs,
                      ),
                      const Spacer(flex: 3),
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
