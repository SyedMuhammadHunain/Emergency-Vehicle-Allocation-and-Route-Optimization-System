import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightTextNavy;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    // Headings in Poppins, body in Inter
    final poppins = GoogleFonts.poppins();
    final inter = GoogleFonts.inter();

    final textTheme = TextTheme(
      displayLarge: poppins.copyWith(fontSize: 32, fontWeight: FontWeight.w800, color: textColor),
      displayMedium: poppins.copyWith(fontSize: 28, fontWeight: FontWeight.w700, color: textColor),
      displaySmall: poppins.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: poppins.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
      headlineSmall: poppins.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: poppins.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: inter.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: inter.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor),
      bodyLarge: inter.copyWith(fontSize: 15, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: inter.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: secondaryTextColor),
      bodySmall: inter.copyWith(fontSize: 11, fontWeight: FontWeight.w400, color: secondaryTextColor),
      labelLarge: inter.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primaryTeal,
        onPrimary: Colors.white,
        secondary: accentColor,
        onSecondary: Colors.white,
        error: AppColors.statusMaintenance,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textColor,
        outline: borderColor,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF162238) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.statusMaintenance, width: 1.5),
        ),
        labelStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
        hintStyle: TextStyle(color: secondaryTextColor.withValues(alpha: 0.7), fontSize: 13),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: poppins.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
