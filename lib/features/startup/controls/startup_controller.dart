/// File: startup_controller.dart
/// Description: Business logic control coordinating the application startup lifecycle,
/// permission gates, audio indexing, cover art extraction, component pre-warming,
/// and smooth progress state transitions following senior optimization and low-coupling principles.
///
/// Components / Classes / Functions:
/// - StartupState: Immutable state data class representing startup progression.
/// - StartupController: ChangeNotifier orchestrating the startup pipeline.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/app_metadata_dao.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/permissions/audio_permission_service.dart';
import 'package:project_anima/core/scanner/music_indexer.dart';
import 'package:project_anima/core/selection/today_selection_service.dart';
import 'package:project_anima/features/startup/models/startup_stage.dart';
import 'package:project_anima/features/startup/models/startup_step.dart';

/// Immutable state holding the active startup stage and visual progress.
@immutable
class StartupState {
  /// Active user-facing onboarding and initialization step.
  final StartupStep step;

  /// Active operational stage.
  final StartupStage stage;

  /// Progress fraction clamped to [0.0, 1.0].
  final double progress;

  /// User-facing status string displayed beneath the brand title.
  final String statusText;

  /// Total count of songs discovered, or null during scanning.
  final int? totalSongs;

  const StartupState({
    this.step = StartupStep.splash,
    required this.stage,
    required this.progress,
    required this.statusText,
    this.totalSongs,
  });

  /// Factory constructing initial blank state before permission check.
  factory StartupState.initial() {
    return const StartupState(
      step: StartupStep.splash,
      stage: StartupStage.checkingPermission,
      progress: 0.0,
      statusText: '',
    );
  }

  /// Creates a copy of this state with modified values.
  StartupState copyWith({
    StartupStep? step,
    StartupStage? stage,
    double? progress,
    String? statusText,
    int? totalSongs,
  }) {
    return StartupState(
      step: step ?? this.step,
      stage: stage ?? this.stage,
      progress: progress != null ? progress.clamp(0.0, 1.0) : this.progress,
      statusText: statusText ?? this.statusText,
      totalSongs: totalSongs ?? this.totalSongs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StartupState &&
        other.step == step &&
        other.stage == stage &&
        (other.progress - progress).abs() < 0.001 &&
        other.statusText == statusText &&
        other.totalSongs == totalSongs;
  }

  @override
  int get hashCode => Object.hash(step, stage, progress, statusText, totalSongs);
}

/// Orchestrator of the application startup lifecycle and permission gate.
class StartupController extends ChangeNotifier {
  final AudioPermissionService _permissionService;
  final MusicIndexer _musicIndexer;
  final ArtworkService _artworkService;
  final TodaySelectionService _todaySelectionService;
  final AppMetadataDao _appMetadataDao;

  StartupController({
    AudioPermissionService? permissionService,
    MusicIndexer? musicIndexer,
    ArtworkService? artworkService,
    TodaySelectionService? todaySelectionService,
    AppMetadataDao? appMetadataDao,
  })  : _permissionService = permissionService ?? AudioPermissionService.instance,
        _musicIndexer = musicIndexer ?? MusicIndexer.instance,
        _artworkService = artworkService ?? ArtworkService.instance,
        _todaySelectionService = todaySelectionService ?? TodaySelectionService.instance,
        _appMetadataDao = appMetadataDao ?? AppMetadataDao.instance {
    if (_appMetadataDao.isOnboardingCompletedSync) {
      _isFirstLaunch = false;
      _state = _state.copyWith(step: StartupStep.loading);
    }
  }

  StartupState _state = StartupState.initial();
  bool _hasStarted = false;
  bool _disposed = false;
  bool _isFirstLaunch = true;

  /// Current immutable startup state.
  StartupState get state => _state;

  /// Active user-facing onboarding and initialization step.
  StartupStep get currentStep => _state.step;

  /// AppMetadataDao for persistence checks.
  AppMetadataDao get appMetadataDao => _appMetadataDao;

  /// Whether this is the first time the app is launched (triggers full onboarding and celebration stars).
  bool get isFirstLaunch => _isFirstLaunch;

  /// Explicitly sets first-time launch state (for testing or overrides).
  void setFirstLaunch(bool value) {
    _isFirstLaunch = value;
  }

