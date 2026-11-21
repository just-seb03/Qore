/// File: startup_loading_screen.dart
/// Description: Initial launch screen coordinating the modern 3-step startup onboarding experience:
/// 1. Animated brand splash ("PROJECT ANIMA" with graceful exit)
/// 2. Permissions request card (Audio files & notification access with action trigger)
/// 3. Dynamic library loading sequence (Wavy progress bar & status labels)
/// followed by seamless transition into the primary application interface.
///
/// Components / Classes / Functions:
/// - StartupLoadingScreen: Main stateful orchestrator switching smoothly across startup steps.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project_anima/controls/menu_transition_controller.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/components/startup_loading_view.dart';
import 'package:project_anima/features/startup/components/startup_permission_card_view.dart';
import 'package:project_anima/features/startup/components/startup_permission_view.dart';
import 'package:project_anima/features/startup/components/startup_splash_view.dart';
import 'package:project_anima/features/startup/controls/startup_controller.dart';
import 'package:project_anima/features/startup/models/startup_stage.dart';
import 'package:project_anima/features/startup/models/startup_step.dart';

/// The entry screen mounted on app initialization to guide the user through
/// branding, permission grant, and audio library indexing.
class StartupLoadingScreen extends StatefulWidget {
  /// Optional injected controller for testing or custom orchestration.
  final StartupController? controller;

  /// Optional target screen destination upon completion. Defaults to [MenuTransitionControl].
  final Widget? destinationScreen;

  /// Optional initial step override (defaults to [StartupStep.splash]).
  final StartupStep? initialStep;

  const StartupLoadingScreen({
    super.key,
    this.controller,
    this.destinationScreen,
    this.initialStep,
  });

  @override
  State<StartupLoadingScreen> createState() => _StartupLoadingScreenState();
}

class _StartupLoadingScreenState extends State<StartupLoadingScreen> {
  late final StartupController _controller;
  bool _internalController = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _internalController = false;
    } else {
      _controller = StartupController();
      _internalController = true;
    }

    if (widget.initialStep != null) {
      _controller.goToStep(widget.initialStep!);
    } else if (!_controller.isPermissionDenied) {
      if (!_controller.isFirstLaunch) {
        _controller.startScanningSequence();
      } else {
        _initFirstLaunchCheck();
      }
    }

    _controller.addListener(_onControllerStateChanged);
  }

  Future<void> _initFirstLaunchCheck() async {
    await _controller.checkOnboardingAndInitialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onCelebrationCompleted() {
    if (_hasNavigated || !mounted) return;
    _controller.markOnboardingCompleted();
    _navigateToDestination();
  }

  Future<void> _prewarmSpaceArtworks(BuildContext context) async {
    try {
      final pinned = PinnedFavoritesDao.instance.cachedPinned ??
          await PinnedFavoritesDao.instance.getAllPinned();
      if (!context.mounted || pinned.isEmpty) return;

      final List<Future<void>> tasks = [];
      for (final item in pinned) {
        if (item.isArtist) {
          final directPath = item.coverPath != null && File(item.coverPath!).existsSync()
              ? item.coverPath
              : null;
          final photoPath = directPath ??
              ArtworkService.instance.getCustomArtistSquarePhoto(item.title);
          if (photoPath != null && File(photoPath).existsSync()) {
            tasks.add(
              precacheImage(FileImage(File(photoPath)), context).catchError((_) {}),
            );
          }
        } else if (item.isPlaylist) {
          if (item.coverPath != null && File(item.coverPath!).existsSync()) {
            tasks.add(
              precacheImage(FileImage(File(item.coverPath!)), context)
                  .catchError((_) {}),
            );
          } else if (item.representativeSongId != null && item.representativeSongId! > 0) {
            tasks.add(
              AnimaArtworkImage.precacheSongArtwork(
                context,
                mediaStoreId: item.representativeSongId!,
                width: double.infinity,
                isThumbnail: false,
              ),
            );
          }
        } else {
          tasks.add(
            AnimaArtworkImage.precacheSongArtwork(
              context,
              mediaStoreId: item.representativeSongId ?? 0,
              albumId: item.albumId,
              albumName: item.title,
              artistName: item.subtitle,
              width: double.infinity,
              isThumbnail: false,
            ),
          );
        }
      }

      if (tasks.isNotEmpty) {
        await Future.wait(tasks).timeout(
          const Duration(milliseconds: 900),
          onTimeout: () => <void>[],
        );
      }
    } catch (_) {}
  }

  Future<void> _navigateToDestination() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    await _prewarmSpaceArtworks(context);
    if (!mounted) return;
    final target = widget.destinationScreen ?? const MenuTransitionControl();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _onControllerStateChanged() {
    if (_controller.state.stage == StartupStage.ready && !_hasNavigated && mounted) {
      if (!_controller.isFirstLaunch) {
        // Second time onwards: no celebration stars, navigate directly after subtle settle
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          _navigateToDestination();
        });
      } else {
        // Fallback safety in case celebration view was not mounted
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (!_hasNavigated && mounted) {
            _onCelebrationCompleted();
          }
        });
      }
    }
  }

  Key _getActiveStepKey(StartupState state) {
    if (state.stage == StartupStage.permissionDenied) {
      return const ValueKey('startup_permission_denied_view');
    }
    switch (state.step) {
      case StartupStep.splash:
        return const ValueKey('startup_splash_view');
      case StartupStep.permissions:
        return const ValueKey('startup_permission_card_view');
      case StartupStep.loading:
        return const ValueKey('startup_loading_view');
    }
  }

  Widget _buildStepWidget(BuildContext context, StartupState state) {
    // If runtime permission was denied in legacy retry flow, show dedicated permission view
    if (state.stage == StartupStage.permissionDenied) {
      return StartupPermissionView(
        key: const ValueKey('startup_permission_denied_view'),
        onRequestPermission: _controller.requestPermissionAndRetry,
      );
    }

    switch (state.step) {
      case StartupStep.splash:
        return StartupSplashView(
          key: const ValueKey('startup_splash_view'),
          onCompleted: _controller.proceedFromSplash,
        );

      case StartupStep.permissions:
        return StartupPermissionCardView(
          key: const ValueKey('startup_permission_card_view'),
          isDenied: state.stage == StartupStage.permissionDenied,
          onRequestPermissions: _controller.requestPermissionsAndProceed,
        );

      case StartupStep.loading:
        return StartupLoadingView(
          key: const ValueKey('startup_loading_view'),
          state: state,
          celebrate: _controller.isFirstLaunch,
          onCelebrationComplete: _onCelebrationCompleted,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          color: AppColors.background,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final state = _controller.state;
                  final activeKey = _getActiveStepKey(state);

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          ...previousChildren,
                          ?currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      final isIncoming = child.key == activeKey;
                      if (isIncoming) {
                        // Incoming child emerges only after outgoing child has faded out
                        final inAnim = CurvedAnimation(
                          parent: animation,
                          curve: const Interval(0.40, 1.0, curve: Curves.easeOutCubic),
                        );
                        return FadeTransition(
                          opacity: inAnim,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.94, end: 1.0).animate(inAnim),
                            child: child,
                          ),
                        );
                      } else {
                        // Outgoing child cleanly fades out with zero visual overlap
                        final outAnim = CurvedAnimation(
                          parent: animation,
                          curve: const Interval(0.60, 1.0, curve: Curves.easeInCubic),
                        );
                        return FadeTransition(
                          opacity: outAnim,
                          child: child,
                        );
                      }
                    },
                    child: _buildStepWidget(context, state),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
