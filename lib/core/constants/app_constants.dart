import 'package:latlong2/latlong.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'ResQ';
  static const String appTagline = 'Closer to Help, Closer to Hope.';

  // Default Map Coordinates: Karachi Central Metropolis
  static const LatLng karachiLocation = LatLng(24.8607, 67.0011);
  static const LatLng defaultLocation = karachiLocation;
  static const double defaultMapZoom = 11.5;
  static const int sosCountdownSeconds = 3;

  // Emergency Hotlines (Karachi / Pakistan)
  static const String policeHotline = '15';
  static const String ambulanceHotline = '1122';
  static const String fireHotline = '16';
  static const String generalHotline = '911';

  // Demo Mock Endpoints (mirrors future Django REST API)
  static const String apiBase = 'http://10.0.2.2:8000';
  static const String endpointAuth = '/api/auth/';
  static const String endpointEmergencies = '/api/emergencies/';
  static const String endpointVehicles = '/api/vehicles/';
  static const String endpointAllocate = '/api/allocate/';
  static const String endpointPlanCurrent = '/api/plan/current/';
  static const String endpointRoute = '/api/route/';
  static const String endpointMap = '/api/map/';
  static const String endpointAssignments = '/api/assignments/';
  static const String endpointResources = '/api/resources/';
  static const String endpointRoads = '/api/roads/';
  static const String endpointUsers = '/api/users/';
}
