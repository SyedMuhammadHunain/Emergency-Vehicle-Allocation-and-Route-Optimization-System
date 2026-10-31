import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/widgets/brand/resq_app_bar.dart';
import '../../../core/widgets/feedback/state_widgets.dart';
import '../../../core/widgets/feedback/status_chip.dart';

class EmergencyDetailScreen extends StatelessWidget {
  final String emergencyId;

  const EmergencyDetailScreen({
    super.key,
    required this.emergencyId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.watch<MockRepository>();
    final emergency = repo.getEmergencyById(emergencyId);

    if (emergency == null) {
      return Scaffold(
        appBar: const ResQAppBar(
          subtitle: 'Report Details',
          showBackButton: true,
        ),
        body: Center(
          child: EmptyState(
            'Report Not Found',
            subtitle: 'Emergency ID "$emergencyId" was not found in the local demo database.',
            icon: Icons.error_outline_rounded,
            action: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryTeal),
              onPressed: () => context.go('/role-shell'),
              child: const Text('Return to Dashboard'),
            ),
          ),
        ),
      );
    }

    final dateStr = DateFormat('MMMM d, y · h:mm a').format(emergency.reportedAt);

    return Scaffold(
      appBar: ResQAppBar(
        subtitle: emergency.id,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Status Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
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
                                  emergency.id,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                emergency.category,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          StatusChip(status: emergency.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        emergency.description,
                        style: GoogleFonts.inter(fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Status Timeline Stepper
                Text(
                  'Dispatch Progress Timeline',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTimeline(emergency.status),
                  ),
                ),

                const SizedBox(height: 20),

                // Assigned Vehicle Card (if assigned)
                if (emergency.assignedVehicle != null) ...[
                  Text(
                    'Assigned Response Unit [DEMO DATA]',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.emergency_rounded,
                                  color: AppColors.primaryTeal,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      emergency.assignedVehicle!.licensePlate,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${emergency.assignedVehicle!.type} · Unit ${emergency.assignedVehicle!.id}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusChip(status: emergency.assignedVehicle!.status),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estimated Arrival (ETA)',
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    '~6 - 8 Minutes [SIMULATED]',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.statusPending,
                                    ),
                                  ),
                                ],
                              ),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                icon: const Icon(Icons.navigation_rounded, size: 16),
                                label: const Text('Live Tracking Map'),
                                onPressed: () {
                                  context.push('/citizen/tracking/${emergency.id}');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Incident Location Map Thumbnail
                Text(
                  'Reported Incident Location',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 180,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: emergency.location,
                            initialZoom: 14.5,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.resq.resq_app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: emergency.location,
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.emergencyPink,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.place_rounded, color: Colors.white, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.place_rounded, size: 16, color: AppColors.primaryTeal),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                emergency.locationLabel,
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Metrics Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Severity Level',
                        value: '${emergency.severity} / 5',
                        color: AppColors.emergencyPink,
                        icon: Icons.warning_amber_rounded,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Urgency Rating',
                        value: '${emergency.urgency} / 5',
                        color: AppColors.statusPending,
                        icon: Icons.timer_outlined,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'People Impacted',
                        value: '${emergency.peopleAffected}',
                        color: AppColors.infoCyan,
                        icon: Icons.people_outline_rounded,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Demo Simulation Control: Advance Status
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.statusPending.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.statusPending.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.science_outlined, size: 16, color: AppColors.statusPending),
                          const SizedBox(width: 6),
                          Text(
                            'DEMO STATE SIMULATOR',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.statusPending,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Simulate the dispatch status change to test UI transitions:',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildStateShiftButton(context, emergency, EmergencyStatus.reported, 'Reported'),
                          _buildStateShiftButton(context, emergency, EmergencyStatus.assigned, 'Assigned'),
                          _buildStateShiftButton(context, emergency, EmergencyStatus.enRoute, 'En Route'),
                          _buildStateShiftButton(context, emergency, EmergencyStatus.onScene, 'On Scene'),
                          _buildStateShiftButton(context, emergency, EmergencyStatus.resolved, 'Resolved'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final steps = [
      {'key': EmergencyStatus.reported, 'label': 'Reported'},
      {'key': EmergencyStatus.assigned, 'label': 'Assigned'},
      {'key': EmergencyStatus.enRoute, 'label': 'En Route'},
      {'key': EmergencyStatus.onScene, 'label': 'On Scene'},
      {'key': EmergencyStatus.resolved, 'label': 'Resolved'},
    ];

    final currentIndex = steps.indexWhere((s) => s['key'] == currentStatus);
    final activeIndex = currentIndex == -1 ? 0 : currentIndex;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final lineIndex = i ~/ 2;
          final isCompleted = lineIndex < activeIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? AppColors.primaryTeal : Colors.grey.withValues(alpha: 0.3),
            ),
          );
        } else {
          // Step circle
          final stepIndex = i ~/ 2;
          final isDone = stepIndex <= activeIndex;
          final isCurrent = stepIndex == activeIndex;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppColors.primaryTeal : Colors.grey.withValues(alpha: 0.2),
                  border: isCurrent
                      ? Border.all(color: AppColors.aquaAccent, width: 2)
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex]['label'] as String,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  color: isCurrent ? AppColors.primaryTeal : Colors.grey,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateShiftButton(
    BuildContext context,
    DemoEmergency emergency,
    String targetStatus,
    String label,
  ) {
    final isCurrent = emergency.status == targetStatus;

    return ActionChip(
      label: Text(label),
      labelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
        color: isCurrent ? Colors.white : AppColors.primaryTeal,
      ),
      backgroundColor: isCurrent ? AppColors.primaryTeal : Colors.transparent,
      side: const BorderSide(color: AppColors.primaryTeal),
      onPressed: isCurrent
          ? null
          : () {
              context.read<MockRepository>().updateEmergencyStatus(emergency.id, targetStatus);
            },
    );
  }
}
