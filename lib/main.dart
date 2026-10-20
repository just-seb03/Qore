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
import 'package:project_anima/core/theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ArtworkService.instance.initialize();

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
class AnimaApp extends StatelessWidget {
  const AnimaApp({super.key});

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
