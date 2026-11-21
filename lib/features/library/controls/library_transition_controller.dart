/// File: library_transition_controller.dart
/// Description: Dedicated transition controller and animated host control
/// coordinating bidirectional slide transitions between Library sub-views: Albums, Artists, and Playlists.
/// Employs the identical physical spring physics as MenuTransitionController
/// (OvershootResistanceCurve with clamped outgoing tweens and 250ms duration)
/// with touch swipe gesture recognition.
///
/// Components / Classes / Functions:
/// - LibraryTransitionDirection: Enum specifying horizontal slide direction (forward/backward).
/// - _ClampedOffsetTween: Internal Tween clamping progress to prevent offscreen bouncing during overshoot.
/// - LibraryTransitionController: ChangeNotifier managing library view transitions and directions.
/// - LibraryTransitionControl: Host widget animating simultaneous directional page sliding with swipe gesture support.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/controls/menu_transition_controller.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';

/// Horizontal direction for the library sub-view transition animation.
enum LibraryTransitionDirection {
  /// Target tab is to the right (target index > source index).
  /// Outgoing page slides left, incoming page slides in from the right.
  forward,

  /// Target tab is to the left (target index < source index).
  /// Outgoing page slides right, incoming page slides in from the left.
  backward,
}

/// Specialized [Tween] that clamps interpolation progress to [0.0, 1.0].
///
/// Prevents the outgoing sub-view from bouncing or wobbling back into view
/// when the transition curve overshoots (> 1.0) during incoming settling.
class _ClampedOffsetTween extends Tween<Offset> {
  _ClampedOffsetTween({super.begin, super.end});

  @override
  Offset lerp(double t) {
    return super.lerp(t.clamp(0.0, 1.0));
  }
}

/// Dedicated controller managing sub-view transitions between Albums, Artists, and Playlists.
///
/// Operates with low coupling from the library screens and high cohesion by encapsulating
/// index state, transition direction, and animation triggering.
class LibraryTransitionController extends ChangeNotifier {
  LibraryFilter _currentFilter;
  LibraryFilter _previousFilter;
  LibraryTransitionDirection _direction = LibraryTransitionDirection.forward;
  bool _isAnimating = false;

  /// Default transition animation duration (250ms, matching MenuTransitionController).
  Duration duration = const Duration(milliseconds: 250);

  /// Default transition animation curve with hard brake and resistance overshoot.
  Curve curve = const OvershootResistanceCurve(1.25);

  LibraryTransitionController({
    LibraryFilter initialFilter = LibraryFilter.albums,
    Duration? duration,
    Curve? curve,
  })  : _currentFilter = initialFilter,
        _previousFilter = initialFilter {
    if (duration != null) this.duration = duration;
    if (curve != null) this.curve = curve;
  }

  /// Currently active filter.
  LibraryFilter get currentFilter => _currentFilter;

  /// Previously active filter before transition.
  LibraryFilter get previousFilter => _previousFilter;

  /// Active filter index (0: Albums, 1: Artists, 2: Playlists).
  int get currentIndex => _currentFilter.index;

  /// Previous filter index.
  int get previousIndex => _previousFilter.index;

  /// Active horizontal slide direction.
  LibraryTransitionDirection get direction => _direction;

  /// Convenience getter checking if transitioning forward (to the right).
  bool get isForward => _direction == LibraryTransitionDirection.forward;

  /// Whether a transition animation is actively in progress.
  bool get isAnimating => _isAnimating;

  /// Initiates a transition animation towards [targetFilter].
  ///
  /// Automatically resolves animation direction based on index comparison:
  /// - If target > current: slides forward (leftward exit, rightward entrance).
  /// - If target < current: slides backward (rightward exit, leftward entrance).
  void animateTo(LibraryFilter targetFilter) {
    if (_currentFilter == targetFilter) return;

    _previousFilter = _currentFilter;
    _currentFilter = targetFilter;
    _direction = (_currentFilter.index > _previousFilter.index)
        ? LibraryTransitionDirection.forward
        : LibraryTransitionDirection.backward;
    _isAnimating = true;

    notifyListeners();
  }

