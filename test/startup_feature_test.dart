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
import 'package:project_anima/core/database/dao/app_metadata_dao.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/localization/localization_controller.dart';
import 'package:project_anima/core/localization/translations/es/startup/es_startup_strings.dart';
import 'package:project_anima/core/permissions/audio_permission_service.dart';
import 'package:project_anima/core/scanner/models/indexing_result.dart';
import 'package:project_anima/core/scanner/music_indexer.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/components/startup_celebration_stars.dart';
import 'package:project_anima/features/startup/components/startup_header.dart';
import 'package:project_anima/features/startup/components/startup_loading_view.dart';
import 'package:project_anima/features/startup/components/startup_permission_card_view.dart';
import 'package:project_anima/features/startup/components/startup_permission_view.dart';
import 'package:project_anima/features/startup/components/startup_progress_bar.dart';
import 'package:project_anima/features/startup/components/startup_splash_view.dart';
import 'package:project_anima/features/startup/components/startup_status_view.dart';
import 'package:project_anima/features/startup/controls/startup_controller.dart';
import 'package:project_anima/features/startup/models/startup_stage.dart';
import 'package:project_anima/features/startup/models/startup_step.dart';
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
    test('StartupStep defines the three onboarding sequential phases', () {
      expect(StartupStep.values, [
        StartupStep.splash,
        StartupStep.permissions,
        StartupStep.loading,
      ]);
    });

    test('ThemeController coordinates Monochrome dark and light brightness switching', () {
      final controller = ThemeController.instance;
      expect(controller.availableFamilies, ['monochrome']);
      expect(controller.activeFamily, 'monochrome');

      controller.setTheme('monochrome', isDark: true);
      expect(controller.isDarkMode, isTrue);
      expect(controller.currentPalette.background, const Color(0xFF0E0E10));

      controller.setDarkMode(false);
      expect(controller.isDarkMode, isFalse);
      expect(controller.currentPalette.background, const Color(0xFFF5F5F7));

      controller.toggleBrightness();
      expect(controller.isDarkMode, isTrue);
      expect(controller.currentPalette.background, const Color(0xFF0E0E10));
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
      expect(strings.welcomeLine1, 'Bienvenido');
      expect(strings.welcomeLine2, 'A');
      expect(strings.welcomeLine3, 'Anima');
      expect(strings.musicAccessPrompt, contains('Para poder utilizar Anima'));
      expect(strings.notificationAccessPrompt, contains('notifiaciones'));
      expect(strings.permissionDeniedPrompt, contains('No se otorgaron los permisos'));
      expect(strings.nextAction, 'SIGUIENTE');
      expect(strings.permissionsCardTitle, 'PERMISOS REQUERIDOS');
      expect(strings.musicAccessTitle, 'Acceso a la música');
      expect(strings.notificationAccessTitle, 'Acceso a notificaciones');
      expect(strings.grantPermissionsButton, 'PERMITIR ACCESOS');
      expect(strings.themeNameMonochrome, 'Monochrome');
    });
  });

  group('StartupController Step Transitions', () {
    test('StartupController transitions through splash -> permissions -> loading -> ready', () async {
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

      // 2. Grant permissions directly initiates scanning & loading
      await controller.requestPermissionsAndProceed();
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

    testWidgets('StartupSplashView animates Bienvenido / A / Anima brand title and triggers onCompleted when tapped', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        _wrapWithLocalization(
          child: StartupSplashView(
            onCompleted: () => completed = true,
          ),
        ),
      );

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
      expect(find.text('Anima'), findsOneWidget);

      // Tap on screen to fast-forward
      await tester.tap(find.byType(StartupSplashView));
      await tester.pump();

      expect(completed, isTrue);
    });

    testWidgets('StartupPermissionCardView stages from < 1 > music to < 2 > notifications to request', (tester) async {
      bool permissionsRequested = false;

      await tester.pumpWidget(
        _wrapWithLocalization(
          child: StartupPermissionCardView(
            onRequestPermissions: () {
              permissionsRequested = true;
              return true;
            },
          ),
        ),
      );

      // Page 1: Music note icon, access prompt, animated indicator < 1 >, and NEXT button
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
      expect(find.textContaining('access to your music files'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);

      // Tap NEXT to advance to Page 2
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Page 2: Notification icon, background playback prompt, indicator < 2 >, and NEXT button
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
      expect(find.textContaining('notification system'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);

      // Tap NEXT to launch permissions request
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(permissionsRequested, isTrue);
    });

    testWidgets('StartupPermissionCardView displays monochrome alert icon, error prompt and removes < 2 > on denial', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          child: StartupPermissionCardView(
            initialPage: 2,
            initialDenied: false,
            onRequestPermissions: () async => false, // denied
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);

      // Tap NEXT, request fails/denied
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      // Denial state: Monochrome warning/alert icon, error prompt, hidden < 2 >, and retry NEXT button
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('permissions were not granted'), findsOneWidget);
      expect(find.text('2'), findsNothing);
      expect(find.text('NEXT'), findsOneWidget);
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

    testWidgets('StartupLoadingView renders centered wavy bar, subtle brand label, and celebration stars on complete', (tester) async {
      bool celebrationDone = false;

      await tester.pumpWidget(
        _wrapWithLocalization(
          child: StartupLoadingView(
            state: const StartupState(
              stage: StartupStage.ready,
              progress: 1.0,
              statusText: 'All set!',
            ),
            celebrate: true,
            onCelebrationComplete: () => celebrationDone = true,
          ),
        ),
      );

      // Only centered progress bar and bottom subtle brand title
      expect(find.byType(StartupProgressBar), findsOneWidget);
      expect(find.text('project_anima'), findsOneWidget);
      expect(find.byType(StartupCelebrationStars), findsOneWidget);

      // Advance through celebration duration
      await tester.pump(const Duration(milliseconds: 1400));
      expect(celebrationDone, isTrue);
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
    testWidgets('StartupLoadingScreen guides through full 3-step sequence into destination screen', (tester) async {
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

      // 2. Step 2: Permission Card View (Staged Onboarding Menu)
      expect(find.byType(StartupPermissionCardView), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Tap NEXT to advance to Page 2 (< 2 >)
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('2'), findsOneWidget);

      // Tap NEXT to request permissions and advance directly to library loading
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600)); // Darkening and grant
      await tester.pump(const Duration(milliseconds: 600)); // AnimatedSwitcher transition to Loading

      // 3. Step 3: Loading View
      expect(find.byType(StartupLoadingView), findsOneWidget);

      // Settle scanning sequence through ready state
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1400)); // Celebration stars duration
      await tester.pumpAndSettle();

      // Successfully reached destination screen!
      expect(find.byKey(destinationKey), findsOneWidget);
      expect(find.text('Main Menu'), findsOneWidget);
    });

    testWidgets('StartupLoadingScreen skips onboarding and loads directly on second launch', (tester) async {
      final fakePerm = _FakePermissionService();
      final fakeIndexer = _FakeMusicIndexer();
      final mockMetadataDao = AppMetadataDao(mockOnboardingCompleted: true);

      final controller = StartupController(
        permissionService: fakePerm,
        musicIndexer: fakeIndexer,
        appMetadataDao: mockMetadataDao,
      );

      const destinationKey = Key('destination_screen_second_launch');

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
              body: Text('Second Launch Destination'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Skips splash and permissions!
      expect(find.byType(StartupSplashView), findsNothing);
      expect(find.byType(StartupPermissionCardView), findsNothing);

      // Mounts loading view directly
      expect(find.byType(StartupLoadingView), findsOneWidget);
      expect(find.text('project_anima'), findsOneWidget);

      // Settle scanning sequence
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Directly reaches destination screen without celebration stars
      expect(find.byType(StartupCelebrationStars), findsNothing);
      expect(find.byKey(destinationKey), findsOneWidget);
      expect(find.text('Second Launch Destination'), findsOneWidget);
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

    test('ThemeController persists active family and isDark to AppMetadataDao and restores on init', () async {
      final dao = AppMetadataDao.instance;
      dao.setMockTheme(family: null, isDark: null);

      // 1. Change mode via controller
      ThemeController.instance.setTheme('monochrome', isDark: false);
      expect(ThemeController.instance.activeFamily, 'monochrome');
      expect(ThemeController.instance.isDarkMode, isFalse);
      expect(dao.cachedThemeFamily, 'monochrome');
      expect(dao.cachedIsDarkMode, isFalse);

      // 2. Re-initialize controller from persisted DAO
      dao.setMockTheme(family: 'monochrome', isDark: true);
      await ThemeController.instance.init(appMetadataDao: dao, syncWithSystem: false);

      expect(ThemeController.instance.activeFamily, 'monochrome');
      expect(ThemeController.instance.isDarkMode, isTrue);
    });

    test('ThemeController dynamically synchronizes with device system platformBrightness', () async {
      // Light brightness
      ThemeController.instance.syncWithSystemBrightness(Brightness.light);
      expect(ThemeController.instance.isDarkMode, isFalse);
      expect(ThemeController.instance.currentPalette.brightness, Brightness.light);

      // Dark brightness
      ThemeController.instance.syncWithSystemBrightness(Brightness.dark);
      expect(ThemeController.instance.isDarkMode, isTrue);
      expect(ThemeController.instance.currentPalette.brightness, Brightness.dark);
    });
  });
}
