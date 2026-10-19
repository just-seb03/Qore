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
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/home/screens/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const HomeScreen(),
    );
  }
}
