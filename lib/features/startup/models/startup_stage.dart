/// File: startup_stage.dart
/// Description: State enumerations and descriptors representing the sequential stages
/// of the application startup, device scanning, and asset indexing lifecycle.
///
/// Components / Classes / Functions:
/// - StartupStage: Enum representing distinct initialization milestones.
/// - StartupStageX: Extension providing localized English titles and progress metrics.
library;

import 'package:flutter/widgets.dart';
import 'package:project_anima/core/localization/app_localizations.dart';

/// Distinct operational stages of the startup initialization sequence.
enum StartupStage {
  /// Initial silent permission inspection before rendering UI.
  checkingPermission,

  /// Permissions missing or declined; renders explicit permission request view.
  permissionDenied,

  /// Initial device filesystem and MediaStore projection scanning.
  scanning,

  /// Deep audio tag parsing and delta synchronization to SQLite.
  savingTracks,

  /// Album artwork extraction and dual-tier thumbnail caching.
  savingCovers,

  /// Pre-warming Today Selection, DAOs, and UI component states.
  finalizing,

  /// All systems initialized and primed; ready to transition to the main interface.
  ready,
}

/// Helper extension providing formatted user-facing English titles.
extension StartupStageX on StartupStage {
  /// English display label matching the user specification.
  String get label {
    switch (this) {
      case StartupStage.checkingPermission:
      case StartupStage.permissionDenied:
        return '';
      case StartupStage.scanning:
        return 'Scanning library...';
      case StartupStage.savingTracks:
        return 'Saving your tracks...';
      case StartupStage.savingCovers:
        return 'Saving covers...';
      case StartupStage.finalizing:
        return 'Finalizing setup...';
      case StartupStage.ready:
        return 'All set!';
    }
  }

  /// Context-aware localized label.
  String localizedLabel(BuildContext context) {
    switch (this) {
      case StartupStage.checkingPermission:
      case StartupStage.permissionDenied:
        return '';
      case StartupStage.scanning:
        return context.l10n.startup.scanningLibrary;
      case StartupStage.savingTracks:
        return context.l10n.startup.savingTracks;
      case StartupStage.savingCovers:
        return context.l10n.startup.savingCovers;
      case StartupStage.finalizing:
        return context.l10n.startup.finalizingSetup;
      case StartupStage.ready:
        return context.l10n.startup.allSet;
    }
  }

  /// Normalized base progress threshold for this stage [0.0 - 1.0].
  double get baseProgress {
    switch (this) {
      case StartupStage.checkingPermission:
      case StartupStage.permissionDenied:
        return 0.0;
      case StartupStage.scanning:
        return 0.15;
      case StartupStage.savingTracks:
        return 0.45;
      case StartupStage.savingCovers:
        return 0.75;
      case StartupStage.finalizing:
        return 0.95;
      case StartupStage.ready:
        return 1.0;
    }
  }
}
