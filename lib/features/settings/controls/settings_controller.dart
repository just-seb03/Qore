/// File: settings_controller.dart
/// Description: Centralized state manager for the Settings lateral side sheet.
/// Coordinates sheet visibility and pauses Metro live tile 3D flip animations while active.
///
/// Components / Classes / Functions:
/// - SettingsController: Singleton ChangeNotifier managing settings sheet lifecycle.
library;

import 'package:flutter/foundation.dart';
import 'package:project_anima/features/home/components/metro_live_tile.dart';

/// Centralized controller coordinating the Settings side sheet.
class SettingsController extends ChangeNotifier {
  SettingsController._internal();

  static SettingsController? _instance;

  /// Global singleton instance.
  static SettingsController get instance =>
      _instance ??= SettingsController._internal();

  @visibleForTesting
  static void setMockInstance(SettingsController? mockController) {
    _instance = mockController;
  }

  bool _isSheetOpen = false;

  /// Whether the lateral settings side sheet is currently open / visible.
  bool get isSheetOpen => _isSheetOpen;

  /// Opens the lateral settings side sheet and pauses Metro live tile flip animations.
  void openSheet() {
    if (_isSheetOpen) return;
    _isSheetOpen = true;
    MetroLiveTile.isPaused.value = true;
    notifyListeners();
  }

  /// Closes the lateral settings side sheet and resumes Metro live tile flip animations.
  void closeSheet() {
    if (!_isSheetOpen) return;
    _isSheetOpen = false;
    MetroLiveTile.isPaused.value = false;
    notifyListeners();
  }

  /// Toggles the lateral settings side sheet open or closed.
  void toggleSheet() {
    if (_isSheetOpen) {
      closeSheet();
    } else {
      openSheet();
    }
  }
}
