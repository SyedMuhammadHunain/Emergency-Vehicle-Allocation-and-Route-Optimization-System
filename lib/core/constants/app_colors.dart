import 'package:flutter/material.dart';

/// Single source of truth for all ResQ branding and theme colors.
/// Never hardcode colors directly in screen files.
class AppColors {
  AppColors._();

  // Official ResQ Teal & Aqua Palette
  static const Color primaryTeal = Color(0xFF08838D);
  static const Color primaryDarkTeal = Color(0xFF0A5C78);
  static const Color aquaAccent = Color(0xFF2DD4BF);
  static const Color aquaRing = Color(0xFF14B8A6);
  static const Color primaryNavy = Color(0xFF16264A);

  // Primary Teal Gradient (Used on headers, main buttons, active nav pills)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryTeal, primaryDarkTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary Emergency Gradient (Report Emergency button, critical incident pins)
  static const Color emergencyPink = Color(0xFFC2185B);
  static const Color emergencyPurple = Color(0xFF7B1FA2);
  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [emergencyPink, emergencyPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary Info Gradient
  static const Color infoCyan = Color(0xFF0A6E9E);
  static const Color infoBlue = Color(0xFF1D4ED8);
  static const LinearGradient infoGradient = LinearGradient(
    colors: [infoCyan, infoBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary Button Border Gradient (Teal #14B8A6 to Blue #2563EB)
  static const LinearGradient buttonBorderGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Theme Tokens
  static const Color lightBg = Color(0xFFF1F7F9);
  static const Color lightSurface = Colors.white;
  static const Color lightTextNavy = Color(0xFF16264A);
  static const Color lightBorder = Color(0xFFC5DAE1);
  static const Color lightAccent = Color(0xFF0A7F8A);
  static const Color lightTextSecondary = Color(0xFF5B6E8A);

  // Dark Theme Tokens
  static const Color darkBg = Color(0xFF0A1020);
  static const Color darkSurface = Color(0xFF111B2E);
  static const Color darkText = Color(0xFFEAF2FF);
  static const Color darkBorder = Color(0xFF2A3F66);
  static const Color darkAccent = Color(0xFF2DD4BF);
  static const Color darkTextSecondary = Color(0xFF8DA4C4);

  // Status & Operational Colors
  static const Color statusPending = Color(0xFFFF8F00);     // Amber
  static const Color statusAssigned = Color(0xFF0A6E9E);    // Cyan Blue
  static const Color statusOnTheWay = Color(0xFF1D4ED8);    // Deep Blue
  static const Color statusArrived = Color(0xFF7B1FA2);     // Purple
  static const Color statusCompleted = Color(0xFF10B981);   // Green
  static const Color statusAvailable = Color(0xFF10B981);
  static const Color statusBusy = Color(0xFFF59E0B);
  static const Color statusMaintenance = Color(0xFFEF4444); // Red

  // Compatibility aliases for legacy/existing files
  static const Color primary = primaryTeal;
  static const Color primaryDark = primaryDarkTeal;
  static const Color primaryLight = aquaAccent;
  static const Color secondary = primaryDarkTeal;
  static const Color secondaryLight = infoCyan;
  static const Color accent = aquaAccent;
  static const Color borderLight = lightBorder;
  static const Color borderDark = darkBorder;
  static const Color backgroundLight = lightBg;
  static const Color backgroundDark = darkBg;
  static const Color surfaceLight = lightSurface;
  static const Color surfaceDark = darkSurface;
  static const Color textPrimaryLight = lightTextNavy;
  static const Color textPrimaryDark = darkText;
  static const Color textSecondaryLight = lightTextSecondary;
  static const Color textSecondaryDark = darkTextSecondary;
  static const Color success = statusCompleted;
  static const Color warning = statusPending;
  static const Color info = statusAssigned;
  static const Color error = statusMaintenance;
  static const Color severityCritical = emergencyPink;
  static const Color severityHigh = statusPending;
  static const Color severityMedium = statusBusy;
  static const Color severityLow = statusCompleted;
  static const Color medical = infoCyan;
  static const Color fire = Color(0xFFE65100);
  static const Color police = Color(0xFF303F9F);
  static const Color rescue = emergencyPurple;
  static const Color disaster = emergencyPink;

  // Map Tokens (Karachi 2D Map)
  static const Color mapNavy = Color(0xFF0D1B2A);
  static const Color mapRoadBlue = Color(0xFF1E3A8A);
  static const Color mapRouteTealGlow = Color(0xFF14B8A6);
  static const Color mapRoadBlockedRed = Color(0xFFEF4444);
  static const Color mapVehiclePurple = Color(0xFF9333EA);

  /// Resolves the color for an incident or vehicle status string.
  static Color forStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'REPORTED':
        return statusPending;
      case 'ASSIGNED':
      case 'ACCEPTED':
        return statusAssigned;
      case 'ON_THE_WAY':
      case 'EN_ROUTE':
        return statusOnTheWay;
      case 'ARRIVED':
      case 'ON_SCENE':
        return statusArrived;
      case 'COMPLETED':
      case 'RESOLVED':
      case 'AVAILABLE':
        return statusCompleted;
      case 'BUSY':
        return statusBusy;
      case 'MAINTENANCE':
      case 'BLOCKED':
        return statusMaintenance;
      default:
        return emergencyPink;
    }
  }

  /// Resolves the branding color for emergency categories.
  static Color forCategory(String category) {
    switch (category.toUpperCase()) {
      case 'MEDICAL':
        return infoCyan;
      case 'FIRE':
        return fire;
      case 'ACCIDENT':
        return emergencyPink;
      case 'RESCUE':
        return emergencyPurple;
      default:
        return primaryTeal;
    }
  }

  /// Resolves status color based on numeric severity (1–5).
  static Color forSeverity(int severity) {
    switch (severity) {
      case 5:
        return emergencyPink;
      case 4:
        return statusPending;
      case 3:
        return statusBusy;
      default:
        return statusCompleted;
    }
  }
}
