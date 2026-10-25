/// File: startup_step.dart
/// Description: Sequential onboarding and initialization steps executed during application startup.
/// Orchestrates the progression through initial splash, dual permission grant card,
/// theme preview selection, and background audio indexing.
///
/// Components / Classes / Functions:
/// - StartupStep: Enum representing distinct user-facing phases of the startup sequence.
library;

/// Distinct interactive steps during the startup onboarding and loading flow.
enum StartupStep {
  /// 1. Initial brand presentation that animates in and departs smoothly.
  splash,

  /// 2. Interactive card presenting both Music and Notification permission requests.
  permissions,

  /// 3. Theme selector showing the theme name ("Monochrome"), 5 color swatches, and accept button.
  themeSelector,

  /// 4. The standard indexing and loading screen with wavy progress bar and stage status.
  loading,
}
