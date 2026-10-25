/// File: ambient_particles_background.dart
/// Description: Root layout widget hosting the solid theme canvas backdrop, the PS3-style
/// dynamic particle animation layer, and the application's interactive foreground tree.
///
/// Components / Classes / Functions:
/// - AmbientParticlesBackground: Structural background wrapper supporting the global dynamic atmosphere.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/ambient_particles/components/ambient_particles_canvas.dart';
import 'package:project_anima/features/ambient_particles/controllers/ambient_particles_controller.dart';

/// Wraps application content with a reactive solid canvas and floating PS3-style ambient particles.
class AmbientParticlesBackground extends StatelessWidget {
  /// Interactive foreground content (e.g., Navigator, Screens).
  final Widget child;

  /// Optional controller override (for testing / DI).
  final AmbientParticlesController? controller;

  const AmbientParticlesBackground({
    super.key,
    required this.child,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Solid canvas background matching active palette
            ColoredBox(
              color: AppColors.background,
            ),

            // 2. Dynamic PS3-style ambient particles
            AmbientParticlesCanvas(
              controller: controller,
            ),

            // 3. Foreground application content
            child,
          ],
        );
      },
    );
  }
}