  /// Whether the entire startup pipeline has completed and is ready for transition.
  bool get isReady => _state.stage == StartupStage.ready;

  /// Whether permissions are currently denied and requiring user interaction.
  bool get isPermissionDenied => _state.stage == StartupStage.permissionDenied;

  /// Whether permissions have been granted and active scanning/indexing is in progress.
  bool get isContentVisible =>
      _state.stage != StartupStage.checkingPermission &&
      _state.stage != StartupStage.permissionDenied;

  void _emit(StartupState newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
  }

  /// Checks whether first-time onboarding was completed.
  /// If completed, skips splash/permissions/theme and immediately starts scanning.
  Future<void> checkOnboardingAndInitialize() async {
    final completed = await _appMetadataDao.isOnboardingCompleted();
    _isFirstLaunch = !completed;
    if (completed) {
      _emit(_state.copyWith(
        step: StartupStep.loading,
        stage: StartupStage.scanning,
        progress: 0.12,
        statusText: StartupStage.scanning.label,
      ));
      await _runScanningAndIndexingSequence();
    }
  }

  /// Explicitly starts background scanning sequence.
  Future<void> startScanningSequence() async {
    _emit(_state.copyWith(
      step: StartupStep.loading,
      stage: StartupStage.scanning,
      progress: 0.12,
      statusText: StartupStage.scanning.label,
    ));
    await _runScanningAndIndexingSequence();
  }

  /// Marks onboarding as permanently completed in SQLite app_metadata.
  Future<void> markOnboardingCompleted() async {
    _isFirstLaunch = false;
    await _appMetadataDao.setOnboardingCompleted(completed: true);
  }

  /// Advances from the splash screen to the permissions request step.
  void proceedFromSplash() {
    _emit(_state.copyWith(step: StartupStep.permissions));
  }

