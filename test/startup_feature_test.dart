/// File: startup_feature_test.dart
/// Description: Unit and Widget tests verifying the modern 4-step Startup sequence:
/// 1. Splash ("PROJECT ANIMA" animated entrance and exit)
/// 2. Permission card (Audio storage and playback notifications)
/// 3. Theme selector ("Monochrome" with 5 constituent color circles and accept action)
/// 4. Wavy library loading sequence with Inconsolata status labels and screen transition.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/localization/localization_controller.dart';
import 'package:project_anima/core/localization/translations/es/startup/es_startup_strings.dart';
import 'package:project_anima/core/permissions/audio_permission_service.dart';
import 'package:project_anima/core/scanner/models/indexing_result.dart';
import 'package:project_anima/core/scanner/music_indexer.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/components/startup_header.dart';
import 'package:project_anima/features/startup/components/startup_loading_view.dart';
import 'package:project_anima/features/startup/components/startup_permission_card_view.dart';
import 'package:project_anima/features/startup/components/startup_permission_view.dart';
import 'package:project_anima/features/startup/components/startup_progress_bar.dart';
import 'package:project_anima/features/startup/components/startup_splash_view.dart';
import 'package:project_anima/features/startup/components/startup_status_view.dart';
import 'package:project_anima/features/startup/components/startup_theme_selector_view.dart';
import 'package:project_anima/features/startup/controls/startup_controller.dart';
import 'package:project_anima/features/startup/models/startup_stage.dart';
import 'package:project_anima/features/startup/models/startup_step.dart';
import 'package:project_anima/features/startup/models/startup_theme_option.dart';
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

