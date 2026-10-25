/// File: startup_loading_view.dart
/// Description: Standard startup progress loading view displaying the brand header,
/// Material 3 Expressive sinusoidal wavy progress bar, and real-time status labels.
///
/// Components / Classes / Functions:
/// - StartupLoadingView: Core initialization loading view component.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/features/startup/components/startup_header.dart';
import 'package:project_anima/features/startup/components/startup_progress_bar.dart';
import 'package:project_anima/features/startup/components/startup_status_view.dart';
import 'package:project_anima/features/startup/controls/startup_controller.dart';

/// Loading view displaying progress during media library scanning and artwork indexing.
class StartupLoadingView extends StatelessWidget {
  /// Current state of the startup pipeline.
  final StartupState state;

  const StartupLoadingView({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