  /// Initiates a transition animation towards a filter by index.
  void animateToIndex(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= LibraryFilter.values.length) return;
    animateTo(LibraryFilter.values[targetIndex]);
  }

  /// Transitions to the next filter if available. Returns true if transition started.
  bool animateToNext() {
    if (_currentFilter.index < LibraryFilter.values.length - 1) {
      animateToIndex(_currentFilter.index + 1);
      return true;
    }
    return false;
  }

  /// Transitions to the previous filter if available. Returns true if transition started.
  bool animateToPrevious() {
    if (_currentFilter.index > 0) {
      animateToIndex(_currentFilter.index - 1);
      return true;
    }
    return false;
  }

  /// Called internally when transition animation finishes.
  void notifyAnimationFinished() {
    if (_isAnimating) {
      _isAnimating = false;
      notifyListeners();
    }
  }

  /// Resets controller state.
  void reset({LibraryFilter initialFilter = LibraryFilter.albums}) {
    _currentFilter = initialFilter;
    _previousFilter = initialFilter;
    _direction = LibraryTransitionDirection.forward;
    _isAnimating = false;
    notifyListeners();
  }
}

/// Reusable animated host control for Library sub-views (Albums, Artists, Playlists).
///
/// Features:
/// - Exact physical spring physics as [MenuTransitionControl] via [OvershootResistanceCurve(1.25)] and [_ClampedOffsetTween].
/// - Fast, punchy 250ms duration with composited GPU [SlideTransition].
/// - Horizontal drag / swipe gesture recognition allowing the user to swipe left or right to switch views.
/// - Full widget state preservation using [Offstage], [TickerMode], and [RepaintBoundary].
class LibraryTransitionControl extends StatefulWidget {
  /// Controller managing filter selection and transition direction.
  final LibraryTransitionController? controller;

  /// The list of 3 children widgets representing [Albums, Artists, Playlists].
  final List<Widget> children;

  /// Custom animation duration override.
  final Duration? duration;

  /// Custom animation curve override.
  final Curve? curve;

  /// Whether horizontal swipe gestures are enabled. Defaults to true.
  final bool enableSwipeGesture;

  const LibraryTransitionControl({
    super.key,
    this.controller,
    required this.children,
    this.duration,
    this.curve,
    this.enableSwipeGesture = true,
  }) : assert(children.length == LibraryFilter.values.length, 'LibraryTransitionControl requires children matching LibraryFilter.values.length.');

  @override
  State<LibraryTransitionControl> createState() => _LibraryTransitionControlState();
}

