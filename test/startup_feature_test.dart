/// File: startup_feature_test.dart
/// Description: Unit and Widget tests verifying the Startup sequence, permission gate,
/// M3 Expressive wavy progress bar, Inconsolata labels, and screen transition.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/core/permissions/audio_permission_service.dart';
import 'package:project_anima/core/scanner/models/indexing_result.dart';
import 'package:project_anima/core/scanner/music_indexer.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/components/startup_header.dart';
import 'package:project_anima/features/startup/components/startup_permission_view.dart';
import 'package:project_anima/features/startup/components/startup_progress_bar.dart';
import 'package:project_anima/features/startup/components/startup_status_view.dart';
import 'package:project_anima/features/startup/controls/startup_controller.dart';
import 'package:project_anima/features/startup/models/startup_stage.dart';
import 'package:project_anima/features/startup/screens/startup_loading_screen.dart';

class _FakePermissionService implements AudioPermissionService {
  bool permissionGranted = true;
  AudioPermissionState currentState = AudioPermissionState.granted;

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<AudioPermissionState> checkPermissionStatus() async => currentState;

  @override
  Future<AudioPermissionState> requestPermission() async {
    return permissionGranted
        ? AudioPermissionState.granted
        : AudioPermissionState.denied;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMusicIndexer implements MusicIndexer {
  @override
  Future<IndexingResult> syncWithDevice({
    List<dynamic>? mockDeviceItems,
    void Function(String phase, int current, int total)? onProgress,
  }) async {
    onProgress?.call('scanning', 10, 10);
    onProgress?.call('saving_tracks', 5, 10);
    onProgress?.call('saving_tracks', 10, 10);
    onProgress?.call('done', 10, 10);
    return const IndexingResult(
      totalSongs: 10,
      addedCount: 10,
      updatedCount: 0,
      deletedCount: 0,
      elapsedMilliseconds: 42,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StartupStage Enum Tests', () {
    test('StartupStage returns accurate localized English labels', () {
      expect(StartupStage.scanning.label, 'Scanning library...');
      expect(StartupStage.savingTracks.label, 'Saving your tracks...');
      expect(StartupStage.savingCovers.label, 'Saving covers...');
      expect(StartupStage.finalizing.label, 'Finalizing setup...');
      expect(StartupStage.ready.label, 'All set!');
    });

    test('StartupStage baseProgress maintains strictly ascending order for active phases', () {
      expect(StartupStage.scanning.baseProgress, lessThan(StartupStage.savingTracks.baseProgress));
      expect(StartupStage.savingTracks.baseProgress, lessThan(StartupStage.savingCovers.baseProgress));
      expect(StartupStage.savingCovers.baseProgress, lessThan(StartupStage.finalizing.baseProgress));
      expect(StartupStage.finalizing.baseProgress, lessThanOrEqualTo(StartupStage.ready.baseProgress));
    });
  });

  group('StartupController Progression Tests', () {
    test('StartupController transitions through all stages to ready when permission granted', () async {
      final fakePerm = _FakePermissionService();
      final fakeIndexer = _FakeMusicIndexer();

      final controller = StartupController(
        permissionService: fakePerm,
        musicIndexer: fakeIndexer,
      );

      expect(controller.state.stage, StartupStage.checkingPermission);
      expect(controller.isReady, isFalse);

      final stagesRecorded = <StartupStage>[];
      controller.addListener(() {
        if (!stagesRecorded.contains(controller.state.stage)) {
          stagesRecorded.add(controller.state.stage);
        }
      });

      await controller.start();

      expect(controller.isReady, isTrue);
      expect(controller.state.stage, StartupStage.ready);
      expect(controller.state.progress, 1.0);
      expect(controller.state.statusText, 'All set!');
      expect(stagesRecorded, containsAll([
        StartupStage.scanning,
        StartupStage.savingTracks,
        StartupStage.savingCovers,
        StartupStage.finalizing,
        StartupStage.ready,
      ]));

      controller.dispose();
    });

    test('StartupController enters permissionDenied stage when permission is rejected', () async {
      final fakePerm = _FakePermissionService()
        ..permissionGranted = false
        ..currentState = AudioPermissionState.denied;
      final fakeIndexer = _FakeMusicIndexer();

      final controller = StartupController(
        permissionService: fakePerm,
        musicIndexer: fakeIndexer,
      );

      await controller.start();

      expect(controller.isPermissionDenied, isTrue);
      expect(controller.state.stage, StartupStage.permissionDenied);
      expect(controller.isContentVisible, isFalse);

      // Now grant permission and retry
      fakePerm.permissionGranted = true;
      fakePerm.currentState = AudioPermissionState.granted;

      await controller.requestPermissionAndRetry();

      expect(controller.isReady, isTrue);
      expect(controller.state.stage, StartupStage.ready);

      controller.dispose();
    });
  });

  group('Startup UI Components Tests', () {
    testWidgets('StartupHeader renders PROJECT ANIMA without subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: StartupHeader(),
          ),
        ),
      );

      expect(find.text('PROJECT ANIMA'), findsOneWidget);
      expect(find.text('HIGH FIDELITY AUDIO'), findsNothing);
    });

    testWidgets('StartupProgressBar renders with M3 Expressive CustomPaint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: StartupProgressBar(
              progress: 0.65,
              width: 260.0,
            ),
          ),
        ),
      );

      expect(find.byType(StartupProgressBar), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('StartupPermissionView renders icon, text, and button in Inconsolata', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: StartupPermissionView(
              onRequestPermission: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
      expect(find.text('AUDIO ACCESS REQUIRED'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      await tester.tap(find.text('CONTINUE'));
      expect(tapped, isTrue);
    });

    testWidgets('StartupStatusView renders stage text and percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: StartupStatusView(
              stage: StartupStage.savingTracks,
              statusText: 'Saving your tracks...',
              progress: 0.50,
            ),
          ),
        ),
      );

      expect(find.text('Saving your tracks...'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('StartupLoadingScreen renders permission view when denied and navigates on ready', (tester) async {
      final fakePerm = _FakePermissionService()
        ..permissionGranted = false
        ..currentState = AudioPermissionState.denied;
      final fakeIndexer = _FakeMusicIndexer();

      final controller = StartupController(
        permissionService: fakePerm,
        musicIndexer: fakeIndexer,
      );

      const destinationKey = Key('destination_screen');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: StartupLoadingScreen(
            controller: controller,
            destinationScreen: const Scaffold(
              key: destinationKey,
              body: Text('Main Menu'),
            ),
          ),
        ),
      );

      // Process post frame callback
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Shows permission denied view
      expect(find.byType(StartupPermissionView), findsOneWidget);
      expect(find.text('AUDIO ACCESS REQUIRED'), findsOneWidget);

      // Grant permission and tap retry
      fakePerm.permissionGranted = true;
      fakePerm.currentState = AudioPermissionState.granted;

      await tester.tap(find.text('CONTINUE'));

      // Advance frames through controller completion
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify destination navigation occurred
      expect(find.byKey(destinationKey), findsOneWidget);
      expect(find.text('Main Menu'), findsOneWidget);
    });
  });
}
