import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum EmergencyType {
  medical,
  fire,
  police,
  accident,
  rescue,
  disaster,
  other,
}

enum IncidentStatus {
  reported,
  dispatched,
  onScene,
  resolved,
}

enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

extension EmergencyTypeExtension on EmergencyType {
  String get displayName {
    switch (this) {
      case EmergencyType.medical:
        return 'Medical Emergency';
      case EmergencyType.fire:
        return 'Fire & Smoke';
      case EmergencyType.police:
        return 'Police / Crime';
      case EmergencyType.accident:
        return 'Traffic Collision';
      case EmergencyType.rescue:
        return 'Search & Rescue';
      case EmergencyType.disaster:
        return 'Natural Disaster';
      case EmergencyType.other:
        return 'General Emergency';
    }
  }

  Color get color {
    switch (this) {
      case EmergencyType.medical:
        return AppColors.medical;
      case EmergencyType.fire:
        return AppColors.fire;
      case EmergencyType.police:
        return AppColors.police;
      case EmergencyType.accident:
        return AppColors.accent;
      case EmergencyType.rescue:
        return AppColors.rescue;
      case EmergencyType.disaster:
        return AppColors.disaster;
      case EmergencyType.other:
        return AppColors.secondary;
    }
  }

  IconData get icon {
    switch (this) {
      case EmergencyType.medical:
        return Icons.medical_services_rounded;
      case EmergencyType.fire:
        return Icons.local_fire_department_rounded;
      case EmergencyType.police:
        return Icons.local_police_rounded;
      case EmergencyType.accident:
        return Icons.car_crash_rounded;
      case EmergencyType.rescue:
        return Icons.healing_rounded;
      case EmergencyType.disaster:
        return Icons.warning_amber_rounded;
      case EmergencyType.other:
        return Icons.emergency_rounded;
    }
  }
}

extension IncidentStatusExtension on IncidentStatus {
  String get displayName {
    switch (this) {
      case IncidentStatus.reported:
        return 'Reported';
      case IncidentStatus.dispatched:
        return 'Unit Dispatched';
      case IncidentStatus.onScene:
        return 'First Responders On Scene';
      case IncidentStatus.resolved:
        return 'Resolved';
    }
  }

  Color get color {
    switch (this) {
      case IncidentStatus.reported:
        return AppColors.warning;
      case IncidentStatus.dispatched:
        return AppColors.info;
      case IncidentStatus.onScene:
        return AppColors.primary;
      case IncidentStatus.resolved:
        return AppColors.success;
    }
  }
}

extension IncidentSeverityExtension on IncidentSeverity {
  String get displayName {
    switch (this) {
      case IncidentSeverity.low:
        return 'Low Priority';
      case IncidentSeverity.medium:
        return 'Medium Priority';
      case IncidentSeverity.high:
        return 'High Priority';
      case IncidentSeverity.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case IncidentSeverity.low:
        return AppColors.severityLow;
      case IncidentSeverity.medium:
        return AppColors.severityMedium;
      case IncidentSeverity.high:
        return AppColors.severityHigh;
      case IncidentSeverity.critical:
        return AppColors.severityCritical;
    }
  }
}

class IncidentModel {
  final String id;
  final String title;
  final String description;
  final EmergencyType type;
  final IncidentStatus status;
  final IncidentSeverity severity;
  final double latitude;
  final double longitude;
  final String address;
  final String reporterName;
  final DateTime reportedAt;
  final String? assignedResponderUnit;
  final int? estimatedArrivalMinutes;

  const IncidentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.reporterName,
    required this.reportedAt,
    this.assignedResponderUnit,
    this.estimatedArrivalMinutes,
  });

  IncidentModel copyWith({
    String? id,
    String? title,
    String? description,
    EmergencyType? type,
    IncidentStatus? status,
    IncidentSeverity? severity,
    double? latitude,
    double? longitude,
    String? address,
    String? reporterName,
    DateTime? reportedAt,
    String? assignedResponderUnit,
    int? estimatedArrivalMinutes,
  }) {
    return IncidentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      reporterName: reporterName ?? this.reporterName,
      reportedAt: reportedAt ?? this.reportedAt,
      assignedResponderUnit: assignedResponderUnit ?? this.assignedResponderUnit,
      estimatedArrivalMinutes:
          estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
    );
  }
}