class _LibraryTransitionControlState extends State<LibraryTransitionControl>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late LibraryTransitionController _controller;
  bool _internalControllerCreated = false;

  late final AnimationController _animController;
  late final Animation<double> _animation;

  late Animation<Offset> _incomingAnimation;
  late Animation<Offset> _outgoingAnimation;

  int _renderedCurrentIndex = 0;
  int _activePreviousIndex = 0;
  int _activeCurrentIndex = 0;
  LibraryTransitionDirection _activeDirection = LibraryTransitionDirection.forward;
  bool _isTransitioning = false;

  double _accumulatedDragDelta = 0.0;
  late List<Widget> _subScreens;
  late List<bool> _mountedSubTabs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.controller != null) {
      _controller = widget.controller!;
      _internalControllerCreated = false;
    } else {
      _controller = LibraryTransitionController();
      _internalControllerCreated = true;
    }

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

    _updateSlideAnimations(_activeDirection == LibraryTransitionDirection.forward);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isTransitioning = false;
        _controller.notifyAnimationFinished();
        if (mounted) {
          setState(() {});
        }
      }
    });

    _subScreens = List<Widget>.generate(
      widget.children.length,
      (index) => RepaintBoundary(
        key: PageStorageKey<String>('library_tab_$index'),
        child: widget.children[index],
      ),
      growable: false,
    );
    _mountedSubTabs = List<bool>.filled(widget.children.length, false);
    if (_mountedSubTabs.isNotEmpty) {
      _mountedSubTabs[_renderedCurrentIndex.clamp(0, _mountedSubTabs.length - 1)] = true;
    }

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
      final int targetIdx = _controller.currentIndex;
      if (targetIdx >= 0 && targetIdx < _mountedSubTabs.length) {
        _mountedSubTabs[targetIdx] = true;
      }

      if (!_controller.isAnimating) {
        setState(() {
          _renderedCurrentIndex = targetIdx;
          _activeCurrentIndex = targetIdx;
          _activePreviousIndex = targetIdx;
          _isTransitioning = false;
        });
        return;
      }

      final isForward = _controller.direction == LibraryTransitionDirection.forward;
      _activePreviousIndex = _renderedCurrentIndex;
      _activeCurrentIndex = targetIdx;
      _activeDirection = _controller.direction;
      _renderedCurrentIndex = targetIdx;
      if (_activePreviousIndex >= 0 && _activePreviousIndex < _mountedSubTabs.length) {
        _mountedSubTabs[_activePreviousIndex] = true;
      }

      _updateSlideAnimations(isForward);

      _isTransitioning = true;
      if (_animController.isAnimating) {
        _animController.stop();
      }
      _animController.forward(from: 0.0);
      setState(() {});
    }
  }

  @override
  void didHaveMemoryPressure() {
    if (!mounted || _isTransitioning) return;
    bool released = false;
    for (int i = 0; i < _mountedSubTabs.length; i++) {
      if (i != _activeCurrentIndex && _mountedSubTabs[i]) {
        _mountedSubTabs[i] = false;
        released = true;
      }
    }
    if (released) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(LibraryTransitionControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (!_internalControllerCreated) {
        oldWidget.controller?.removeListener(_onControllerChanged);
      } else {
        _controller.removeListener(_onControllerChanged);
        _controller.dispose();
      }

      if (widget.controller != null) {
        _controller = widget.controller!;
        _internalControllerCreated = false;
      } else {
        _controller = LibraryTransitionController();
        _internalControllerCreated = true;
      }
      _controller.addListener(_onControllerChanged);
      final int activeIdx = _controller.currentIndex;
      if (activeIdx >= 0 && activeIdx < _mountedSubTabs.length) {
        _mountedSubTabs[activeIdx] = true;
      }
    }
    if (widget.duration != oldWidget.duration) {
      _animController.duration = widget.duration ?? _controller.duration;
    }
    if (widget.children != oldWidget.children) {
      _subScreens = List<Widget>.generate(
        widget.children.length,
        (index) => RepaintBoundary(
          key: PageStorageKey<String>('library_tab_$index'),
          child: widget.children[index],
        ),
        growable: false,
      );
      if (_mountedSubTabs.length != widget.children.length) {
        _mountedSubTabs = List<bool>.filled(widget.children.length, false);
        if (_mountedSubTabs.isNotEmpty) {
          _mountedSubTabs[_activeCurrentIndex.clamp(0, _mountedSubTabs.length - 1)] = true;
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    if (_internalControllerCreated) {
      _controller.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _accumulatedDragDelta = 0.0;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _accumulatedDragDelta += details.primaryDelta ?? 0.0;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_controller.isAnimating || _isTransitioning) {
      _accumulatedDragDelta = 0.0;
      return;
    }

    final velocity = details.primaryVelocity ?? 0.0;
    const double velocityThreshold = 180.0;
    const double distanceThreshold = 40.0;

    // Dragging left (negative primary velocity or negative delta) -> advance forward to next tab
    if (velocity < -velocityThreshold || _accumulatedDragDelta < -distanceThreshold) {
      _controller.animateToNext();
    }
    // Dragging right (positive primary velocity or positive delta) -> retreat backward to previous tab
    else if (velocity > velocityThreshold || _accumulatedDragDelta > distanceThreshold) {
      _controller.animateToPrevious();
    }

    _accumulatedDragDelta = 0.0;
  }

  void _handleHorizontalDragCancel() {
    _accumulatedDragDelta = 0.0;
  }

  Widget _buildContent() {
    final stack = ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: List.generate(_subScreens.length, (index) {
          final bool isCurrent = index == _activeCurrentIndex;
          final bool isPrevious = index == _activePreviousIndex;
          final bool isVisible =
              _isTransitioning ? (isCurrent || isPrevious) : isCurrent;
          final bool shouldMount = _mountedSubTabs[index] || isVisible;

          if (!shouldMount) {
            return KeyedSubtree(
              key: ValueKey<int>(index),
              child: const SizedBox.shrink(),
            );
          }

          Animation<Offset> slideAnim;
          if (_isTransitioning) {
            if (isCurrent) {
              slideAnim = _incomingAnimation;
            } else if (isPrevious) {
              slideAnim = _outgoingAnimation;
            } else {
              slideAnim = const AlwaysStoppedAnimation(Offset.zero);
            }
          } else {
            slideAnim = const AlwaysStoppedAnimation(Offset.zero);
          }

          return KeyedSubtree(
            key: ValueKey<int>(index),
            child: Offstage(
              offstage: !isVisible,
              child: TickerMode(
                enabled: isVisible,
                child: SlideTransition(
                  position: slideAnim,
                  child: _subScreens[index],
                ),
              ),
            ),
          );
        }),
      ),
    );

    if (!widget.enableSwipeGesture) {
      return stack;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      onHorizontalDragCancel: _handleHorizontalDragCancel,
      child: stack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }
}
