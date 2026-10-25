/// File: startup_loading_screen.dart
/// Description: Initial launch screen displaying the monochromatic "PROJECT ANIMA" branding,
/// smooth stage progression ("Scanning library...", "Saving your tracks...", "Saving covers...",
/// "Finalizing setup...", "All set!"), and animated progress bar before navigating into the main app.
///
/// Components / Classes / Functions:
/// - StartupLoadingScreen: Main stateful screen coordinating startup display and seamless transition.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/controls/menu_transition_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/components/startup_header.dart';
import 'package:project_anima/features/startup/components/startup_progress_bar.dart';
import 'package:project_anima/features/startup/components/startup_status_view.dart';
import 'package:project_anima/features/startup/controllers/startup_controller.dart';
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

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    // 1. Monochromatic brand title: PROJECT ANIMA
                    const StartupHeader(),
                    const Spacer(flex: 2),
                    // 2. Expressive interpolated progress bar
                    StartupProgressBar(
                      progress: state.progress,
                      width: 250.0,
                      height: 4.0,
                    ),
                    const SizedBox(height: 20.0),
                    // 3. Status label: "Scanning...", "Saving your tracks...", "Saving covers...", etc.
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
            );
          },
        ),
      ),
    );
  }
}
