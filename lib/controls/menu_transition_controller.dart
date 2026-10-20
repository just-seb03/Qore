/// File: menu_transition_controller.dart
/// Description: Dedicated global transition controller and animated host control
/// coordinating bidirectional slide transitions between primary menus: Home, Search, and Library.
/// Decoupled from core navigation state management to isolate animation orchestration.
/// Implements composited GPU SlideTransition with pre-interpolated `Tween<Offset>`
/// to prevent widget tree rebuilds during transitions.
///
/// Components / Classes / Functions:
/// - MenuTransitionDirection: Enum specifying horizontal slide direction (forward/backward).
/// - OvershootResistanceCurve: Custom curve with fast acceleration, hard braking, and elastic resistance.
/// - _ClampedOffsetTween: Internal Tween clamping progress to prevent offscreen bounce during overshoot.
/// - MenuTransitionController: Singleton ChangeNotifier managing transition state and direction.
/// - MenuTransitionControl: Reusable widget animating simultaneous directional page sliding.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/controls/navigation_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/home/screens/home.dart';
import 'package:project_anima/features/library/screens/library.dart';
import 'package:project_anima/features/search/screens/search.dart';

/// Horizontal direction for the menu transition animation.
enum MenuTransitionDirection {
  /// Target tab is to the right (target index > source index).
  /// Outgoing page slides left, incoming page slides in from the right.
  forward,

  /// Target tab is to the left (target index < source index).
  /// Outgoing page slides right, incoming page slides in from the left.
  backward,
}

/// A specialized deceleration curve that launches rapidly, brakes hard,
/// overshoots the target center slightly (~5.7%), and returns to center with resistance.
class OvershootResistanceCurve extends Curve {
  /// Resistance and overshoot intensity parameter.
  /// Defaults to 1.25, creating an optimal physical spring and braking feel.
  final double intensity;

  const OvershootResistanceCurve([this.intensity = 1.25]);

  @override
  double transformInternal(double t) {
    final double tau = t - 1.0;
    return 1.0 + (intensity + 1.0) * tau * tau * tau + intensity * tau * tau;
  }
}

/// Specialized [Tween] that clamps interpolation progress to [0.0, 1.0].
///
/// Prevents the outgoing screen from bouncing or wobbling off-screen when the
/// transition curve overshoots (> 1.0) during incoming settling.
class _ClampedOffsetTween extends Tween<Offset> {
  _ClampedOffsetTween({super.begin, super.end});

  @override
  Offset lerp(double t) {
    return super.lerp(t.clamp(0.0, 1.0));
  }
}

/// Global controller managing menu transition animations between Home, Search, and Library.
///
/// Operates independently from [NavigationController] to keep animation coordination
/// separate from routing and navigation state.
class MenuTransitionController extends ChangeNotifier {
  static final MenuTransitionController instance = MenuTransitionController._internal();

  MenuTransitionController._internal();

  factory MenuTransitionController() => instance;

  int _currentIndex = 0;
  int _previousIndex = 0;
  MenuTransitionDirection _direction = MenuTransitionDirection.forward;
  bool _isAnimating = false;

  /// Default transition animation duration (fast, punchy 250ms).
  Duration duration = const Duration(milliseconds: 250);

  /// Default transition animation curve with hard brake and resistance overshoot.
  Curve curve = const OvershootResistanceCurve(1.25);

  /// Currently active menu index (0: Home, 1: Search, 2: Library).
  int get currentIndex => _currentIndex;

  /// Previously active menu index before transition.
  int get previousIndex => _previousIndex;

  /// Active horizontal slide direction.
  MenuTransitionDirection get direction => _direction;

  /// Convenience getter checking if transitioning forward (to the right).
  bool get isForward => _direction == MenuTransitionDirection.forward;

  /// Whether a transition animation is actively in progress.
  bool get isAnimating => _isAnimating;

  /// Initiates a transition animation towards [targetIndex].
  ///
  /// Automatically resolves animation direction based on index comparison:
  /// - If target > current: slides forward (leftward exit, rightward entrance).
  /// - If target < current: slides backward (rightward exit, leftward entrance).
  void animateTo(int targetIndex) {
    if (targetIndex < 0 || targetIndex > 2) return;
    if (_currentIndex == targetIndex) return;

    _previousIndex = _currentIndex;
    _currentIndex = targetIndex;
    _direction = (_currentIndex > _previousIndex)
        ? MenuTransitionDirection.forward
        : MenuTransitionDirection.backward;
    _isAnimating = true;

    notifyListeners();
  }

  /// Convenience method accepting a [NavigationTab] destination.
  void animateToTab(NavigationTab tab) {
    animateTo(tab.index);
  }

  /// Called internally when transition animation finishes.
  void notifyAnimationFinished() {
    if (_isAnimating) {
      _isAnimating = false;
      notifyListeners();
    }
  }

  /// Resets controller state to the initial Home tab without animating.
  void reset() {
    _currentIndex = 0;
    _previousIndex = 0;
    _direction = MenuTransitionDirection.forward;
    _isAnimating = false;
    notifyListeners();
  }
}

