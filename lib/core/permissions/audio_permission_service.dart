/// File: audio_permission_service.dart
/// Description: Centralized permission management service for accessing local
/// audio and media files on the device. Encapsulates platform-specific permission
/// workflows (Android 13+ READ_MEDIA_AUDIO vs legacy READ_EXTERNAL_STORAGE).
///
/// Components / Classes / Functions:
/// - AudioPermissionState: Enum representing normalized permission states.
/// - AudioPermissionService: Singleton service handling audio permission checks and requests.
library;

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
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

  /// Determines the relevant permission target based on platform and OS version.
  Future<Permission> _getAudioPermissionTarget() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      // Android 13 (API 33) and above uses granular READ_MEDIA_AUDIO (Permission.audio)
      if (androidInfo.version.sdkInt >= 33) {
        return Permission.audio;
      }
      // Android 12 and below relies on legacy external storage
      return Permission.storage;
    }

    if (Platform.isIOS) {
      return Permission.mediaLibrary;
    }

    return Permission.audio;
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
