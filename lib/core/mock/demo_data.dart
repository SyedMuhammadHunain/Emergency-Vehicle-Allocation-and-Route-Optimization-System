// DEMO DATA — Centralized in-memory demo data for ResQ Frontend Prototype.
// All incidents, vehicles, staff, and routes are simulated demo records.

import 'package:latlong2/latlong.dart';

/// Emergency category constants
class EmergencyCategory {
  static const String medical = 'MEDICAL';
  static const String fire = 'FIRE';
  static const String accident = 'ACCIDENT';
  static const String rescue = 'RESCUE';
}

/// Emergency status constants
class EmergencyStatus {
  static const String reported = 'REPORTED';
  static const String assigned = 'ASSIGNED';
  static const String enRoute = 'EN_ROUTE';
  static const String onScene = 'ON_SCENE';
  static const String resolved = 'RESOLVED';
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO: User Account Model
// ─────────────────────────────────────────────────────────────────────────────
class DemoUserAccount {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role; // 'citizen', 'dispatcher', 'driver', 'admin'
  final String phone;
  bool isActive;
  final DateTime createdAt;

  DemoUserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.phone = '',
    this.isActive = true,
    required this.createdAt,
  });

  DemoUserAccount copyWith({
    String? name,
    String? phone,
    bool? isActive,
  }) {
    return DemoUserAccount(
      id: id,
      name: name ?? this.name,
      email: email,
      password: password,
      role: role,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREDEFINED DEMO ACCOUNTS (Compulsory exact credentials)
// ─────────────────────────────────────────────────────────────────────────────
final List<DemoUserAccount> kPredefinedDemoAccounts = [
  DemoUserAccount(
    id: 'USR-CIT-001',
    name: 'Demo Citizen',
    email: 'citizen@resq.com',
    password: 'Citizen123',
    role: 'citizen',
    phone: '+92 300 1234567',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  ),
  DemoUserAccount(
    id: 'USR-DIS-001',
    name: 'Karachi Central Dispatcher',
    email: 'dispatcher@resq.com',
    password: 'Dispatch123',
    role: 'dispatcher',
    phone: '+92 321 9876543',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  ),
  DemoUserAccount(
    id: 'USR-DRV-001',
    name: 'Captain Tariq (Ambulance Unit 1)',
    email: 'driver@resq.com',
    password: 'Driver123',
    role: 'driver',
    phone: '+92 333 5551122',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  ),
  DemoUserAccount(
    id: 'USR-ADM-001',
    name: 'System Administrator',
    email: 'admin@resq.com',
    password: 'Admin123',
    role: 'admin',
    phone: '+92 300 0000000',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// DEMO: Vehicle Model
// ─────────────────────────────────────────────────────────────────────────────
class DemoVehicle {
  final String id;
  final String licensePlate;
  final String type; // 'Ambulance' | 'Fire Brigade' | 'Rescue Vehicle'
  String status; // 'Available' | 'Busy' | 'Maintenance' | 'En Route'
  LatLng location; // DEMO simulated position
  String? assignedEmergencyId;
  String? driverName;

  DemoVehicle({
    required this.id,
    required this.licensePlate,
    required this.type,
    required this.status,
    required this.location,
    this.assignedEmergencyId,
    this.driverName,
  });

  DemoVehicle copyWith({
    String? status,
    LatLng? location,
    String? assignedEmergencyId,
    String? driverName,
  }) {
    return DemoVehicle(
      id: id,
      licensePlate: licensePlate,
      type: type,
      status: status ?? this.status,
      location: location ?? this.location,
      assignedEmergencyId: assignedEmergencyId ?? this.assignedEmergencyId,
      driverName: driverName ?? this.driverName,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO: Resource Model
// ─────────────────────────────────────────────────────────────────────────────
class DemoResource {
  final String id;
  final String name;
  final String category; // 'Crew', 'Equipment', 'Medical', 'Fuel'
  int quantity;
  final String unit;
  String status; // 'Available', 'In Use', 'Depleted'
  String? associatedVehicleId;

  DemoResource({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.status = 'Available',
    this.associatedVehicleId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO: Blocked Road Model
// ─────────────────────────────────────────────────────────────────────────────
class DemoBlockedRoad {
  final String id;
  final String roadName;
  final String reason;
  final LatLng location;
  bool isBlocked;

  DemoBlockedRoad({
    required this.id,
    required this.roadName,
    required this.reason,
    required this.location,
    this.isBlocked = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO: Emergency Model
// ─────────────────────────────────────────────────────────────────────────────
class DemoEmergency {
  final String id;
  final String category;
  String status;
  final int severity; // 1–5
  final int urgency; // 1–5
  final int peopleAffected;
  final String description;
  final LatLng location;
  final String locationLabel;
  final DateTime reportedAt;
  final String reportedByUserId;
  DemoVehicle? assignedVehicle;
  String? allocationReason; // Illustrative DP explanation

  DemoEmergency({
    required this.id,
    required this.category,
    required this.status,
    required this.severity,
    required this.urgency,
    required this.peopleAffected,
    required this.description,
    required this.location,
    required this.locationLabel,
    required this.reportedAt,
    required this.reportedByUserId,
    this.assignedVehicle,
    this.allocationReason,
  });

  DemoEmergency copyWith({
    String? status,
    DemoVehicle? assignedVehicle,
    String? allocationReason,
  }) {
    return DemoEmergency(
      id: id,
      category: category,
      status: status ?? this.status,
      severity: severity,
      urgency: urgency,
      peopleAffected: peopleAffected,
      description: description,
      location: location,
      locationLabel: locationLabel,
      reportedAt: reportedAt,
      reportedByUserId: reportedByUserId,
      assignedVehicle: assignedVehicle ?? this.assignedVehicle,
      allocationReason: allocationReason ?? this.allocationReason,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO: Notification Model
// ─────────────────────────────────────────────────────────────────────────────
class DemoNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;
  final String? relatedEmergencyId;
  final String targetRole; // 'all', 'citizen', 'dispatcher', 'driver', 'admin'

  DemoNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.relatedEmergencyId,
    this.targetRole = 'all',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// INITIAL DEMO SEEDS
// ─────────────────────────────────────────────────────────────────────────────
final List<DemoVehicle> kDemoVehicles = [
  DemoVehicle(
    id: 'VH-001',
    licensePlate: 'KHI-1122-AMB',
    type: 'Ambulance',
    status: 'Available',
    location: const LatLng(24.8720, 67.0104),
    driverName: 'Captain Tariq',
  ),
  DemoVehicle(
    id: 'VH-002',
    licensePlate: 'KHI-FIRE-077',
    type: 'Fire Brigade',
    status: 'Available',
    location: const LatLng(24.8550, 66.9987),
    driverName: 'Sgt. Farooq',
  ),
  DemoVehicle(
    id: 'VH-003',
    licensePlate: 'KHI-RSQ-042',
    type: 'Rescue Vehicle',
    status: 'Busy',
    location: const LatLng(24.8680, 67.0320),
    driverName: 'Officer Salman',
    assignedEmergencyId: 'EM-2026-0001',
  ),
  DemoVehicle(
    id: 'VH-004',
    licensePlate: 'KHI-AMB-015',
    type: 'Ambulance',
    status: 'Available',
    location: const LatLng(24.8800, 67.0150),
    driverName: 'Zubair Ahmed',
  ),
  DemoVehicle(
    id: 'VH-005',
    licensePlate: 'KHI-FIRE-102',
    type: 'Fire Brigade',
    status: 'Maintenance',
    location: const LatLng(24.8420, 67.0250),
  ),
];

final List<DemoResource> kDemoResources = [
  DemoResource(
    id: 'RES-001',
    name: 'Paramedic Crew Alpha (3 Staff)',
    category: 'Crew',
    quantity: 3,
    unit: 'personnel',
    status: 'Available',
    associatedVehicleId: 'VH-001',
  ),
  DemoResource(
    id: 'RES-002',
    name: 'Advanced Cardiac Defibrillator',
    category: 'Medical',
    quantity: 2,
    unit: 'units',
    status: 'Available',
    associatedVehicleId: 'VH-001',
  ),
  DemoResource(
    id: 'RES-003',
    name: 'Hydraulic Rescue Cutter & Spreader',
    category: 'Equipment',
    quantity: 1,
    unit: 'kit',
    status: 'In Use',
    associatedVehicleId: 'VH-003',
  ),
  DemoResource(
    id: 'RES-004',
    name: 'High-Expansion Fire Foam Tank',
    category: 'Equipment',
    quantity: 500,
    unit: 'liters',
    status: 'Available',
    associatedVehicleId: 'VH-002',
  ),
  DemoResource(
    id: 'RES-005',
    name: 'Emergency Oxygen Cylinders',
    category: 'Medical',
    quantity: 8,
    unit: 'cylinders',
    status: 'Available',
    associatedVehicleId: 'VH-004',
  ),
  DemoResource(
    id: 'RES-006',
    name: 'Heavy Duty Diesel Reserve',
    category: 'Fuel',
    quantity: 1200,
    unit: 'liters',
    status: 'Available',
  ),
];

final List<DemoBlockedRoad> kDemoBlockedRoads = [
  DemoBlockedRoad(
    id: 'BLK-001',
    roadName: 'M.A. Jinnah Road (Near Tibet Centre)',
    reason: 'Water Pipeline Burst & Road Cavity',
    location: const LatLng(24.8625, 67.0180),
    isBlocked: true,
  ),
  DemoBlockedRoad(
    id: 'BLK-002',
    roadName: 'Shahrah-e-Faisal (Nursery Flyover under repair)',
    reason: 'Scheduled Bridge Expansion Joint Works',
    location: const LatLng(24.8640, 67.0650),
    isBlocked: true,
  ),
  DemoBlockedRoad(
    id: 'BLK-003',
    roadName: 'University Road (NIPA Intersection)',
    reason: 'Heavy Construction / BRT Line',
    location: const LatLng(24.9180, 67.0980),
    isBlocked: false,
  ),
];

List<DemoEmergency> buildDemoEmergencies(String userId) => [
      DemoEmergency(
        id: 'EM-2026-0001',
        category: EmergencyCategory.medical,
        status: EmergencyStatus.onScene,
        severity: 4,
        urgency: 5,
        peopleAffected: 2,
        description: 'Cardiac arrest reported at residential flat. Patient unresponsive.',
        location: const LatLng(24.8607, 67.0105),
        locationLabel: 'Gulshan-e-Iqbal, Block 4, Karachi',
        reportedAt: DateTime.now().subtract(const Duration(hours: 2)),
        reportedByUserId: userId,
        assignedVehicle: kDemoVehicles[0],
        allocationReason: 'Optimal DP score: Ambulance VH-001 is closest with Defibrillator equipment.',
      ),
      DemoEmergency(
        id: 'EM-2026-0002',
        category: EmergencyCategory.fire,
        status: EmergencyStatus.enRoute,
        severity: 5,
        urgency: 5,
        peopleAffected: 10,
        description: 'Multi-story commercial warehouse fire. Thick smoke billowing.',
        location: const LatLng(24.8700, 66.9950),
        locationLabel: 'SITE Industrial Area, Karachi',
        reportedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        reportedByUserId: userId,
        assignedVehicle: kDemoVehicles[1],
        allocationReason: 'High Severity 5: Fire Brigade VH-002 dispatched with Foam Reserve.',
      ),
      DemoEmergency(
        id: 'EM-2026-0003',
        category: EmergencyCategory.accident,
        status: EmergencyStatus.reported,
        severity: 3,
        urgency: 4,
        peopleAffected: 4,
        description: 'Two-vehicle collision on highway. Minor to moderate injuries.',
        location: const LatLng(24.8550, 67.0350),
        locationLabel: 'Shahrah-e-Faisal near Baloch Colony, Karachi',
        reportedAt: DateTime.now().subtract(const Duration(minutes: 12)),
        reportedByUserId: userId,
        allocationReason: 'Pending Dispatcher Review: Proposing Ambulance VH-004.',
      ),
    ];

List<DemoNotification> buildDemoNotifications(String userId) => [
      DemoNotification(
        id: 'NOTIF-001',
        title: 'Emergency Assigned',
        message: 'Report EM-2026-0001 assigned to Ambulance KHI-1122-AMB. ETA: ~8 min.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        isRead: false,
        relatedEmergencyId: 'EM-2026-0001',
        targetRole: 'all',
      ),
      DemoNotification(
        id: 'NOTIF-002',
        title: 'Responder On Scene',
        message: 'Ambulance KHI-1122-AMB has arrived at your reported location.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        isRead: false,
        relatedEmergencyId: 'EM-2026-0001',
        targetRole: 'all',
      ),
      DemoNotification(
        id: 'NOTIF-003',
        title: 'Fire Unit Dispatched',
        message: 'Fire Truck KHI-FIRE-077 dispatched for report EM-2026-0002.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 38)),
        isRead: true,
        relatedEmergencyId: 'EM-2026-0002',
        targetRole: 'dispatcher',
      ),
      DemoNotification(
        id: 'NOTIF-004',
        title: 'Road Block Alert',
        message: 'M.A. Jinnah Road blocked near Tibet Centre. Dijkstra route will re-route.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        isRead: false,
        targetRole: 'driver',
      ),
    ];
