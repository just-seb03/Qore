/// File: app_route_tracker.dart
/// Description: NavigatorObserver that prevents duplicate route stacking across deep
/// navigation flows (e.g. Player -> Album -> Artist -> Player -> Artist), ensuring Back
/// walks through unique screens without revisiting duplicates.
///
/// Components / Classes / Functions:
/// - AppRouteTracker: Singleton NavigatorObserver maintaining deduplicated named routes.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';

/// Singleton [NavigatorObserver] deduplicating named `anima://` routes in the navigation stack.
class AppRouteTracker extends NavigatorObserver {
  static final AppRouteTracker instance = AppRouteTracker._internal();

  AppRouteTracker._internal();

  factory AppRouteTracker() => instance;

  static const String _prefix = 'anima://';

  static const String playerRouteName = '${_prefix}player';
  static const String settingsRouteName = '${_prefix}settings';

  static String albumRouteName(String albumName, String? artistName) {
    final alb = albumName.trim().toLowerCase();
    final art = (artistName ?? '').trim().toLowerCase();
    return '${_prefix}album/$alb::$art';
  }

  static String artistRouteName(String artistName) =>
      '${_prefix}artist/${artistName.trim().toLowerCase()}';

  static String artistDiscographyRouteName(String artistName) =>
      '${_prefix}artist_discography/${artistName.trim().toLowerCase()}';

  static String artistTracksRouteName(String artistName) =>
      '${_prefix}artist_tracks/${artistName.trim().toLowerCase()}';

  static String playlistRouteName({int? playlistId, required String name}) {
    final idPart = playlistId != null ? '$playlistId' : name.trim().toLowerCase();
    return '${_prefix}playlist/$idPart';
  }

  final List<Route<dynamic>> _routes = [];

  /// Active route names currently in the navigator stack (bottom to top).
  @visibleForTesting
  List<String?> get routeNames => _routes.map((r) => r.settings.name).toList();

  void _syncExpandedPlayerParticles() {
    final bool isPlayerOnTop =
        _routes.isNotEmpty && _routes.last.settings.name == playerRouteName;
    AmbientParticlesController.instance.setExpandedPlayerVisible(isPlayerOnTop);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _routes.add(route);
    _deduplicateIfNeeded(route, previousRoute);
    _syncExpandedPlayerParticles();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _routes.remove(route);
    _syncExpandedPlayerParticles();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _routes.remove(route);
    _syncExpandedPlayerParticles();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      final idx = _routes.indexOf(oldRoute);
      if (idx != -1) {
        if (newRoute != null) {
          _routes[idx] = newRoute;
        } else {
          _routes.removeAt(idx);
        }
        _syncExpandedPlayerParticles();
        return;
      }
    }
    if (newRoute != null) {
      _routes.add(newRoute);
    }
    _syncExpandedPlayerParticles();
  }

  void _deduplicateIfNeeded(
    Route<dynamic> pushedRoute,
    Route<dynamic>? previousRoute,
  ) {
    final String? name = pushedRoute.settings.name;
    if (name == null || !name.startsWith(_prefix)) return;

    final duplicates = _routes
        .where((r) => r != pushedRoute && r.settings.name == name)
        .toList();
    if (duplicates.isEmpty) return;

    void removeDuplicates() {
      final nav = navigator;
      if (nav == null) return;
      for (final dup in duplicates) {
        if (dup.isActive) {
          nav.removeRoute(dup);
        }
      }
    }

    // If any duplicate is the immediately covered previousRoute, wait until the
    // incoming push animation settles so there is zero visual flash underneath.
    final bool overlapsPrevious = duplicates.contains(previousRoute);
    final Animation<double>? anim =
        pushedRoute is ModalRoute<dynamic> ? pushedRoute.animation : null;

    if (overlapsPrevious &&
        anim != null &&
        anim.status != AnimationStatus.completed &&
        anim.status != AnimationStatus.dismissed) {
      void onStatus(AnimationStatus status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          anim.removeStatusListener(onStatus);
          WidgetsBinding.instance.addPostFrameCallback((_) => removeDuplicates());
        }
      }

      anim.addStatusListener(onStatus);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => removeDuplicates());
    }
  }

  /// Clears tracked route references (useful in isolated tests).
  @visibleForTesting
  void reset() => _routes.clear();
}

