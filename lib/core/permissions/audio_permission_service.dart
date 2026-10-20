/// File: audio_permission_service.dart
/// Description: Centralized permission management service for accessing local
/// audio and media files on the device. Encapsulates platform-specific permission
/// workflows (Android 13+ READ_MEDIA_AUDIO vs legacy READ_EXTERNAL_STORAGE).
/// Implements in-memory caching of OS version and target permissions to eliminate
/// blocking the main UI thread with repetitive platform channel IPC queries.
///
/// Components / Classes / Functions:
/// - AudioPermissionState: Enum representing normalized permission states.
/// - AudioPermissionService: Singleton service handling audio permission checks and requests.
///   - hasPermission(): Queries if audio access is granted.
///   - checkPermissionStatus(): Evaluates current normalized permission state.
///   - requestPermission(): Initiates platform permission dialog.
///   - openSettings(): Opens application system settings page.
///   - resetCache(): Clears cached hardware/OS properties (visible for testing).
library;

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Normalized state for audio file access permissions.
enum AudioPermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted;

  /// Whether audio files can currently be accessed.
  bool get isGranted => this == AudioPermissionState.granted;
}

/// Central service managing audio and storage permissions across Android and iOS.
class AudioPermissionService {
  // Singleton instance
  static final AudioPermissionService instance = AudioPermissionService._internal();

  AudioPermissionService._internal();

  factory AudioPermissionService() => instance;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  int? _cachedSdkInt;
  Permission? _cachedPermissionTarget;

  /// Cached Android SDK version if resolved.
  int? get cachedSdkInt => _cachedSdkInt;

  /// Cached Permission target if resolved.
  Permission? get cachedPermissionTarget => _cachedPermissionTarget;

  /// Resets in-memory cached hardware properties (primarily used for unit testing).
  @visibleForTesting
  void resetCache() {
    _cachedSdkInt = null;
    _cachedPermissionTarget = null;
  }

  /// Determines the relevant permission target based on platform and OS version.
  ///
  /// Caches the evaluated target in memory to avoid repetitive asynchronous
  /// platform channel IPC calls to [DeviceInfoPlugin] on every check or request.
  Future<Permission> _getAudioPermissionTarget() async {
    if (_cachedPermissionTarget != null) {
      return _cachedPermissionTarget!;
    }

    if (Platform.isAndroid) {
      if (_cachedSdkInt == null) {
        final androidInfo = await _deviceInfo.androidInfo;
        _cachedSdkInt = androidInfo.version.sdkInt;
      }

      // Android 13 (API 33) and above uses granular READ_MEDIA_AUDIO (Permission.audio)
      if (_cachedSdkInt! >= 33) {
        _cachedPermissionTarget = Permission.audio;
      } else {
        // Android 12 and below relies on legacy external storage
        _cachedPermissionTarget = Permission.storage;
      }

      return _cachedPermissionTarget!;
    }

    if (Platform.isIOS) {
      _cachedPermissionTarget = Permission.mediaLibrary;
      return _cachedPermissionTarget!;
    }

    _cachedPermissionTarget = Permission.audio;
    return _cachedPermissionTarget!;
  }

  /// Checks whether audio access permission has been granted.
  Future<bool> hasPermission() async {
    final status = await checkPermissionStatus();
    return status.isGranted;
  }

  /// Evaluates current permission status taking OS version into account.
  Future<AudioPermissionState> checkPermissionStatus() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return AudioPermissionState.granted;
    }

    final permission = await _getAudioPermissionTarget();
    final status = await permission.status;
    return _normalizeStatus(status);
  }

  /// Requests the necessary permissions to read audio files from the device.
  Future<AudioPermissionState> requestPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return AudioPermissionState.granted;
    }

    final permission = await _getAudioPermissionTarget();
    final status = await permission.request();
    return _normalizeStatus(status);
  }

  /// Converts a native [PermissionStatus] into our normalized [AudioPermissionState].
  AudioPermissionState _normalizeStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return AudioPermissionState.granted;
    }
    if (status.isPermanentlyDenied) {
      return AudioPermissionState.permanentlyDenied;
    }
    if (status.isRestricted) {
      return AudioPermissionState.restricted;
    }
    return AudioPermissionState.denied;
  }

  /// Opens the device settings page for this application so the user can grant permissions manually.
  Future<bool> openSettings() async {
    return openAppSettings();
  }
}
