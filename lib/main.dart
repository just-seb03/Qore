/// File: main.dart
/// Description: Root entry point for the Project Anima Flutter application.
/// Initializes the application with the custom Material Design 3 Expressive
/// monochromatic dark theme and mounts the initial Home screen.
///
/// Components / Classes / Functions:
/// - main(): Application execution entry point.
/// - AnimaApp: Root StatelessWidget configuring global theme and routing.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/controls/menu_transition_controller.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ArtworkService.instance.initialize();

  try {
    await PlaybackController.instance.initAudioService();
  } catch (e) {
    debugPrint('AudioService init warning: $e');
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

  @override
  State<AnimaApp> createState() => _AnimaAppState();
}

class _AnimaAppState extends State<AnimaApp> with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.detached) {
      // User closed the application completely: stop playback and close notification
      PlaybackController.instance.stopAndClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Anima',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MenuTransitionControl(),
    );
  }
}