/// Reusable global control widget hosting Home, Search, and Library menus
/// with synchronized directional slide animations.
class MenuTransitionControl extends StatefulWidget {
  /// Custom controller instance. Defaults to [MenuTransitionController.instance].
  final MenuTransitionController? controller;

  /// Explicit list of children widgets to animate between (ordered: 0: Home, 1: Search, 2: Library).
  /// If null, default instances of [HomeScreen], [SearchScreen], and [LibraryScreen] are used.
  final List<Widget>? children;

  /// Whether to host the global [AppBottomNav] inside this control's Scaffold.
  final bool includeBottomNav;

  /// Custom animation duration override.
  final Duration? duration;

  /// Custom animation curve override.
  final Curve? curve;

  const MenuTransitionControl({
    super.key,
    this.controller,
    this.children,
    this.includeBottomNav = true,
    this.duration,
    this.curve,
  });

  @override
  State<MenuTransitionControl> createState() => _MenuTransitionControlState();
}

class _MenuTransitionControlState extends State<MenuTransitionControl>
    with SingleTickerProviderStateMixin {
  late final MenuTransitionController _controller;
  late final AnimationController _animController;
  late final Animation<double> _animation;

  late Animation<Offset> _incomingAnimation;
  late Animation<Offset> _outgoingAnimation;

  int _renderedCurrentIndex = 0;
  int _activePreviousIndex = 0;
  int _activeCurrentIndex = 0;
  MenuTransitionDirection _activeDirection = MenuTransitionDirection.forward;
  bool _isTransitioning = false;

  late List<Widget> _menuScreens;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? MenuTransitionController.instance;

    _renderedCurrentIndex = _controller.currentIndex;
    _activePreviousIndex = _controller.previousIndex;
    _activeCurrentIndex = _controller.currentIndex;
    _activeDirection = _controller.direction;

    final animDuration = widget.duration ?? _controller.duration;
    final animCurve = widget.curve ?? _controller.curve;

    _animController = AnimationController(
      vsync: this,
      duration: animDuration,
    );

    _animation = CurvedAnimation(
      parent: _animController,
      curve: animCurve,
    );

    _updateSlideAnimations(_activeDirection == MenuTransitionDirection.forward);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isTransitioning = false;
        _controller.notifyAnimationFinished();
        if (mounted) {
          setState(() {});
        }
      }
    });

    final screens = widget.children ??
        const [
          HomeScreen(showBottomNav: false),
          SearchScreen(showBottomNav: false),
          LibraryScreen(showBottomNav: false),
        ];

    _menuScreens = List<Widget>.generate(
      screens.length,
      (index) => RepaintBoundary(
        key: ValueKey<int>(index),
        child: screens[index],
      ),
      growable: false,
    );

    _controller.addListener(_onControllerChanged);
  }

  void _updateSlideAnimations(bool isForward) {
    final incomingBegin =
        isForward ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
    final outgoingEnd =
        isForward ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);

    _incomingAnimation = Tween<Offset>(
      begin: incomingBegin,
      end: Offset.zero,
    ).animate(_animation);

    _outgoingAnimation = _ClampedOffsetTween(
      begin: Offset.zero,
      end: outgoingEnd,
    ).animate(_animation);
  }

  void _onControllerChanged() {
    if (!mounted) return;

    if (_controller.currentIndex != _renderedCurrentIndex) {
      if (!_controller.isAnimating) {
        setState(() {
          _renderedCurrentIndex = _controller.currentIndex;
          _activeCurrentIndex = _controller.currentIndex;
          _activePreviousIndex = _controller.currentIndex;
          _isTransitioning = false;
        });
        return;
      }

      final isForward = _controller.direction == MenuTransitionDirection.forward;
      _activePreviousIndex = _renderedCurrentIndex;
      _activeCurrentIndex = _controller.currentIndex;
      _activeDirection = _controller.direction;
      _renderedCurrentIndex = _controller.currentIndex;

      _updateSlideAnimations(isForward);

      _isTransitioning = true;
      _animController.forward(from: 0.0);
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(MenuTransitionControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _animController.duration = widget.duration ?? _controller.duration;
    }
    if (widget.children != oldWidget.children && widget.children != null) {
      _menuScreens = List<Widget>.generate(
        widget.children!.length,
        (index) => RepaintBoundary(
          key: ValueKey<int>(index),
          child: widget.children![index],
        ),
        growable: false,
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _animController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedContent() {
    if (!_isTransitioning) {
      return _menuScreens[_activeCurrentIndex];
    }

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          SlideTransition(
            position: _outgoingAnimation,
            child: _menuScreens[_activePreviousIndex],
          ),
          SlideTransition(
            position: _incomingAnimation,
            child: _menuScreens[_activeCurrentIndex],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animatedContent = _buildAnimatedContent();

    if (!widget.includeBottomNav) {
      return animatedContent;
    }

    return Scaffold(
      backgroundColor: AppColors.bottomNavBackground,
      body: animatedContent,
      bottomNavigationBar: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return AppBottomNav(
            currentIndex: _controller.currentIndex,
            onDestinationSelected: (index) {
              _controller.animateTo(index);
              NavigationController.instance.setIndex(index);
            },
          );
        },
      ),
    );
  }
}