  /// Requests runtime permissions (audio access & notification) and initiates scanning if granted.
  /// Returns `true` if all required permissions are granted, or `false` if denied.
  Future<bool> requestPermissionsAndProceed() async {
    bool audioGranted = false;
    bool notificationGranted = true;

    try {
      final audioStatus = await _permissionService.requestPermission();
      audioGranted = audioStatus.isGranted;

      final isTest = Platform.environment.containsKey('FLUTTER_TEST');
      if (!isTest && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final notifStatus = await Permission.notification.request();
          notificationGranted = notifStatus.isGranted;
        } catch (e) {
          debugPrint('⚠️ [StartupController] Notification permission request error: $e');
          notificationGranted = true;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [StartupController] Error requesting permissions: $e');
      audioGranted = false;
    }

    final bool allGranted = audioGranted && notificationGranted;
    if (allGranted) {
      _emit(_state.copyWith(
        step: StartupStep.loading,
        stage: StartupStage.scanning,
        progress: 0.12,
        statusText: StartupStage.scanning.label,
      ));
      await _runScanningAndIndexingSequence();
      return true;
    } else {
      return false;
    }
  }

  /// Explicitly navigates to a target startup step (useful for tests and programmatic flow).
  void goToStep(StartupStep step) {
    _emit(_state.copyWith(step: step));
  }

  /// Initiates the initial permission gate and startup pipeline.
  Future<void> start() async {
    if (_hasStarted) return;
    _hasStarted = true;

    try {
      // 1. Initial silent permission check
      final hasPerm = await _permissionService.hasPermission();
      if (!hasPerm) {
        final status = await _permissionService.requestPermission();
        if (!status.isGranted) {
          _emit(_state.copyWith(
            step: StartupStep.permissions,
            stage: StartupStage.permissionDenied,
            progress: 0.0,
            statusText: '',
          ));
          return;
        }
      }

      // Permission granted: start sequence
      _emit(_state.copyWith(step: StartupStep.loading));
      await _runScanningAndIndexingSequence();
    } catch (e, stack) {
      debugPrint('⚠️ [StartupController] Permission initialization error: $e\n$stack');
      _emit(_state.copyWith(
        step: StartupStep.permissions,
        stage: StartupStage.permissionDenied,
        progress: 0.0,
      ));
    }
  }

  /// Retries requesting permission when user taps action button on denied view.
  Future<void> requestPermissionAndRetry() async {
    try {
      final currentStatus = await _permissionService.checkPermissionStatus();
      if (currentStatus == AudioPermissionState.permanentlyDenied) {
        await _permissionService.openSettings();
        return;
      }

      final status = await _permissionService.requestPermission();
      if (status.isGranted) {
        _emit(_state.copyWith(step: StartupStep.loading));
        await _runScanningAndIndexingSequence();
      } else {
        _emit(_state.copyWith(
          step: StartupStep.permissions,
          stage: StartupStage.permissionDenied,
          progress: 0.0,
        ));
      }
    } catch (e) {
      debugPrint('⚠️ [StartupController] Error retrying permission request: $e');
    }
  }

  /// Executes scanning, metadata indexing, cover extraction, and component warm-up.
  Future<void> _runScanningAndIndexingSequence() async {
    try {
      // 1. Stage: Scanning library
      _emit(_state.copyWith(
        stage: StartupStage.scanning,
        progress: 0.12,
        statusText: StartupStage.scanning.label,
      ));

      _emit(_state.copyWith(progress: 0.22));

      // 2. Stage: Saving your tracks (MediaStore lightweight projection & isolated parsing)
      final indexResult = await _musicIndexer.syncWithDevice(
        onProgress: (phase, current, total) {
          if (phase == 'saving_tracks') {
            final double subProgress = total > 0 ? (current / total) : 0.5;
            _emit(_state.copyWith(
              stage: StartupStage.savingTracks,
              progress: 0.25 + (subProgress * 0.30),
              statusText: StartupStage.savingTracks.label,
            ));
          }
        },
      );

      final totalSongs = indexResult.totalSongs;

      // Small pacing pause for smooth aesthetic transition
      await Future.delayed(const Duration(milliseconds: 120));

      // 3. Stage: Saving covers (Background isolate artwork extraction)
      _emit(_state.copyWith(
        stage: StartupStage.savingCovers,
        progress: 0.58,
        statusText: StartupStage.savingCovers.label,
        totalSongs: totalSongs,
      ));

      await _artworkService.waitForQueueCompletion(
        timeout: const Duration(seconds: 4),
        onProgress: (processed, total) {
          final double ratio = total > 0 ? (processed / total) : 1.0;
          _emit(_state.copyWith(
            progress: 0.58 + (ratio * 0.27),
          ));
        },
      );

      // 4. Stage: Finalizing setup (Component warm-up & Today Selection caching)
      _emit(_state.copyWith(
        stage: StartupStage.finalizing,
        progress: 0.88,
        statusText: StartupStage.finalizing.label,
      ));

      // Pre-warm Today Selection so HomeScreen renders immediately with zero pop-in
      try {
        await _todaySelectionService.getTodaySelection();
      } catch (e) {
        debugPrint('⚠️ [StartupController] TodaySelection pre-warm warning: $e');
      }

      // Pre-warm Favorite Songs cache so favorite badges render immediately
      try {
        await FavoriteSongsDao.instance.ensureLoaded();
      } catch (e) {
        debugPrint('⚠️ [StartupController] FavoriteSongsDao pre-warm warning: $e');
      }

      // Pre-warm Space pinned items & prioritize any pending Space covers
      try {
        final pinnedItems = await PinnedFavoritesDao.instance.getAllPinned();
        final spaceSongIds = pinnedItems
            .map((e) => e.representativeSongId)
            .whereType<int>()
            .where((id) => id > 0)
            .toList();
        if (spaceSongIds.isNotEmpty) {
          _artworkService.prioritizeSongIds(spaceSongIds);
        }
      } catch (e) {
        debugPrint('⚠️ [StartupController] PinnedFavoritesDao pre-warm warning: $e');
      }

      _emit(_state.copyWith(progress: 0.96));

      // Small pacing pause to let GPU pipeline settle
      await Future.delayed(const Duration(milliseconds: 180));

      // 5. Stage: Ready / All set!
      _emit(_state.copyWith(
        stage: StartupStage.ready,
        progress: 1.0,
        statusText: StartupStage.ready.label,
      ));
    } catch (e, stack) {
      debugPrint('⚠️ [StartupController] Startup sequence recovered from error: $e\n$stack');
      _emit(_state.copyWith(
        stage: StartupStage.ready,
        progress: 1.0,
        statusText: StartupStage.ready.label,
      ));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
