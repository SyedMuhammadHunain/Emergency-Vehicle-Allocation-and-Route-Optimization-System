import 'package:flutter/foundation.dart';
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

  // Configurable base URL:
  // 1. Checks build-time environment variable `RESQ_API_BASE_URL`
  // 2. Android emulator default: http://10.0.2.2:8000
  // 3. Web / Windows desktop / macOS / Linux default: http://127.0.0.1:8000
  static String get defaultApiBase {
    const envUrl = String.fromEnvironment('RESQ_API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String apiBase = defaultApiBase;

  // Django REST API Endpoints
  // Auth
  static const String endpointAuth = '/api/auth/';
  static const String endpointAuthLogin = '/api/auth/login/';
  static const String endpointAuthRegister = '/api/auth/register/';
  static const String endpointAuthLogout = '/api/auth/logout/';
  static const String endpointAuthMe = '/api/auth/me/';
  static const String endpointAuthChangePassword = '/api/auth/change-password/';
  static const String endpointAuthForgotPassword = '/api/auth/forgot-password/';

  // Health
  static const String endpointHealth = '/api/health/';

  // Emergencies
  static const String endpointEmergencies = '/api/emergencies/';

  // Vehicles
  static const String endpointVehicles = '/api/vehicles/';

  // Allocation & Planning
  static const String endpointAllocate = '/api/allocate/';
  static const String endpointPlanCurrent = '/api/plan/current/';
  static const String endpointPlanRecalculate = '/api/plan/recalculate/';
  static const String endpointPlanHistory = '/api/plan/history/';

  // Route & Map
  static const String endpointRoute = '/api/route/';
  static const String endpointMap = '/api/map/';

  // Assignments
  static const String endpointAssignments = '/api/assignments/';

  // Resources
  static const String endpointResources = '/api/resources/';

  // Roads
  static const String endpointRoads = '/api/roads/';
  static const String endpointRoadNodes = '/api/roads/nodes/';

  // Users (Admin)
  static const String endpointUsers = '/api/users/';
  static const String endpointUserCounts = '/api/users/counts/';

  // Notifications
  static const String endpointNotifications = '/api/notifications/';
  static const String endpointNotificationsReadAll =
      '/api/notifications/read-all/';

  // Driver
  static const String endpointDriverMission = '/api/driver/mission/';
  static const String endpointDriverHistory = '/api/driver/history/';

  // Reports
  static const String endpointReportsSummary = '/api/reports/summary/';

  // Audit
  static const String endpointAuditLogs = '/api/audit-logs/';
}
