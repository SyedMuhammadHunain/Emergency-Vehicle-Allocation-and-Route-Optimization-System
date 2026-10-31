// Location Service for ResQ
// Wraps device GPS with graceful permission handling and fallback.
// Never crashes on permission denial or unavailable GPS.

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';

class LocationResult {
  final LatLng? position;
  final String? error;
  final bool isPermissionDenied;

  const LocationResult({
    this.position,
    this.error,
    this.isPermissionDenied = false,
  });

  bool get isSuccess => position != null;
}

class LocationService {
  LocationService._();

  /// Default Karachi coordinates fallback
  static const LatLng defaultKarachiLocation = AppConstants.defaultLocation;

  /// Attempts to fetch device GPS location. Returns [LocationResult] safely.
  static Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          error: 'Location services are disabled on this device. Using Karachi default.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            error: 'Location permission was denied. You can select your position manually on the map.',
            isPermissionDenied: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          error: 'Location permissions are permanently denied. Please select location manually on the map.',
          isPermissionDenied: true,
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        position: LatLng(pos.latitude, pos.longitude),
      );
    } catch (e) {
      if (kDebugMode) {
        print('LocationService error: $e');
      }
      return LocationResult(
        error: 'Could not detect device GPS ($e). Please pick location manually.',
      );
    }
  }
}
