import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/services/session_service.dart';
import '../../../core/widgets/buttons/emergency_report_button.dart';
import '../../../core/widgets/cards/dashboard_card.dart';
import '../../../core/widgets/feedback/status_chip.dart';

class CitizenHomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToReport;
  final VoidCallback? onNavigateToReportsList;

  const CitizenHomeScreen({
    super.key,
    this.onNavigateToReport,
    this.onNavigateToReportsList,
  });

  void _triggerCategoryReport(BuildContext context, String category) {
    if (onNavigateToReport != null) {
      onNavigateToReport!();
    } else {
      context.push('/citizen/report', extra: category);
    }
  }

  void _showHotlineDialog(BuildContext context, String service, String number) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, color: AppColors.primaryTeal),
            const SizedBox(width: 8),
            Text('Call $service', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Hotline: $number',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.emergencyPink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'In a real emergency, this dials $number directly. [SIMULATED DEMO]',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Simulate Call'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primaryTeal,
                  content: Text('Simulated call to $service ($number)...'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionService>();
    final repo = context.watch<MockRepository>();
    final activeEmergencies = repo.activeEmergencies;
    final recentReports = repo.recentEmergencies;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primaryTeal,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Top Greeting & City Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.25),
                        blurRadius: 12,
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Karachi Central Grid',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusCompleted.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'ONLINE',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hello, ${session.userName} 👋',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Need immediate assistance? Tap below to report an emergency.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Main Emergency CTA Button
                EmergencyReportButton(
                  label: 'REPORT EMERGENCY NOW',
                  sublabel: 'Direct dispatch triage · Karachi Emergency Network',
                  onPressed: () {
                    if (onNavigateToReport != null) {
                      onNavigateToReport!();
                    } else {
                      context.push('/citizen/report');
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Quick Category Selector
                Text(
                  'Quick Report by Category',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.lightTextNavy,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildCategoryTile(
                      context,
                      title: 'Medical',
                      icon: Icons.medical_services_rounded,
                      color: AppColors.infoCyan,
                      onTap: () => _triggerCategoryReport(context, EmergencyCategory.medical),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryTile(
                      context,
                      title: 'Fire',
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFE65100),
                      onTap: () => _triggerCategoryReport(context, EmergencyCategory.fire),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryTile(
                      context,
                      title: 'Accident',
                      icon: Icons.car_crash_rounded,
                      color: AppColors.emergencyPink,
                      onTap: () => _triggerCategoryReport(context, EmergencyCategory.accident),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryTile(
                      context,
                      title: 'Rescue',
                      icon: Icons.support_rounded,
                      color: AppColors.emergencyPurple,
                      onTap: () => _triggerCategoryReport(context, EmergencyCategory.rescue),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Active Emergency Card (if any active)
                if (activeEmergencies.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.emergencyPink,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Active Incident Status',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          if (onNavigateToReportsList != null) {
                            onNavigateToReportsList!();
                          } else {
                            context.push('/citizen/details/${activeEmergencies.first.id}');
                          }
                        },
                        child: Text(
                          'View All (${activeEmergencies.length})',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildActiveEmergencyCard(context, activeEmergencies.first, isDark),
                  const SizedBox(height: 22),
                ],

                // Overview Metrics Cards
                Row(
                  children: [
                    Expanded(
                      child: DashboardCard(
                        title: 'Active Incidents',
                        value: '${activeEmergencies.length}',
                        icon: Icons.pending_actions_rounded,
                        iconColor: AppColors.statusPending,
                        subtitle: 'Monitored real-time',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardCard(
                        title: 'Resolved Today',
                        value: '${repo.resolvedEmergencies.length}',
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.statusCompleted,
                        subtitle: 'Safely closed',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Karachi Emergency Hotlines Bar
                Text(
                  'Emergency Hotlines (Karachi)',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.lightTextNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHotlineButton(
                          context,
                          label: 'Police',
                          number: '15',
                          icon: Icons.local_police_rounded,
                          color: const Color(0xFF1D4ED8),
                        ),
                        Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.2)),
                        _buildHotlineButton(
                          context,
                          label: 'Rescue 1122',
                          number: '1122',
                          icon: Icons.health_and_safety_rounded,
                          color: AppColors.primaryTeal,
                        ),
                        Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.2)),
                        _buildHotlineButton(
                          context,
                          label: 'Fire Brigade',
                          number: '16',
                          icon: Icons.fire_truck_rounded,
                          color: const Color(0xFFE65100),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Recent Reports List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Reports',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.lightTextNavy,
                      ),
                    ),
                    if (onNavigateToReportsList != null)
                      TextButton(
                        onPressed: onNavigateToReportsList,
                        child: Text(
                          'See All',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (recentReports.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No emergency reports filed yet.',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  ...recentReports.map((e) => _buildRecentItem(context, e, isDark)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildCategoryTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.lightTextNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildActiveEmergencyCard(BuildContext context, DemoEmergency item, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.id,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.category,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                StatusChip(status: item.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 14, color: AppColors.primaryTeal),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                if (item.assignedVehicle != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.statusAssigned.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Unit: ${item.assignedVehicle!.type}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusAssigned,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ETA: ~7 mins [SIMULATED]',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusPending,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: AppColors.primaryTeal),
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 14, color: AppColors.primaryTeal),
                      label: Text(
                        'Track',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryTeal),
                      ),
                      onPressed: () {
                        context.push('/citizen/tracking/${item.id}');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Details',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        context.push('/citizen/details/${item.id}');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotlineButton(
    BuildContext context, {
    required String label,
    required String number,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _showHotlineDialog(context, label, number),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  number,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(BuildContext context, DemoEmergency item, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          context.push('/citizen/details/${item.id}');
        },
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emergency_rounded, color: AppColors.primaryTeal, size: 18),
        ),
        title: Row(
          children: [
            Text(
              item.id,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryTeal),
            ),
            const SizedBox(width: 6),
            Text(
              '· ${item.category}',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Text(
          item.locationLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 11),
        ),
        trailing: StatusChip(status: item.status),
      ),
    );
  }
}
