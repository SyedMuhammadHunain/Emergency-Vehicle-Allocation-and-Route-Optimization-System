import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

// ---------------------------------------------------------------------------
// ApiResponse – generic result wrapper
// ---------------------------------------------------------------------------

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? validationErrors;

  const ApiResponse({
    this.data,
    this.error,
    this.statusCode,
    this.validationErrors,
  });

  bool get isSuccess => error == null && data != null;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 400;
  bool get isServerError => (statusCode ?? 0) >= 500;
}

// ---------------------------------------------------------------------------
// ApiService – singleton HTTP client for Django REST backend
// ---------------------------------------------------------------------------

class ApiService {
  // ---- singleton & factory ----
  ApiService._internal();
  static ApiService? _instance;
  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  /// Factory constructor ensuring `ApiService()` returns the singleton instance
  factory ApiService({String? baseUrl, http.Client? client}) {
    _instance ??= ApiService._internal();
    if (client != null) _instance!._client = client;
    if (baseUrl != null) _instance!._customBaseUrl = baseUrl;
    return _instance!;
  }

  /// Call once from main.dart or tests if you need to supply custom settings
  static void initialize({String? baseUrl, http.Client? client}) {
    _instance = ApiService._internal();
    if (client != null) _instance!._client = client;
    if (baseUrl != null) _instance!._customBaseUrl = baseUrl;
  }

  // ---- state ----
  http.Client _client = http.Client();
  String? _authToken;
  String? _customBaseUrl;

  String get baseUrl => _customBaseUrl ?? AppConstants.apiBase;
  String? get authToken => _authToken;

  void setAuthToken(String? token) => _authToken = token;
  void clearAuthToken() => _authToken = null;

