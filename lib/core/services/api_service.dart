import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';
import '../mock/demo_data.dart';
import '../mock/mock_repository.dart';

/// Network result wrapper containing status, data payload, and fallback flag.
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isFromFallback;
  final int? statusCode;

  const ApiResponse({
    this.data,
    this.error,
    this.isFromFallback = false,
    this.statusCode,
  });

  bool get isSuccess => error == null && data != null;
  bool get hasError => error != null;
}

/// Service providing unified HTTP access to Django REST backend with
/// safe automatic offline fallback to in-memory [MockRepository].
class ApiService {
  final String baseUrl;
  final http.Client _client;
  String? _authToken;
  bool _isBackendReachable = false;
  DateTime? _lastHealthCheck;

  ApiService({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? AppConstants.apiBase,
      _client = client ?? http.Client();

  String? get authToken => _authToken;
  bool get isBackendReachable => _isBackendReachable;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

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

  /// Checks if Django backend `/api/health/` is reachable with a short 2s timeout.
  Future<bool> checkHealth({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final now = DateTime.now();
    if (_lastHealthCheck != null &&
        now.difference(_lastHealthCheck!) < const Duration(seconds: 5)) {
      return _isBackendReachable;
    }

    try {
      final uri = Uri.parse('$baseUrl/api/health/');
      final response = await _client.get(uri).timeout(timeout);
      _lastHealthCheck = now;
      _isBackendReachable = response.statusCode == 200;
      return _isBackendReachable;
    } catch (e) {
      _lastHealthCheck = now;
      _isBackendReachable = false;
      debugPrint(
        'ApiService.checkHealth: backend unreachable at $baseUrl ($e)',
      );
      return false;
    }
  }

  Future<http.Response?> _request({
    required String method,
    required String path,
    Map<String, dynamic>? jsonBody,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final isOnline = await checkHealth();
    if (!isOnline) return null;

    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = _buildHeaders();
      final bodyStr = jsonBody != null ? jsonEncode(jsonBody) : null;

      if (method == 'POST') {
        return await _client
            .post(uri, headers: headers, body: bodyStr)
            .timeout(timeout);
      } else if (method == 'PATCH') {
        return await _client
            .patch(uri, headers: headers, body: bodyStr)
            .timeout(timeout);
      } else if (method == 'PUT') {
        return await _client
            .put(uri, headers: headers, body: bodyStr)
            .timeout(timeout);
      } else if (method == 'DELETE') {
        return await _client
            .delete(uri, headers: headers, body: bodyStr)
            .timeout(timeout);
      }
      return await _client.get(uri, headers: headers).timeout(timeout);
    } catch (e) {
      debugPrint('ApiService.$path error: $e');
      return null;
    }
  }

  /// Authenticate user via Django `/api/auth/login/` with fallback to [MockRepository].
  Future<ApiResponse<DemoUserAccount>> login(
    String email,
    String password, {
    required MockRepository mockRepo,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '${AppConstants.endpointAuth}login/',
      jsonBody: {'email': email, 'username': email, 'password': password},
    );

    if (response != null && response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _authToken = data['token'] as String?;
        final userJson = data['user'] as Map<String, dynamic>;

        final account = DemoUserAccount(
          id: 'USR-${userJson['id']}',
          name:
              userJson['name'] ??
              userJson['full_name'] ??
              userJson['username'] ??
              'User',
          email: userJson['email'] ?? email,
          password: '',
          role: (userJson['role'] as String? ?? 'citizen').toLowerCase(),
          phone: userJson['phone'] ?? '',
          isActive: userJson['is_active'] ?? true,
          createdAt: DateTime.now(),
        );

        return ApiResponse(data: account, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.login decode error: $e');
      }
    }

    // Graceful fallback to mock repository
    debugPrint('ApiService: falling back to MockRepository for login.');
    final mockAccount = mockRepo.authenticate(email, password);
    if (mockAccount != null) {
      return ApiResponse(data: mockAccount, isFromFallback: true);
    }

    return const ApiResponse(
      error: 'Invalid email or password.',
      isFromFallback: true,
    );
  }

  /// Fetch vehicles list from `/api/vehicles/` with fallback to [MockRepository].
  Future<ApiResponse<List<DemoVehicle>>> getVehicles({
    required MockRepository mockRepo,
  }) async {
    final response = await _request(
      method: 'GET',
      path: AppConstants.endpointVehicles,
    );

    if (response != null && response.statusCode == 200) {
      try {
        final list = jsonDecode(response.body) as List;
        final vehicles = list.map((item) {
          final map = item as Map<String, dynamic>;
          final lat = (map['latitude'] as num?)?.toDouble() ?? 24.8607;
          final lng = (map['longitude'] as num?)?.toDouble() ?? 67.0011;
          return DemoVehicle(
            id: map['call_sign'] ?? 'VH-${map['id']}',
            licensePlate: map['license_plate'] ?? 'KHI-${map['id']}',
            type: map['vehicle_type'] ?? 'Ambulance',
            status: map['status'] ?? 'Available',
            location: LatLng(lat, lng),
            assignedEmergencyId: map['assigned_emergency_id']?.toString(),
            driverName: map['driver_name'],
          );
        }).toList();

        return ApiResponse(data: vehicles, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.getVehicles decode error: $e');
      }
    }

    return ApiResponse(data: mockRepo.vehicles, isFromFallback: true);
  }

  /// Create emergency report at `/api/emergencies/` with fallback to [MockRepository].
  Future<ApiResponse<DemoEmergency>> reportEmergency({
    required String category,
    required int severity,
    required int urgency,
    required int peopleAffected,
    required String description,
    required LatLng location,
    required String locationLabel,
    required String userId,
    required MockRepository mockRepo,
  }) async {
    final catUpper = category.toUpperCase();
    final normalizedCategory =
        (catUpper == 'TRAFFIC' || catUpper == 'COLLISION')
        ? 'ACCIDENT'
        : catUpper;
    final response = await _request(
      method: 'POST',
      path: AppConstants.endpointEmergencies,
      jsonBody: {
        'title': '$category Emergency at $locationLabel',
        'description': description,
        'category': normalizedCategory,
        'emergency_type': normalizedCategory,
        'severity': severity,
        'urgency': urgency,
        'people_affected': peopleAffected,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'location_label': locationLabel,
        'address': locationLabel,
      },
    );

    if (response != null &&
        (response.statusCode == 201 || response.statusCode == 200)) {
      try {
        final map = jsonDecode(response.body) as Map<String, dynamic>;
        final createdEmergency = DemoEmergency(
          id: map['code'] ?? map['tracking_number'] ?? 'EM-${map['id']}',
          category: category,
          status: EmergencyStatus.reported,
          severity: severity,
          urgency: urgency,
          peopleAffected: peopleAffected,
          description: map['description'] ?? description,
          location: location,
          locationLabel: locationLabel,
          reportedAt: DateTime.now(),
          reportedByUserId: userId,
        );

        mockRepo.addEmergency(createdEmergency);

        return ApiResponse(
          data: createdEmergency,
          statusCode: response.statusCode,
        );
      } catch (e) {
        debugPrint('ApiService.reportEmergency decode error: $e');
      }
    }

    // Offline fallback to mock repo
    final mockCreated = mockRepo.reportEmergency(
      category: category,
      severity: severity,
      urgency: urgency,
      peopleAffected: peopleAffected,
      description: description,
      location: location,
      locationLabel: locationLabel,
      userId: userId,
    );

    return ApiResponse(data: mockCreated, isFromFallback: true);
  }

  /// Trigger multi-criteria 0/1 Knapsack allocation at `/api/allocate/`.
  Future<ApiResponse<Map<String, dynamic>>> triggerAllocation({
    int? emergencyId,
  }) async {
    final response = await _request(
      method: 'POST',
      path: AppConstants.endpointAllocate,
      jsonBody: emergencyId != null ? {'emergency_id': emergencyId} : null,
      timeout: const Duration(seconds: 8),
    );

    if (response != null && response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(data: data, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.triggerAllocation decode error: $e');
      }
    }

    return const ApiResponse(
      error: 'Backend allocation service offline.',
      isFromFallback: true,
    );
  }

  /// Fetch emergencies from `/api/emergencies/` with fallback to [MockRepository].
  Future<ApiResponse<List<DemoEmergency>>> getEmergencies({
    MockRepository? mockRepo,
    String? userId,
    String? userEmail,
    String? userName,
    String? status,
    String? category,
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (userId != null && userId.isNotEmpty) {
      queryParams['mine'] = 'true';
    }

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final response = await _request(
      method: 'GET',
      path: '${AppConstants.endpointEmergencies}$queryString',
      timeout: const Duration(seconds: 8),
    );

    if (response != null && response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['results'] is List) {
          list = decoded['results'] as List;
        } else {
          list = [];
        }

        final emergencies = list.map((item) {
          final map = item as Map<String, dynamic>;
          final lat = (map['latitude'] as num?)?.toDouble() ?? 24.8607;
          final lng = (map['longitude'] as num?)?.toDouble() ?? 67.0011;
          final repId = map['reported_by']?.toString() ?? (userId ?? '');
          DateTime repAt;
          try {
            repAt = map['created_at'] != null
                ? DateTime.parse(map['created_at'].toString())
                : DateTime.now();
          } catch (_) {
            repAt = DateTime.now();
          }

          DemoVehicle? v;
          if (map['assigned_vehicle'] is Map<String, dynamic>) {
            final vMap = map['assigned_vehicle'] as Map<String, dynamic>;
            v = DemoVehicle(
              id: vMap['call_sign'] ?? 'VH-${vMap['id']}',
              licensePlate: vMap['license_plate'] ?? 'KHI-${vMap['id']}',
              type: vMap['vehicle_type'] ?? 'Ambulance',
              status: vMap['status'] ?? 'Assigned',
              location: LatLng(lat, lng),
            );
          }

          return DemoEmergency(
            id: map['code'] ?? map['tracking_number'] ?? 'EM-${map['id']}',
            category: map['category']?.toString().toUpperCase() ?? 'OTHER',
            status:
                map['status']?.toString().toUpperCase() ??
                EmergencyStatus.reported,
            severity: (map['severity'] as num?)?.toInt() ?? 3,
            urgency: (map['urgency'] as num?)?.toInt() ?? 3,
            peopleAffected: (map['people_affected'] as num?)?.toInt() ?? 1,
            description: map['description']?.toString() ?? '',
            location: LatLng(lat, lng),
            locationLabel:
                map['location_label']?.toString() ?? 'Karachi Grid Location',
            reportedAt: repAt,
            reportedByUserId: repId,
            assignedVehicle: v,
            allocationReason: map['allocation_reason']?.toString(),
          );
        }).toList();

        if (mockRepo != null) {
          for (final em in emergencies) {
            mockRepo.addEmergency(em);
          }
        }

        return ApiResponse(data: emergencies, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.getEmergencies decode error: $e');
      }
    }

    final fallbackEmergencies = mockRepo != null
        ? mockRepo.getEmergenciesForUser(
            userId ?? '',
            userEmail: userEmail,
            userName: userName,
          )
        : <DemoEmergency>[];

    return ApiResponse(
      data: fallbackEmergencies,
      isFromFallback: true,
      error: response != null && response.statusCode != 200
          ? 'Failed to fetch incident reports from server (${response.statusCode})'
          : null,
    );
  }

  /// Fetch a single emergency by ID or code at `/api/emergencies/{id}/`.
  Future<ApiResponse<DemoEmergency>> getEmergencyById(
    String emergencyId, {
    MockRepository? mockRepo,
  }) async {
    final cleanId = emergencyId
        .replaceFirst('EM-', '')
        .replaceFirst('2026-', '');
    final response = await _request(
      method: 'GET',
      path: '${AppConstants.endpointEmergencies}$cleanId/',
      timeout: const Duration(seconds: 8),
    );

    if (response != null && response.statusCode == 200) {
      try {
        final map = jsonDecode(response.body) as Map<String, dynamic>;
        final lat = (map['latitude'] as num?)?.toDouble() ?? 24.8607;
        final lng = (map['longitude'] as num?)?.toDouble() ?? 67.0011;
        final repId = map['reported_by']?.toString() ?? '';
        DateTime repAt;
        try {
          repAt = map['created_at'] != null
              ? DateTime.parse(map['created_at'].toString())
              : DateTime.now();
        } catch (_) {
          repAt = DateTime.now();
        }

        DemoVehicle? v;
        if (map['assigned_vehicle'] is Map<String, dynamic>) {
          final vMap = map['assigned_vehicle'] as Map<String, dynamic>;
          v = DemoVehicle(
            id: vMap['call_sign'] ?? 'VH-${vMap['id']}',
            licensePlate: vMap['license_plate'] ?? 'KHI-${vMap['id']}',
            type: vMap['vehicle_type'] ?? 'Ambulance',
            status: vMap['status'] ?? 'Assigned',
            location: LatLng(lat, lng),
          );
        }

        final emergency = DemoEmergency(
          id: map['code'] ?? map['tracking_number'] ?? 'EM-${map['id']}',
          category: map['category']?.toString().toUpperCase() ?? 'OTHER',
          status:
              map['status']?.toString().toUpperCase() ??
              EmergencyStatus.reported,
          severity: (map['severity'] as num?)?.toInt() ?? 3,
          urgency: (map['urgency'] as num?)?.toInt() ?? 3,
          peopleAffected: (map['people_affected'] as num?)?.toInt() ?? 1,
          description: map['description']?.toString() ?? '',
          location: LatLng(lat, lng),
          locationLabel:
              map['location_label']?.toString() ?? 'Karachi Grid Location',
          reportedAt: repAt,
          reportedByUserId: repId,
          assignedVehicle: v,
          allocationReason: map['allocation_reason']?.toString(),
        );

        if (mockRepo != null) {
          mockRepo.addEmergency(emergency);
        }

        return ApiResponse(data: emergency, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.getEmergencyById decode error: $e');
      }
    }

    final fallback = mockRepo?.getEmergencyById(emergencyId);
    return ApiResponse(
      data: fallback,
      isFromFallback: true,
      error: fallback == null ? 'Emergency not found.' : null,
    );
  }

  /// Citizen registration via `/api/auth/register/` with fallback to [MockRepository].
  Future<ApiResponse<DemoUserAccount>> registerCitizen({
    required String name,
    required String email,
    required String password,
    required String phone,
    required MockRepository mockRepo,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '${AppConstants.endpointAuth}register/',
      jsonBody: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'phone': phone.trim(),
      },
    );

    if (response != null &&
        (response.statusCode == 201 || response.statusCode == 200)) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _authToken = data['token'] as String?;
        final userJson = data['user'] as Map<String, dynamic>? ?? data;

        final account = DemoUserAccount(
          id: 'USR-${userJson['id'] ?? 'CIT-NEW'}',
          name: userJson['name'] ?? name,
          email: userJson['email'] ?? email,
          password: password,
          role: 'citizen',
          phone: userJson['phone'] ?? phone,
          isActive: userJson['is_active'] ?? true,
          createdAt: DateTime.now(),
        );

        mockRepo.addAccount(account);
        return ApiResponse(data: account, statusCode: response.statusCode);
      } catch (e) {
        debugPrint('ApiService.registerCitizen decode error: $e');
      }
    }

    final localAccount = mockRepo.registerCitizen(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
    return ApiResponse(
      data: localAccount,
      isFromFallback: true,
      error: response != null && response.statusCode >= 400
          ? 'Registration failed (${response.statusCode})'
          : null,
    );
  }

  /// Fetch own profile via `/api/auth/me/` with fallback to [MockRepository].
  Future<ApiResponse<DemoUserAccount>> getMe({
    required MockRepository mockRepo,
    String? fallbackEmail,
  }) async {
    final response = await _request(
      method: 'GET',
      path: '${AppConstants.endpointAuth}me/',
    );

    if (response != null && response.statusCode == 200) {
      try {
        final userJson = jsonDecode(response.body) as Map<String, dynamic>;
        final account = DemoUserAccount(
          id: 'USR-${userJson['id']}',
          name: userJson['name'] ?? userJson['full_name'] ?? 'User',
          email: userJson['email'] ?? fallbackEmail ?? '',
          password: '',
          role: (userJson['role'] as String? ?? 'citizen').toLowerCase(),
          phone: userJson['phone'] ?? '',
          isActive: userJson['is_active'] ?? true,
          createdAt: DateTime.now(),
        );
        return ApiResponse(data: account, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.getMe decode error: $e');
      }
    }

    if (fallbackEmail != null) {
      final local = mockRepo.accounts.where(
        (a) => a.email.toLowerCase() == fallbackEmail.toLowerCase(),
      );
      if (local.isNotEmpty) {
        return ApiResponse(data: local.first, isFromFallback: true);
      }
    }

    return const ApiResponse(error: 'Profile not found.', isFromFallback: true);
  }

  /// Update own profile (name, phone) via `/api/auth/me/` with fallback to [MockRepository].
  Future<ApiResponse<DemoUserAccount>> updateProfile({
    required String name,
    required String phone,
    required MockRepository mockRepo,
    String? currentEmail,
  }) async {
    final response = await _request(
      method: 'PATCH',
      path: '${AppConstants.endpointAuth}me/',
      jsonBody: {'name': name.trim(), 'phone': phone.trim()},
    );

    if (response != null && response.statusCode == 200) {
      try {
        final userJson = jsonDecode(response.body) as Map<String, dynamic>;
        final account = DemoUserAccount(
          id: 'USR-${userJson['id']}',
          name: userJson['name'] ?? name,
          email: userJson['email'] ?? currentEmail ?? '',
          password: '',
          role: (userJson['role'] as String? ?? 'citizen').toLowerCase(),
          phone: userJson['phone'] ?? phone,
          isActive: userJson['is_active'] ?? true,
          createdAt: DateTime.now(),
        );
        return ApiResponse(data: account, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.updateProfile decode error: $e');
      }
    }

    if (currentEmail != null) {
      final existing = mockRepo.accounts.where(
        (a) => a.email.toLowerCase() == currentEmail.toLowerCase(),
      );
      if (existing.isNotEmpty) {
        final updated = existing.first.copyWith(name: name, phone: phone);
        mockRepo.addAccount(updated);
        return ApiResponse(data: updated, isFromFallback: true);
      }
    }

    return const ApiResponse(
      error: 'Failed to update profile.',
      isFromFallback: true,
    );
  }

  /// Fetch users list from `/api/users/` (admin) with fallback to [MockRepository].
  Future<ApiResponse<List<DemoUserAccount>>> getUsers({
    String? role,
    MockRepository? mockRepo,
  }) async {
    final query = (role != null && role.isNotEmpty && role != 'ALL')
        ? '?role=${Uri.encodeComponent(role.toLowerCase())}'
        : '';
    final response = await _request(
      method: 'GET',
      path: '${AppConstants.endpointUsers}$query',
      timeout: const Duration(seconds: 8),
    );

    if (response != null && response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['results'] is List) {
          list = decoded['results'] as List;
        } else {
          list = [];
        }

        final users = list
            .map((item) {
              final map = item as Map<String, dynamic>;
              DateTime createdAt;
              try {
                createdAt = map['created_at'] != null
                    ? DateTime.parse(map['created_at'].toString())
                    : DateTime.now();
              } catch (_) {
                createdAt = DateTime.now();
              }
              return DemoUserAccount(
                id: 'USR-${map['id']}',
                name:
                    map['name'] ??
                    map['full_name'] ??
                    map['username'] ??
                    'User',
                email: map['email'] ?? '',
                password: '',
                role: (map['role'] as String? ?? 'citizen').toLowerCase(),
                phone: map['phone'] ?? '',
                isActive: map['is_active'] ?? true,
                createdAt: createdAt,
              );
            })
            .where(
              (u) =>
                  u.id != 'USR-CIT-001' &&
                  u.name.toLowerCase() != 'demo citizen' &&
                  u.email.toLowerCase() != 'citizen@resq.com',
            )
            .toList();

        return ApiResponse(data: users, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.getUsers decode error: $e');
      }
    }

    final fallbackAccounts =
        (mockRepo != null ? mockRepo.accounts : <DemoUserAccount>[])
            .where(
              (u) =>
                  u.id != 'USR-CIT-001' &&
                  u.name.toLowerCase() != 'demo citizen' &&
                  u.email.toLowerCase() != 'citizen@resq.com',
            )
            .where(
              (u) =>
                  role == null ||
                  role == 'ALL' ||
                  u.role.toLowerCase() == role.toLowerCase(),
            )
            .toList();

    return ApiResponse(
      data: fallbackAccounts,
      isFromFallback: true,
      error: response != null && response.statusCode != 200
          ? 'Failed to fetch users from server (${response.statusCode})'
          : null,
    );
  }

  /// Provision a staff account (dispatcher or driver) via `/api/users/` with fallback to [MockRepository].
  Future<ApiResponse<DemoUserAccount>> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    required MockRepository mockRepo,
  }) async {
    final response = await _request(
      method: 'POST',
      path: AppConstants.endpointUsers,
      jsonBody: {
        'name': name.trim(),
        'full_name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role.toLowerCase(),
        'phone': phone.trim(),
      },
    );

    if (response != null &&
        (response.statusCode == 201 || response.statusCode == 200)) {
      try {
        final map = jsonDecode(response.body) as Map<String, dynamic>;
        final newStaff = DemoUserAccount(
          id: 'USR-${map['id'] ?? 'STAFF'}',
          name: map['name'] ?? name,
          email: map['email'] ?? email,
          password: password,
          role: role.toLowerCase(),
          phone: map['phone'] ?? phone,
          isActive: map['is_active'] ?? true,
          createdAt: DateTime.now(),
        );
        mockRepo.addAccount(newStaff);
        return ApiResponse(data: newStaff, statusCode: response.statusCode);
      } catch (e) {
        debugPrint('ApiService.createStaffAccount decode error: $e');
      }
    }

    final created = mockRepo.createStaffAccount(
      name: name,
      email: email,
      password: password,
      role: role.toLowerCase(),
      phone: phone,
    );
    return ApiResponse(data: created, isFromFallback: true);
  }

  /// Fetch equipment and crew resources via `/api/resources/` with fallback to [MockRepository].
  Future<ApiResponse<List<DemoResource>>> getResources({
    required MockRepository mockRepo,
  }) async {
    final response = await _request(
      method: 'GET',
      path: AppConstants.endpointResources,
    );

    if (response != null && response.statusCode == 200) {
      try {
        final list = jsonDecode(response.body) as List;
        final resources = list.map((item) {
          final map = item as Map<String, dynamic>;
          return DemoResource(
            id: 'RES-${map['id']}',
            name: map['name'] ?? 'Resource',
            category: map['category'] ?? 'Equipment',
            quantity: (map['quantity'] as num?)?.toInt() ?? 1,
            unit: map['unit'] ?? 'units',
            associatedVehicleId: map['assigned_vehicle_id']?.toString(),
          );
        }).toList();
        return ApiResponse(data: resources, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.getResources decode error: $e');
      }
    }

    return ApiResponse(data: mockRepo.resources, isFromFallback: true);
  }

  /// Request route path via `/api/route/` with fallback estimation.
  Future<ApiResponse<Map<String, dynamic>>> getRoute({
    int? vehicleId,
    int? emergencyId,
    LatLng? from,
    LatLng? to,
    MockRepository? mockRepo,
  }) async {
    final body = <String, dynamic>{};
    if (vehicleId != null && emergencyId != null) {
      body['vehicle_id'] = vehicleId;
      body['emergency_id'] = emergencyId;
    } else if (from != null && to != null) {
      body['from_lat'] = from.latitude;
      body['from_lng'] = from.longitude;
      body['to_lat'] = to.latitude;
      body['to_lng'] = to.longitude;
    }

    final response = await _request(
      method: 'POST',
      path: '/api/route/',
      jsonBody: body,
      timeout: const Duration(seconds: 8),
    );

    if (response != null && response.statusCode == 200) {
      try {
        final map = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(data: map, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.getRoute decode error: $e');
      }
    }

    return ApiResponse(
      data: {
        'total_time': 8.5,
        'distance_km': 4.2,
        'route_coords': [
          [from?.latitude ?? 24.8607, from?.longitude ?? 67.0011],
          [to?.latitude ?? 24.8720, to?.longitude ?? 67.0104],
        ],
      },
      isFromFallback: true,
      error: response != null && response.statusCode != 200
          ? 'Route calculation failed'
          : null,
    );
  }

  /// Update emergency status via `/api/emergencies/{id}/status/` with fallback to [MockRepository].
  Future<ApiResponse<bool>> updateEmergencyStatus({
    required String emergencyId,
    required String status,
    MockRepository? mockRepo,
  }) async {
    final cleanId = emergencyId
        .replaceFirst('EM-', '')
        .replaceFirst('2026-', '');
    final response = await _request(
      method: 'PATCH',
      path: '${AppConstants.endpointEmergencies}$cleanId/status/',
      jsonBody: {'status': status.toUpperCase()},
    );

    if (response != null && response.statusCode == 200) {
      if (mockRepo != null) {
        mockRepo.updateEmergencyStatus(emergencyId, status.toUpperCase());
      }
      return const ApiResponse(data: true, statusCode: 200);
    }

    if (mockRepo != null) {
      mockRepo.updateEmergencyStatus(emergencyId, status.toUpperCase());
      return const ApiResponse(data: true, isFromFallback: true);
    }

    return const ApiResponse(
      data: false,
      error: 'Update status failed',
      isFromFallback: true,
    );
  }

  /// Fetch driver active mission via `/api/driver/mission/` with fallback to [MockRepository].
  Future<ApiResponse<Map<String, dynamic>?>> getDriverMission({
    MockRepository? mockRepo,
  }) async {
    final response = await _request(
      method: 'GET',
      path: '/api/driver/mission/',
      timeout: const Duration(seconds: 8),
    );

    if (response != null && response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(data: data, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.getDriverMission decode error: $e');
      }
    }

    return const ApiResponse(data: null, isFromFallback: true);
  }

  /// Fetch system notifications via `/api/notifications/` with fallback to [MockRepository].
  Future<ApiResponse<List<DemoNotification>>> getNotifications({
    required MockRepository mockRepo,
    String? role,
  }) async {
    final response = await _request(
      method: 'GET',
      path: '/api/notifications/',
      timeout: const Duration(seconds: 8),
    );

    if (response != null && response.statusCode == 200) {
      try {
        final list = jsonDecode(response.body) as List;
        final notifications = list.map((item) {
          final map = item as Map<String, dynamic>;
          DateTime createdAt;
          try {
            createdAt = map['created_at'] != null
                ? DateTime.parse(map['created_at'].toString())
                : DateTime.now();
          } catch (_) {
            createdAt = DateTime.now();
          }
          return DemoNotification(
            id: 'NOTIF-${map['id']}',
            title: map['title'] ?? 'ResQ Notification',
            message: map['message'] ?? '',
            createdAt: createdAt,
            isRead: map['is_read'] ?? false,
            targetRole: map['target_role'] ?? 'citizen',
          );
        }).toList();

        return ApiResponse(data: notifications, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.getNotifications decode error: $e');
      }
    }

    return ApiResponse(data: mockRepo.notifications, isFromFallback: true);
  }

  /// Fetch reports summary via `/api/reports/summary/` with fallback to [MockRepository].
  Future<ApiResponse<Map<String, dynamic>>> getReportsSummary({
    MockRepository? mockRepo,
  }) async {
    final response = await _request(
      method: 'GET',
      path: '/api/reports/summary/',
      timeout: const Duration(seconds: 8),
    );

    if (response != null && response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse(data: data, statusCode: 200);
      } catch (e) {
        debugPrint('ApiService.getReportsSummary decode error: $e');
      }
    }

    return ApiResponse(
      data: {
        'total_emergencies': mockRepo?.emergencies.length ?? 0,
        'resolved': mockRepo?.resolvedEmergencies.length ?? 0,
        'active': mockRepo?.activeEmergencies.length ?? 0,
      },
      isFromFallback: true,
    );
  }
}
