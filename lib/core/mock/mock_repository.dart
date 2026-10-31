// DEMO DATA REPOSITORY — In-memory reactive state for ResQ frontend prototype.
// Shared across all four roles: Citizen, Dispatcher, Driver, Admin.
// Fully prepared for future Django REST Framework API client integration.

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'demo_data.dart';

class MockRepository extends ChangeNotifier {
  final List<DemoUserAccount> _accounts = [];
  final List<DemoEmergency> _emergencies = [];
  final List<DemoNotification> _notifications = [];
  final List<DemoVehicle> _vehicles = [];
  final List<DemoResource> _resources = [];
  final List<DemoBlockedRoad> _blockedRoads = [];

  // Default simulated location: Karachi central
  LatLng _userLocation = const LatLng(24.8607, 67.0011);
  String _userLocationLabel = 'Saddar, Karachi (Default)';

  MockRepository() {
    _seedInitialData();
  }

  void _seedInitialData() {
    _accounts.addAll(kPredefinedDemoAccounts);
    _vehicles.addAll(kDemoVehicles);
    _resources.addAll(kDemoResources);
    _blockedRoads.addAll(kDemoBlockedRoads);
    _emergencies.addAll(buildDemoEmergencies('USR-CIT-001'));
    _notifications.addAll(buildDemoNotifications('USR-CIT-001'));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ───────────────────────────────────────────────────────────────────────────
  List<DemoUserAccount> get accounts => List.unmodifiable(_accounts);
  List<DemoEmergency> get emergencies => List.unmodifiable(_emergencies);
  List<DemoNotification> get notifications => List.unmodifiable(_notifications);
  List<DemoVehicle> get vehicles => List.unmodifiable(_vehicles);
  List<DemoResource> get resources => List.unmodifiable(_resources);
  List<DemoBlockedRoad> get blockedRoads => List.unmodifiable(_blockedRoads);
  LatLng get userLocation => _userLocation;
  String get userLocationLabel => _userLocationLabel;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  int get totalCitizensCount => _accounts.where((u) => u.role == 'citizen').length;
  int get totalDispatchersCount => _accounts.where((u) => u.role == 'dispatcher').length;
  int get totalDriversCount => _accounts.where((u) => u.role == 'driver').length;

  List<DemoVehicle> get availableVehicles =>
      _vehicles.where((v) => v.status == 'Available').toList();
  List<DemoVehicle> get busyVehicles =>
      _vehicles.where((v) => v.status == 'Busy' || v.status == 'En Route').toList();

  List<DemoEmergency> get activeEmergencies => _emergencies
      .where((e) =>
          e.status == EmergencyStatus.reported ||
          e.status == EmergencyStatus.assigned ||
          e.status == EmergencyStatus.enRoute ||
          e.status == EmergencyStatus.onScene)
      .toList();

  List<DemoEmergency> get pendingEmergencies =>
      _emergencies.where((e) => e.status == EmergencyStatus.reported).toList();

  List<DemoEmergency> get assignedEmergencies => _emergencies
      .where((e) =>
          e.status == EmergencyStatus.assigned ||
          e.status == EmergencyStatus.enRoute ||
          e.status == EmergencyStatus.onScene)
      .toList();

  List<DemoEmergency> get resolvedEmergencies => _emergencies
      .where((e) => e.status == EmergencyStatus.resolved)
      .toList();

  List<DemoEmergency> get recentEmergencies =>
      _emergencies.take(5).toList();

  // ───────────────────────────────────────────────────────────────────────────
  // AUTHENTICATION & USER MANAGEMENT
  // ───────────────────────────────────────────────────────────────────────────

  /// Validates credentials against stored accounts.
  DemoUserAccount? authenticate(String email, String password) {
    try {
      final cleanEmail = email.trim().toLowerCase();
      return _accounts.firstWhere(
        (u) =>
            u.email.toLowerCase() == cleanEmail &&
            u.password == password.trim() &&
            u.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  /// Public Sign Up: ONLY citizens can register publicly.
  DemoUserAccount registerCitizen({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    // Check if account already exists
    final existing = _accounts.where((u) => u.email.toLowerCase() == cleanEmail);
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final newAccount = DemoUserAccount(
      id: 'USR-CIT-${1000 + Random().nextInt(9000)}',
      name: name.trim(),
      email: cleanEmail,
      password: password,
      role: 'citizen', // Enforced citizen only
      phone: phone.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    _accounts.add(newAccount);
    notifyListeners();
    return newAccount;
  }

  /// Admin Staff Management: Creates Dispatcher or Driver accounts.
  DemoUserAccount createStaffAccount({
    required String name,
    required String email,
    required String password,
    required String role, // 'dispatcher' or 'driver'
    required String phone,
  }) {
    if (role != 'dispatcher' && role != 'driver') {
      throw ArgumentError('Staff role must be either dispatcher or driver');
    }

    final cleanEmail = email.trim().toLowerCase();
    final newStaff = DemoUserAccount(
      id: 'USR-${role.substring(0, 3).toUpperCase()}-${1000 + Random().nextInt(9000)}',
      name: name.trim(),
      email: cleanEmail,
      password: password,
      role: role,
      phone: phone.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    _accounts.add(newStaff);

    _notifications.insert(
      0,
      DemoNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Staff Provisioned',
        message: 'Account for ${newStaff.name} ($role) has been created by Administrator.',
        createdAt: DateTime.now(),
        isRead: false,
        targetRole: 'admin',
      ),
    );

    notifyListeners();
    return newStaff;
  }

  void toggleUserStatus(String accountId) {
    final idx = _accounts.indexWhere((u) => u.id == accountId);
    if (idx != -1) {
      _accounts[idx].isActive = !_accounts[idx].isActive;
      notifyListeners();
    }
  }

  List<DemoUserAccount> getUsersByRole(String role) {
    return _accounts.where((u) => u.role == role).toList();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // EMERGENCY MANAGEMENT
  // ───────────────────────────────────────────────────────────────────────────

  DemoEmergency? getEmergencyById(String id) {
    try {
      return _emergencies.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void setUserLocation(LatLng location, [String? label]) {
    _userLocation = location;
    if (label != null) {
      _userLocationLabel = label;
    } else {
      _userLocationLabel =
          'Lat ${location.latitude.toStringAsFixed(4)}, Lng ${location.longitude.toStringAsFixed(4)}';
    }
    notifyListeners();
  }

  DemoEmergency reportEmergency({
    required String category,
    required int severity,
    required int urgency,
    required int peopleAffected,
    required String description,
    required LatLng location,
    required String locationLabel,
    required String userId,
  }) {
    final randomIdNum = 1000 + Random().nextInt(9000);
    final newId = 'EM-2026-$randomIdNum';

    final emergency = DemoEmergency(
      id: newId,
      category: category,
      status: EmergencyStatus.reported,
      severity: severity,
      urgency: urgency,
      peopleAffected: peopleAffected,
      description: description,
      location: location,
      locationLabel: locationLabel,
      reportedAt: DateTime.now(),
      reportedByUserId: userId,
      allocationReason: 'Awaiting Dispatcher Review: Priority rating based on severity $severity and urgency $urgency.',
    );

    _emergencies.insert(0, emergency);

    // Notification for Dispatchers & Citizen
    _notifications.insert(
      0,
      DemoNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Emergency Reported ($newId)',
        message: 'New $category emergency in $locationLabel requires triage.',
        createdAt: DateTime.now(),
        isRead: false,
        relatedEmergencyId: newId,
        targetRole: 'dispatcher',
      ),
    );

    notifyListeners();
    return emergency;
  }

  void updateEmergencyStatus(String id, String newStatus) {
    final idx = _emergencies.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _emergencies[idx].status = newStatus;

      // If resolved, free up any assigned vehicle
      if (newStatus == EmergencyStatus.resolved && _emergencies[idx].assignedVehicle != null) {
        final vId = _emergencies[idx].assignedVehicle!.id;
        final vIdx = _vehicles.indexWhere((v) => v.id == vId);
        if (vIdx != -1) {
          _vehicles[vIdx].status = 'Available';
          _vehicles[vIdx].assignedEmergencyId = null;
        }
      }

      _notifications.insert(
        0,
        DemoNotification(
          id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Status Update: $id',
          message: 'Report $id is now marked as $newStatus. [SIMULATED DEMO]',
          createdAt: DateTime.now(),
          isRead: false,
          relatedEmergencyId: id,
          targetRole: 'all',
        ),
      );

      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DISPATCHER ALLOCATION & VEHICLE ASSIGNMENT
  // ───────────────────────────────────────────────────────────────────────────

  /// Assigns a vehicle to an emergency (DP Allocation Confirmation)
  void assignVehicleToEmergency(String emergencyId, String vehicleId, {String? notes}) {
    final eIdx = _emergencies.indexWhere((e) => e.id == emergencyId);
    final vIdx = _vehicles.indexWhere((v) => v.id == vehicleId);

    if (eIdx != -1 && vIdx != -1) {
      final vehicle = _vehicles[vIdx];
      vehicle.status = 'Busy';
      vehicle.assignedEmergencyId = emergencyId;

      _emergencies[eIdx].status = EmergencyStatus.assigned;
      _emergencies[eIdx].assignedVehicle = vehicle;
      _emergencies[eIdx].allocationReason = notes ?? 'Dispatched based on DP minimum response latency.';

      // Notify Driver & Citizen
      _notifications.insert(
        0,
        DemoNotification(
          id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Mission Dispatched',
          message: 'Emergency $emergencyId assigned to unit ${vehicle.licensePlate}.',
          createdAt: DateTime.now(),
          isRead: false,
          relatedEmergencyId: emergencyId,
          targetRole: 'driver',
        ),
      );

      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DRIVER MISSION PROGRESSION
  // ───────────────────────────────────────────────────────────────────────────

  /// Finds the currently assigned active mission for Driver
  DemoEmergency? getActiveMissionForDriver([String? driverName]) {
    try {
      return _emergencies.firstWhere(
        (e) =>
            (e.status == EmergencyStatus.assigned ||
             e.status == EmergencyStatus.enRoute ||
             e.status == EmergencyStatus.onScene) &&
            e.assignedVehicle != null,
      );
    } catch (_) {
      return null;
    }
  }

  List<DemoEmergency> getMissionHistoryForDriver([String? driverName]) {
    return _emergencies
        .where((e) => e.status == EmergencyStatus.resolved && e.assignedVehicle != null)
        .toList();
  }

  /// Driver transitions mission status
  void updateMissionStatus(String emergencyId, String newStatus) {
    final idx = _emergencies.indexWhere((e) => e.id == emergencyId);
    if (idx != -1) {
      _emergencies[idx].status = newStatus;

      // Update vehicle status accordingly
      if (_emergencies[idx].assignedVehicle != null) {
        final vId = _emergencies[idx].assignedVehicle!.id;
        final vIdx = _vehicles.indexWhere((v) => v.id == vId);
        if (vIdx != -1) {
          if (newStatus == EmergencyStatus.enRoute) {
            _vehicles[vIdx].status = 'En Route';
          } else if (newStatus == EmergencyStatus.onScene) {
            _vehicles[vIdx].status = 'Busy';
          } else if (newStatus == EmergencyStatus.resolved) {
            _vehicles[vIdx].status = 'Available';
            _vehicles[vIdx].assignedEmergencyId = null;
          }
        }
      }

      _notifications.insert(
        0,
        DemoNotification(
          id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Mission Update: $newStatus',
          message: 'Emergency $emergencyId is now $newStatus. [SIMULATED PROGRESSION]',
          createdAt: DateTime.now(),
          isRead: false,
          relatedEmergencyId: emergencyId,
          targetRole: 'all',
        ),
      );

      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FLEET & RESOURCE MANAGEMENT (Admin / Dispatcher)
  // ───────────────────────────────────────────────────────────────────────────

  void addVehicle({
    required String licensePlate,
    required String type,
    String? driverName,
  }) {
    final newId = 'VH-00${_vehicles.length + 1}';
    final vehicle = DemoVehicle(
      id: newId,
      licensePlate: licensePlate.toUpperCase(),
      type: type,
      status: 'Available',
      location: const LatLng(24.8607, 67.0011),
      driverName: driverName,
    );

    _vehicles.add(vehicle);
    notifyListeners();
  }

  void updateVehicleStatus(String vehicleId, String newStatus) {
    final idx = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (idx != -1) {
      _vehicles[idx].status = newStatus;
      notifyListeners();
    }
  }

  void addResource({
    required String name,
    required String category,
    required int quantity,
    required String unit,
    String? associatedVehicleId,
  }) {
    final newId = 'RES-00${_resources.length + 1}';
    _resources.add(DemoResource(
      id: newId,
      name: name,
      category: category,
      quantity: quantity,
      unit: unit,
      associatedVehicleId: associatedVehicleId,
    ));
    notifyListeners();
  }

  void updateResourceQuantity(String resourceId, int newQuantity) {
    final idx = _resources.indexWhere((r) => r.id == resourceId);
    if (idx != -1) {
      _resources[idx].quantity = newQuantity;
      if (newQuantity <= 0) {
        _resources[idx].status = 'Depleted';
      } else {
        _resources[idx].status = 'Available';
      }
      notifyListeners();
    }
  }

  void toggleRoadBlock(String roadId) {
    final idx = _blockedRoads.indexWhere((b) => b.id == roadId);
    if (idx != -1) {
      _blockedRoads[idx].isBlocked = !_blockedRoads[idx].isBlocked;
      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS
  // ───────────────────────────────────────────────────────────────────────────

  void markNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }
}
