/// File: startup_loading_view.dart
/// Description: Ultra-minimal startup progress loading view displaying solely the centered
/// Material 3 Expressive sinusoidal wavy progress bar, upward celebration stars on first-time finish,
/// and a subtle bottom-docked "project_anima" brand label in Inconsolata.
///
/// Components / Classes / Functions:
/// - StartupLoadingView: Core initialization loading view component.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/components/startup_celebration_stars.dart';
import 'package:project_anima/features/startup/components/startup_progress_bar.dart';
import 'package:project_anima/features/startup/controls/startup_controller.dart';
import 'package:project_anima/features/startup/models/startup_stage.dart';

/// Loading view displaying progress during media library scanning and artwork indexing.
/// Kept minimal: only the centered wavy progress bar and bottom subtle brand title.
class StartupLoadingView extends StatefulWidget {
  /// Current state of the startup pipeline.
  final StartupState state;

  /// Whether to celebrate with shooting stars upon completion (first-time launch only).
  final bool celebrate;

  /// Callback triggered once the celebration sequence finishes.
  final VoidCallback? onCelebrationComplete;

  const StartupLoadingView({
    super.key,
    required this.state,
    this.celebrate = false,
    this.onCelebrationComplete,
  });

  @override
  State<StartupLoadingView> createState() => _StartupLoadingViewState();
}

class _StartupLoadingViewState extends State<StartupLoadingView> {
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _checkCelebrationTrigger();
  }

  @override
  void didUpdateWidget(StartupLoadingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkCelebrationTrigger();
  }

  void _checkCelebrationTrigger() {
    if (widget.celebrate &&
        !_celebrating &&
        (widget.state.progress >= 1.0 || widget.state.stage == StartupStage.ready)) {
      setState(() {
        _celebrating = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Centered Material 3 Expressive sinusoidal wavy progress bar
          Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                StartupProgressBar(
                  progress: widget.state.progress,
                  width: 260.0,
                  height: 36.0,
                ),
                // Celebration stars shooting upward from the progress bar on first launch
                if (widget.celebrate && _celebrating)
                  Positioned(
                    top: 0,
                    child: StartupCelebrationStars(
                      onComplete: widget.onCelebrationComplete,
                    ),
                  ),
              ],
            ),
          ),

          // 2. Center-bottom subtle brand label: Qore
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'Qore',
                  style: AppFonts.segoe(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.2,
                    color: AppColors.onSurfaceDisabled.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
