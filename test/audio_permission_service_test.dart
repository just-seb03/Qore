import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/core/permissions/audio_permission_service.dart';

void main() {
  group('AudioPermissionService tests', () {
    setUp(() {
      AudioPermissionService.instance.resetCache();
    });

    test('Initial cache state is null', () {
      final service = AudioPermissionService.instance;
      expect(service.cachedSdkInt, isNull);
      expect(service.cachedPermissionTarget, isNull);
    });

    test('resetCache clears cached values', () {
      final service = AudioPermissionService.instance;
      service.resetCache();
      expect(service.cachedSdkInt, isNull);
      expect(service.cachedPermissionTarget, isNull);
    });

    test('AudioPermissionState enum getters', () {
      expect(AudioPermissionState.granted.isGranted, isTrue);
      expect(AudioPermissionState.denied.isGranted, isFalse);
      expect(AudioPermissionState.permanentlyDenied.isGranted, isFalse);
      expect(AudioPermissionState.restricted.isGranted, isFalse);
    });
  });
}
