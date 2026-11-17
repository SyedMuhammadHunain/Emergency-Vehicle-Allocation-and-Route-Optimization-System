import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/core/constants/app_constants.dart';

void main() {
  group('Mobile APK Map and Android Manifest Verification', () {
    test('AppConstants defines valid package name for tile provider user-agent', () {
      expect(AppConstants.packageName, equals('com.resq.resq'));
      expect(AppConstants.packageName.isNotEmpty, isTrue);
    });

    test('android/app/src/main/AndroidManifest.xml contains required network and location permissions', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue, reason: 'AndroidManifest.xml must exist');

      final content = manifestFile.readAsStringSync();

      expect(
        content.contains('android.permission.INTERNET'),
        isTrue,
        reason: 'Release APK requires INTERNET permission for tile downloading',
      );
      expect(
        content.contains('android.permission.ACCESS_NETWORK_STATE'),
        isTrue,
        reason: 'ACCESS_NETWORK_STATE is required for network status verification',
      );
      expect(
        content.contains('android.permission.ACCESS_FINE_LOCATION'),
        isTrue,
        reason: 'ACCESS_FINE_LOCATION is required for GPS centering on maps',
      );
      expect(
        content.contains('android.permission.ACCESS_COARSE_LOCATION'),
        isTrue,
        reason: 'ACCESS_COARSE_LOCATION is required for location tracking',
      );
      expect(
        content.contains('android:usesCleartextTraffic="true"'),
        isTrue,
        reason: 'usesCleartextTraffic must be true to allow local backend communication over HTTP',
      );
    });
  });
}