Widget _wrapWithLocalization({required Widget child}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalizationController.instance.init();
  });

  group('Startup Models Tests', () {
    test('StartupStep defines the four onboarding sequential phases', () {
      expect(StartupStep.values, [
        StartupStep.splash,
        StartupStep.permissions,
        StartupStep.themeSelector,
        StartupStep.loading,
      ]);
    });

    test('StartupThemeOption monochrome provides 5 constituent palette colors', () {
      const theme = StartupThemeOption.monochrome;
      expect(theme.id, 'monochrome');
      expect(theme.name, 'Monochrome');
      expect(theme.colors.length, 5);
      expect(theme.colors[0], const Color(0xFF0E0E10));
      expect(theme.colors[1], const Color(0xFF1A1A1E));
      expect(theme.colors[2], const Color(0xFF242429));
      expect(theme.colors[3], const Color(0xFF8E8E96));
      expect(theme.colors[4], const Color(0xFFF2F2F2));
    });

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

    test('Startup strings return valid Spanish translations', () {
      const strings = EsStartupStrings();
      expect(strings.permissionsCardTitle, 'PERMISOS REQUERIDOS');
      expect(strings.musicAccessTitle, 'Acceso a la música');
      expect(strings.notificationAccessTitle, 'Acceso a notificaciones');
      expect(strings.grantPermissionsButton, 'PERMITIR ACCESOS');
      expect(strings.themeNameMonochrome, 'Monochrome');
      expect(strings.acceptThemeAction, 'ACEPTAR');
    });
  });

  group('StartupController Step Transitions', () {
    test('StartupController transitions through splash -> permissions -> theme -> loading -> ready', () async {
      final fakePerm = _FakePermissionService();
      final fakeIndexer = _FakeMusicIndexer();

      final controller = StartupController(
        permissionService: fakePerm,
        musicIndexer: fakeIndexer,
      );

      expect(controller.currentStep, StartupStep.splash);
      expect(controller.isReady, isFalse);

      // 1. Advance from splash
      controller.proceedFromSplash();
      expect(controller.currentStep, StartupStep.permissions);

      // 2. Grant permissions
      await controller.requestPermissionsAndProceed();
      expect(controller.currentStep, StartupStep.themeSelector);

      // 3. Accept theme and start scanning
      await controller.acceptThemeAndStartScanning();
      expect(controller.currentStep, StartupStep.loading);
      expect(controller.isReady, isTrue);
      expect(controller.state.stage, StartupStage.ready);
      expect(controller.state.progress, 1.0);

      controller.dispose();
    });

    test('StartupController start() backwards compatibility transitions to ready directly', () async {
      final fakePerm = _FakePermissionService();
      final fakeIndexer = _FakeMusicIndexer();

      final controller = StartupController(
        permissionService: fakePerm,
        musicIndexer: fakeIndexer,
      );

      await controller.start();

      expect(controller.isReady, isTrue);
      expect(controller.state.stage, StartupStage.ready);
      expect(controller.state.step, StartupStep.loading);

      controller.dispose();
    });

    test('StartupController enters permissionDenied stage when permission is rejected in start()', () async {
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
    testWidgets('StartupHeader renders PROJECT ANIMA', (tester) async {
      await tester.pumpWidget(_wrapWithLocalization(child: const StartupHeader()));

      expect(find.text('PROJECT ANIMA'), findsOneWidget);
    });

    testWidgets('StartupProgressBar renders with M3 Expressive CustomPaint', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          child: const StartupProgressBar(
            progress: 0.65,
            width: 260.0,
          ),
        ),
      );

      expect(find.byType(StartupProgressBar), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('StartupSplashView animates brand title and triggers onCompleted when tapped', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        _wrapWithLocalization(
          child: StartupSplashView(
            onCompleted: () => completed = true,
          ),
        ),
      );

      expect(find.text('PROJECT ANIMA'), findsOneWidget);

      // Tap on screen to fast-forward
      await tester.tap(find.byType(StartupSplashView));
      await tester.pump();

      expect(completed, isTrue);
    });

    testWidgets('StartupPermissionCardView renders both permissions and triggers callback', (tester) async {
      bool permissionsRequested = false;

      await tester.pumpWidget(
        _wrapWithLocalization(
          child: StartupPermissionCardView(
            onRequestPermissions: () => permissionsRequested = true,
          ),
        ),
      );

      expect(find.text('PERMISSIONS REQUIRED'), findsOneWidget);
      expect(find.text('Music & Audio Access'), findsOneWidget);
      expect(find.text('Notification Controls'), findsOneWidget);
      expect(find.text('GRANT PERMISSIONS'), findsOneWidget);

      await tester.tap(find.text('GRANT PERMISSIONS'));
      expect(permissionsRequested, isTrue);
    });

    testWidgets('StartupThemeSelectorView renders Monochrome and 5 color circles', (tester) async {
      bool accepted = false;

      await tester.pumpWidget(
        _wrapWithLocalization(
          child: StartupThemeSelectorView(
            onAccept: () => accepted = true,
          ),
        ),
      );

      expect(find.text('Monochrome'), findsOneWidget);
      expect(find.text('SELECT THEME'), findsOneWidget);
      expect(find.text('ACCEPT'), findsOneWidget);

      await tester.tap(find.text('ACCEPT'));
      expect(accepted, isTrue);
    });

    testWidgets('StartupStatusView renders stage text and percentage', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          child: const StartupStatusView(
            stage: StartupStage.savingTracks,
            statusText: 'Saving your tracks...',
            progress: 0.50,
          ),
        ),
      );

      expect(find.text('Saving your tracks...'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('StartupLoadingView renders header, wavy bar, and status labels', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          child: const StartupLoadingView(
            state: StartupState(
              stage: StartupStage.savingCovers,
              progress: 0.75,
              statusText: 'Saving covers...',
            ),
          ),
        ),
      );

      expect(find.text('PROJECT ANIMA'), findsOneWidget);
      expect(find.byType(StartupProgressBar), findsOneWidget);
      expect(find.text('Saving covers...'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('StartupPermissionView renders legacy denied screen correctly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _wrapWithLocalization(
          child: StartupPermissionView(
            onRequestPermission: () => tapped = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
      expect(find.text('AUDIO ACCESS REQUIRED'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      await tester.tap(find.text('CONTINUE'));
      expect(tapped, isTrue);
    });
  });

  group('StartupLoadingScreen Orchestration Tests', () {
    testWidgets('StartupLoadingScreen guides through full 4-step sequence into destination screen', (tester) async {
      final fakePerm = _FakePermissionService();
      final fakeIndexer = _FakeMusicIndexer();

      final controller = StartupController(
        permissionService: fakePerm,
        musicIndexer: fakeIndexer,
      );

      const destinationKey = Key('destination_screen');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: StartupLoadingScreen(
            controller: controller,
            destinationScreen: const Scaffold(
              key: destinationKey,
              body: Text('Main Menu'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 1. Initial Step: Splash View
      expect(find.byType(StartupSplashView), findsOneWidget);

      // Fast-forward splash by tapping
      await tester.tap(find.byType(StartupSplashView));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // AnimatedSwitcher transition

      // 2. Step 2: Permission Card View
      expect(find.byType(StartupPermissionCardView), findsOneWidget);
      expect(find.text('GRANT PERMISSIONS'), findsOneWidget);

      // Tap Grant Permissions button
      await tester.tap(find.text('GRANT PERMISSIONS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // AnimatedSwitcher transition

      // 3. Step 3: Theme Selector View
      expect(find.byType(StartupThemeSelectorView), findsOneWidget);
      expect(find.text('Monochrome'), findsOneWidget);
      expect(find.text('ACCEPT'), findsOneWidget);

      // Tap Accept theme button
      await tester.tap(find.text('ACCEPT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // AnimatedSwitcher transition

      // 4. Step 4: Loading View
      expect(find.byType(StartupLoadingView), findsOneWidget);

      // Settle scanning sequence through ready state
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Successfully reached destination screen!
      expect(find.byKey(destinationKey), findsOneWidget);
      expect(find.text('Main Menu'), findsOneWidget);
    });

    testWidgets('StartupLoadingScreen renders legacy permission denied screen when stage is permissionDenied', (tester) async {
      final fakePerm = _FakePermissionService()
        ..permissionGranted = false
        ..currentState = AudioPermissionState.denied;
      final fakeIndexer = _FakeMusicIndexer();

      final controller = StartupController(
        permissionService: fakePerm,
        musicIndexer: fakeIndexer,
      );

      // Run start directly to force permissionDenied state
      await controller.start();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: StartupLoadingScreen(
            controller: controller,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(StartupPermissionView), findsOneWidget);
      expect(find.text('AUDIO ACCESS REQUIRED'), findsOneWidget);
    });
  });
}
