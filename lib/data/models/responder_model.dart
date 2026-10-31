import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum ResponderType {
  ambulance,
  fireTruck,
  policePatrol,
  rescueUnit,
}

extension ResponderTypeExtension on ResponderType {
  String get displayName {
    switch (this) {
      case ResponderType.ambulance:
        return 'Medical EMS';
      case ResponderType.fireTruck:
        return 'Fire & Rescue Engine';
      case ResponderType.policePatrol:
        return 'Police Squad';
      case ResponderType.rescueUnit:
        return 'Emergency Rescue Team';
    }
  }

  Color get color {
    switch (this) {
      case ResponderType.ambulance:
        return AppColors.medical;
      case ResponderType.fireTruck:
        return AppColors.fire;
      case ResponderType.policePatrol:
        return AppColors.police;
      case ResponderType.rescueUnit:
        return AppColors.rescue;
    }
  }

  IconData get icon {
    switch (this) {
      case ResponderType.ambulance:
        return Icons.emergency_rounded;
      case ResponderType.fireTruck:
        return Icons.fire_truck_rounded;
      case ResponderType.policePatrol:
        return Icons.local_police_rounded;
      case ResponderType.rescueUnit:
        return Icons.health_and_safety_rounded;
    }
  }
}

class ResponderModel {
  final String id;
  final String callSign;
  final String stationName;
  final ResponderType type;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final int etaMinutes;
  final String phoneNumber;

  const ResponderModel({
    required this.id,
    required this.callSign,
    required this.stationName,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.isAvailable,
    required this.etaMinutes,
    required this.phoneNumber,
  });
}
