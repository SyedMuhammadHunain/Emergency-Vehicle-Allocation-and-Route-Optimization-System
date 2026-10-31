import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';

class AdminReportsScreen extends StatelessWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const AdminReportsScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.watch<MockRepository>();

    final emergencies = repo.emergencies;
    final total = emergencies.isNotEmpty ? emergencies.length : 1;

    final medicalCount = emergencies.where((e) => e.category == EmergencyCategory.medical).length;
    final fireCount = emergencies.where((e) => e.category == EmergencyCategory.fire).length;
    final accidentCount = emergencies.where((e) => e.category == EmergencyCategory.accident).length;
    final rescueCount = emergencies.where((e) => e.category == EmergencyCategory.rescue).length;

    final reportedCount = emergencies.where((e) => e.status == EmergencyStatus.reported).length;
    final inProgressCount = emergencies.where((e) =>
        e.status == EmergencyStatus.assigned ||
        e.status == EmergencyStatus.enRoute ||
        e.status == EmergencyStatus.onScene).length;
    final resolvedCount = emergencies.where((e) => e.status == EmergencyStatus.resolved).length;

    final totalVehicles = repo.vehicles.isNotEmpty ? repo.vehicles.length : 1;
    final availableVehicles = repo.availableVehicles.length;
    final fleetUtilization = (((totalVehicles - availableVehicles) / totalVehicles) * 100).toInt();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Analytics Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OPERATIONAL PERFORMANCE & AUDIT',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Karachi Sector Emergency Telemetry',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text(
                              '[SIMULATED DEMO] Aggregate metrics calculated from live centralized repository.',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.88)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.analytics_rounded, color: Colors.white, size: 36),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Key Performance Highlights
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricHighlight(
                        label: 'Avg Response Latency',
                        value: '7.4 min',
                        icon: Icons.timer_rounded,
                        color: AppColors.primaryTeal,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricHighlight(
                        label: 'Fleet Utilization',
                        value: '$fleetUtilization%',
                        icon: Icons.pie_chart_rounded,
                        color: AppColors.statusAssigned,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricHighlight(
                        label: 'Resolution Rate',
                        value: '${((resolvedCount / total) * 100).toInt()}%',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.statusCompleted,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Category Distribution Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incidents by Emergency Category',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        _buildProgressBar('Medical Emergencies', medicalCount, total, AppColors.forCategory(EmergencyCategory.medical)),
                        _buildProgressBar('Fire & Structural Hazards', fireCount, total, AppColors.forCategory(EmergencyCategory.fire)),
                        _buildProgressBar('Vehicular Accidents', accidentCount, total, AppColors.forCategory(EmergencyCategory.accident)),
                        _buildProgressBar('Rescue & Disaster Ops', rescueCount, total, AppColors.forCategory(EmergencyCategory.rescue)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Status Distribution Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Triage Status Distribution',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        _buildProgressBar('Pending Dispatch Review', reportedCount, total, AppColors.statusPending),
                        _buildProgressBar('Active / En Route / On Scene', inProgressCount, total, AppColors.statusAssigned),
                        _buildProgressBar('Resolved & Closed', resolvedCount, total, AppColors.statusCompleted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricHighlight({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int count, int total, Color color) {
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final percent = (ratio * 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('$count calls ($percent%)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