  // ---- headers ----
  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Token $_authToken';
    }
    return headers;
  }

  // ---- health check ----
  Future<bool> checkHealth({Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.endpointHealth}');
      final response = await _client.get(uri, headers: _buildHeaders()).timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.checkHealth: backend unreachable at $baseUrl ($e)');
      return false;
    }
  }

  // ======================================================================
  // Core HTTP helpers
  // ======================================================================

  Future<ApiResponse<Map<String, dynamic>>> get(
    String path, {
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(timeout);
      return _handleResponse(response);
    } on TimeoutException {
      return const ApiResponse(error: 'Connection timed out', statusCode: 0);
    } catch (e) {
      return ApiResponse(error: 'Connection error: $e', statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client
          .post(uri, headers: _buildHeaders(), body: body != null ? jsonEncode(body) : null)
          .timeout(timeout);
      return _handleResponse(response);
    } on TimeoutException {
      return const ApiResponse(error: 'Connection timed out', statusCode: 0);
    } catch (e) {
      return ApiResponse(error: 'Connection error: $e', statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> put(
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client
          .put(uri, headers: _buildHeaders(), body: body != null ? jsonEncode(body) : null)
          .timeout(timeout);
      return _handleResponse(response);
    } on TimeoutException {
      return const ApiResponse(error: 'Connection timed out', statusCode: 0);
    } catch (e) {
      return ApiResponse(error: 'Connection error: $e', statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> patch(
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client
          .patch(uri, headers: _buildHeaders(), body: body != null ? jsonEncode(body) : null)
          .timeout(timeout);
      return _handleResponse(response);
    } on TimeoutException {
      return const ApiResponse(error: 'Connection timed out', statusCode: 0);
    } catch (e) {
      return ApiResponse(error: 'Connection error: $e', statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> delete(
    String path, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client
          .delete(uri, headers: _buildHeaders())
          .timeout(timeout);
      return _handleResponse(response);
    } on TimeoutException {
      return const ApiResponse(error: 'Connection timed out', statusCode: 0);
    } catch (e) {
      return ApiResponse(error: 'Connection error: $e', statusCode: 0);
    }
  }

  // ---- response handler ----
  ApiResponse<Map<String, dynamic>> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // Try to parse body as JSON map or list
    Map<String, dynamic>? bodyMap;
    try {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          bodyMap = decoded;
        } else if (decoded is List) {
          bodyMap = {'results': decoded};
        }
      }
    } catch (_) {
      bodyMap = {'raw': response.body};
    }

    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponse(data: bodyMap ?? {}, statusCode: statusCode);
    }

    // Error mapping
    String errorMessage;
    Map<String, dynamic>? validationErrors;

    switch (statusCode) {
      case 400:
        errorMessage = _extractErrorMessage(bodyMap, 'Validation error');
        validationErrors = bodyMap;
        break;
      case 401:
        errorMessage = _extractErrorMessage(bodyMap, 'Unauthorized – please log in again');
        break;
      case 403:
        errorMessage = _extractErrorMessage(bodyMap, 'Forbidden – insufficient permissions');
        break;
      case 404:
        errorMessage = _extractErrorMessage(bodyMap, 'Resource not found');
        break;
      case 500:
      case 502:
      case 503:
        errorMessage = _extractErrorMessage(bodyMap, 'Server error – please try again later');
        break;
      default:
        errorMessage = _extractErrorMessage(bodyMap, 'Request failed (HTTP $statusCode)');
    }

    return ApiResponse(
      error: errorMessage,
      statusCode: statusCode,
      validationErrors: validationErrors,
    );
  }

  String _extractErrorMessage(Map<String, dynamic>? body, String fallback) {
    if (body == null) return fallback;
    // Django REST framework common error keys
    if (body.containsKey('detail')) return body['detail'].toString();
    if (body.containsKey('error')) return body['error'].toString();
    if (body.containsKey('message')) return body['message'].toString();
    if (body.containsKey('non_field_errors')) {
      final nfe = body['non_field_errors'];
      if (nfe is List && nfe.isNotEmpty) return nfe.first.toString();
      return nfe.toString();
    }
    // Specific field errors, e.g. {"email": ["This field is required."]}
    for (final key in body.keys) {
      final val = body[key];
      if (val is List && val.isNotEmpty) {
        return '$key: ${val.first}';
      } else if (val is String) {
        return '$key: $val';
      }
    }
    return fallback;
  }

  // ======================================================================
  // Typed API methods matching Django contracts
  // ======================================================================

  // ---- Auth ----

  Future<ApiResponse<Map<String, dynamic>>> login(String email, String password) async {
    final res = await post(
      AppConstants.endpointAuthLogin,
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    if (res.isSuccess && res.data != null) {
      _authToken = res.data!['token'] as String?;
    }
    return res;
  }

  Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await post(
      AppConstants.endpointAuthRegister,
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
      },
    );
    if (res.isSuccess && res.data != null) {
      _authToken = res.data!['token'] as String?;
    }
    return res;
  }

  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    final res = await post(AppConstants.endpointAuthLogout);
    clearAuthToken();
    return res;
  }

  Future<ApiResponse<Map<String, dynamic>>> getMe() async {
    return get(AppConstants.endpointAuthMe);
  }

  Future<ApiResponse<Map<String, dynamic>>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    return post(AppConstants.endpointAuthChangePassword, body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> forgotPassword(String email) async {
    return post(AppConstants.endpointAuthForgotPassword, body: {'email': email.trim().toLowerCase()});
  }

  // ---- Emergencies ----

  Future<ApiResponse<Map<String, dynamic>>> getEmergencies({
    String? status,
    String? category,
    bool? mine,
    bool? active,
    String? query,
    String? ordering,
  }) async {
    final qp = <String, String>{};
    if (status != null && status.isNotEmpty) qp['status'] = status;
    if (category != null && category.isNotEmpty) qp['category'] = category.toUpperCase();
    if (mine == true) qp['mine'] = 'true';
    if (active == true) qp['active'] = 'true';
    if (query != null && query.isNotEmpty) qp['q'] = query;
    if (ordering != null && ordering.isNotEmpty) qp['ordering'] = ordering;
    return get(AppConstants.endpointEmergencies, queryParams: qp.isNotEmpty ? qp : null);
  }

  Future<ApiResponse<Map<String, dynamic>>> getEmergency(int id) async {
    return get('${AppConstants.endpointEmergencies}$id/');
  }

  Future<ApiResponse<Map<String, dynamic>>> createEmergency({
    required String category,
    required int severity,
    required int urgency,
    required int peopleAffected,
    required String description,
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    return post(AppConstants.endpointEmergencies, body: {
      'category': category.toUpperCase(),
      'severity': severity,
      'urgency': urgency,
      'people_affected': peopleAffected,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'location_label': locationLabel,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> updateEmergencyStatus(int id, String status) async {
    return patch('${AppConstants.endpointEmergencies}$id/status/', body: {'status': status.toUpperCase()});
  }

  Future<ApiResponse<Map<String, dynamic>>> assignVehicleToEmergency(
    int emergencyId,
    int vehicleId, {
    String? notes,
  }) async {
    final body = <String, dynamic>{'vehicle_id': vehicleId};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    return post('${AppConstants.endpointEmergencies}$emergencyId/assign/', body: body);
  }

  Future<ApiResponse<Map<String, dynamic>>> getEmergencyCandidates(int id) async {
    return get('${AppConstants.endpointEmergencies}$id/candidates/');
  }

  // ---- Vehicles ----

  Future<ApiResponse<Map<String, dynamic>>> getVehicles({
    String? status,
    String? type,
    bool? available,
  }) async {
    final qp = <String, String>{};
    if (status != null && status.isNotEmpty) qp['status'] = status;
    if (type != null && type.isNotEmpty) qp['type'] = type;
    if (available == true) qp['available'] = 'true';
    return get(AppConstants.endpointVehicles, queryParams: qp.isNotEmpty ? qp : null);
  }

  Future<ApiResponse<Map<String, dynamic>>> getVehicle(int id) async {
    return get('${AppConstants.endpointVehicles}$id/');
  }

  Future<ApiResponse<Map<String, dynamic>>> createVehicle({
    required String licensePlate,
    required String type,
    int? driverId,
    String? stationName,
    int? crewRequired,
    int? fuelLevel,
    List<String>? capabilities,
  }) async {
    final body = <String, dynamic>{
      'license_plate': licensePlate.trim().toUpperCase(),
      'type': type,
    };
    if (driverId != null) body['driver'] = driverId;
    if (stationName != null) body['station_name'] = stationName;
    if (crewRequired != null) body['crew_required'] = crewRequired;
    if (fuelLevel != null) body['fuel_level'] = fuelLevel;
    if (capabilities != null) body['capabilities'] = capabilities;
    return post(AppConstants.endpointVehicles, body: body);
  }

  Future<ApiResponse<Map<String, dynamic>>> updateVehicleStatus(int id, String status) async {
    return patch('${AppConstants.endpointVehicles}$id/', body: {'status': status});
  }

  Future<ApiResponse<Map<String, dynamic>>> updateVehicleLocation(
    int id,
    double lat,
    double lng, {
    String? status,
    int? fuelLevel,
  }) async {
    final body = <String, dynamic>{'latitude': lat, 'longitude': lng};
    if (status != null) body['status'] = status;
    if (fuelLevel != null) body['fuel_level'] = fuelLevel;
    return post('${AppConstants.endpointVehicles}$id/location/', body: body);
  }

  // ---- Resources ----

  Future<ApiResponse<Map<String, dynamic>>> getResources() async {
    return get(AppConstants.endpointResources);
  }

  Future<ApiResponse<Map<String, dynamic>>> createResource({
    required String name,
    required String category,
    required int quantity,
    required String unit,
    int? vehicleId,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'category': category,
      'quantity': quantity,
      'unit': unit,
    };
    if (vehicleId != null) body['vehicle'] = vehicleId;
    return post(AppConstants.endpointResources, body: body);
  }

  Future<ApiResponse<Map<String, dynamic>>> updateResource(int id, {int? quantity, String? status}) async {
    final body = <String, dynamic>{};
    if (quantity != null) body['quantity'] = quantity;
    if (status != null) body['status'] = status;
    return patch('${AppConstants.endpointResources}$id/', body: body);
  }

  Future<ApiResponse<Map<String, dynamic>>> getResourceSummary() async {
    return get('${AppConstants.endpointResources}summary/');
  }

  // ---- Roads ----

  Future<ApiResponse<Map<String, dynamic>>> getRoads({bool? blocked, int? limit, int? offset}) async {
    final qp = <String, String>{};
    if (blocked != null) qp['blocked'] = blocked.toString();
    if (limit != null) qp['limit'] = limit.toString();
    if (offset != null) qp['offset'] = offset.toString();
    return get(AppConstants.endpointRoads, queryParams: qp.isNotEmpty ? qp : null);
  }

  Future<ApiResponse<Map<String, dynamic>>> getRoadNodes() async {
    return get(AppConstants.endpointRoadNodes);
  }

  Future<ApiResponse<Map<String, dynamic>>> toggleRoadBlock(
    int id,
    bool isBlocked, {
    String? reason,
  }) async {
    final body = <String, dynamic>{'is_blocked': isBlocked};
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;
    return post('${AppConstants.endpointRoads}$id/block/', body: body);
  }

  // ---- Map & Planning ----

  Future<ApiResponse<Map<String, dynamic>>> getMapData() async {
    return get(AppConstants.endpointMap);
  }

  Future<ApiResponse<Map<String, dynamic>>> allocate({bool dryRun = false}) async {
    final body = <String, dynamic>{};
    if (dryRun) body['dry_run'] = true;
    return post(AppConstants.endpointAllocate, body: body.isNotEmpty ? body : null);
  }

  Future<ApiResponse<Map<String, dynamic>>> getPlanCurrent() async {
    return get(AppConstants.endpointPlanCurrent);
  }

  Future<ApiResponse<Map<String, dynamic>>> recalculatePlan(String reason) async {
    return post(AppConstants.endpointPlanRecalculate, body: {'reason': reason});
  }

  Future<ApiResponse<Map<String, dynamic>>> getPlanHistory({int limit = 20}) async {
    return get(AppConstants.endpointPlanHistory, queryParams: {'limit': limit.toString()});
  }

  Future<ApiResponse<Map<String, dynamic>>> calculateRoute({
    int? vehicleId,
    int? emergencyId,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
  }) async {
    final body = <String, dynamic>{};
    if (vehicleId != null) body['vehicle_id'] = vehicleId;
    if (emergencyId != null) body['emergency_id'] = emergencyId;
    if (fromLat != null) body['from_lat'] = fromLat;
    if (fromLng != null) body['from_lng'] = fromLng;
    if (toLat != null) body['to_lat'] = toLat;
    if (toLng != null) body['to_lng'] = toLng;
    return post(AppConstants.endpointRoute, body: body);
  }

  // ---- Driver ----

  Future<ApiResponse<Map<String, dynamic>>> getDriverMission() async {
    return get(AppConstants.endpointDriverMission);
  }

  Future<ApiResponse<Map<String, dynamic>>> getDriverHistory() async {
    return get(AppConstants.endpointDriverHistory);
  }

  // ---- Assignments ----

  Future<ApiResponse<Map<String, dynamic>>> getAssignments() async {
    return get(AppConstants.endpointAssignments);
  }

  Future<ApiResponse<Map<String, dynamic>>> completeAssignment(int id) async {
    return post('${AppConstants.endpointAssignments}$id/complete/');
  }

  // ---- Notifications ----

  Future<ApiResponse<Map<String, dynamic>>> getNotifications({
    bool? unread,
    int limit = 50,
  }) async {
    final qp = <String, String>{'limit': limit.toString()};
    if (unread != null) qp['unread'] = unread.toString();
    return get(AppConstants.endpointNotifications, queryParams: qp);
  }

  Future<ApiResponse<Map<String, dynamic>>> markNotificationRead(int id) async {
    return post('${AppConstants.endpointNotifications}$id/read/');
  }

  Future<ApiResponse<Map<String, dynamic>>> markAllNotificationsRead() async {
    return post(AppConstants.endpointNotificationsReadAll);
  }

  // ---- Users (Admin) ----

  Future<ApiResponse<Map<String, dynamic>>> getUsers({String? role}) async {
    final qp = <String, String>{};
    if (role != null && role.isNotEmpty) qp['role'] = role;
    return get(AppConstants.endpointUsers, queryParams: qp.isNotEmpty ? qp : null);
  }

  Future<ApiResponse<Map<String, dynamic>>> createStaffUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    return post(AppConstants.endpointUsers, body: {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'password': password,
      'role': role.toLowerCase(),
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> toggleUserActive(int id) async {
    return post('${AppConstants.endpointUsers}$id/toggle-active/');
  }

  Future<ApiResponse<Map<String, dynamic>>> getUserCounts() async {
    return get(AppConstants.endpointUserCounts);
  }

  // ---- Reports ----

  Future<ApiResponse<Map<String, dynamic>>> getReportsSummary({int days = 30}) async {
    return get(AppConstants.endpointReportsSummary, queryParams: {'days': days.toString()});
  }

  // ---- Audit ----

  Future<ApiResponse<Map<String, dynamic>>> getAuditLogs({String? event}) async {
    final qp = <String, String>{};
    if (event != null && event.isNotEmpty) qp['event'] = event;
    return get(AppConstants.endpointAuditLogs, queryParams: qp.isNotEmpty ? qp : null);
  }
}
