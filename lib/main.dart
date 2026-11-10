/// File: main.dart
/// Description: Root entry point for the Project Anima Flutter application.
/// Initializes the application with the custom Material Design 3 Expressive
/// monochromatic dark theme, adaptive system boundary management for cutout/notch
/// masking (e.g. Xiaomi MIUI / Samsung One UI "Hide Notch"), and mounts the initial Home screen.
///
/// Components / Classes / Functions:
/// - main(): Application execution entry point.
/// - AnimaApp: Root StatefulWidget configuring global theme, lifecycle, and adaptive boundaries.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/app_metadata_dao.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/dimensions/adaptive_system_boundary.dart';
import 'package:project_anima/core/dimensions/system_dimensions_coordinator.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/localization/localization_controller.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/startup/screens/startup_loading_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock application strictly to vertical portrait mode (disable horizontal orientation)
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure balanced, low-footprint RAM ImageCache (45MB buffer, 100 images)
  // Prevents aggressive OS Low Memory Killer (LMK) while preserving instant 60/120 FPS scrolling
  PaintingBinding.instance.imageCache.maximumSizeBytes = 45 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 100;

  ArtworkService.instance.initialize();
  LocalizationController.instance.init();

  try {
    await AppMetadataDao.instance.isOnboardingCompleted();
  } catch (e) {
    debugPrint('AppMetadataDao onboarding check warning: $e');
  }

  try {
    await AppMetadataDao.instance.hasSeenSpaceIntro();
  } catch (e) {
    debugPrint('AppMetadataDao space intro check warning: $e');
  }

  try {
    await ThemeController.instance.init();
  } catch (e) {
    debugPrint('ThemeController init warning: $e');
  }

  try {
    await FavoriteSongsDao.instance.ensureLoaded();
  } catch (e) {
    debugPrint('FavoriteSongsDao ensureLoaded warning: $e');
  }

  try {
    await SystemDimensionsCoordinator.instance.init();
  } catch (e) {
    debugPrint('SystemDimensions init warning: $e');
  }

  try {
    await PlaybackController.instance.initAudioService();
  } catch (e) {
    debugPrint('AudioService init warning: $e');
  }

  try {
    await PlaybackController.instance.restoreLastSession();
  } catch (e) {
    debugPrint('Playback session restore warning: $e');
  }

  // Configure true Edge-to-Edge and disable artificial OS status bar scrims/shadows
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(const AnimaApp());
}

/// Root widget of the Project Anima application.
class AnimaApp extends StatefulWidget {
  const AnimaApp({super.key});

  /// Restarts the application widget tree cleanly with all newly applied configurations.
  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_AnimaAppState>()?.restart();
  }

  @override
  State<AnimaApp> createState() => _AnimaAppState();
}

class _AnimaAppState extends State<AnimaApp> with WidgetsBindingObserver {
  Key _appKey = UniqueKey();

  void restart() {
    setState(() {
      _appKey = UniqueKey();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-detect system dimensions and notch concealment in case user modified device settings
      SystemDimensionsCoordinator.instance.refresh();
      AmbientParticlesController.instance.setAppPaused(false);
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      PlaybackController.instance.saveCurrentSessionImmediate();
      AmbientParticlesController.instance.setAppPaused(true);
      // Evict non-visible rasterized GPU textures from RAM when app is backgrounded
      PaintingBinding.instance.imageCache.clearLiveImages();
    }
    if (state == AppLifecycleState.detached) {
      // User closed the application completely: stop playback and close notification
      PlaybackController.instance.stopAndClose();
    }
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    // Proactively purge unpinned raster textures under OS memory pressure
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _appKey,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          LocalizationController.instance,
          ThemeController.instance,
        ]),
        builder: (context, _) {
          return MaterialApp(
          title: 'Project Anima',
          debugShowCheckedModeBanner: false,
          theme: ThemeController.instance.currentThemeData,
          locale: LocalizationController.instance.currentLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return AdaptiveSystemBoundary(
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const StartupLoadingScreen(),
        );
      },
    ),
    );
  }
}
