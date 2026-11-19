/// File: duration_formatter.dart
/// Description: Shared duration formatting helpers for player progress bars and track tiles.
library;

/// Formats a [Duration] as `M:SS` when under an hour, or `H:MM:SS` when >= 1 hour.
String formatDuration(Duration duration) {
  final int totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final int hours = totalSeconds ~/ 3600;
  final int minutes = (totalSeconds % 3600) ~/ 60;
  final int seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Formats a duration in milliseconds [ms] as `M:SS` or `H:MM:SS`.
String formatDurationMs(int ms) {
  if (ms <= 0) return '0:00';
  return formatDuration(Duration(milliseconds: ms));
}
