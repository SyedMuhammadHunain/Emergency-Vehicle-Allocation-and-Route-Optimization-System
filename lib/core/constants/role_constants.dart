import 'package:flutter/material.dart';

enum UserRole {
  citizen,
  dispatcher,
  driver,
  admin,
}

extension UserRoleExtension on UserRole {
  String get nameId {
    switch (this) {
      case UserRole.citizen:
        return 'citizen';
      case UserRole.dispatcher:
        return 'dispatcher';
      case UserRole.driver:
        return 'driver';
      case UserRole.admin:
        return 'admin';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.citizen:
        return 'Citizen';
      case UserRole.dispatcher:
        return 'Dispatcher';
      case UserRole.driver:
        return 'First Responder';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.citizen:
        return Icons.person_rounded;
      case UserRole.dispatcher:
        return Icons.headset_mic_rounded;
      case UserRole.driver:
        return Icons.local_shipping_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }
}
