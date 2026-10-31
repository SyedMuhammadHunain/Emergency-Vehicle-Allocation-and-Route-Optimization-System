import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/services/session_service.dart';
import '../../../core/widgets/feedback/state_widgets.dart';
import '../../../core/widgets/feedback/status_chip.dart';

class DriverMissionScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const DriverMissionScreen({super.key, this.onNavigateToTab});

  @override
  State<DriverMissionScreen> createState() => _DriverMissionScreenState();
}

class _DriverMissionScreenState extends State<DriverMissionScreen> {
  bool _isUpdating = false;

  Future<void> _advanceMissionStatus(
      BuildContext context, MockRepository repo, DemoEmergency mission, String newStatus) async {
    setState(() => _isUpdating = true);
    await Future.delayed(const Duration(milliseconds: 300));

    repo.updateMissionStatus(mission.id, newStatus);

    if (!context.mounted) return;
    setState(() => _isUpdating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryTeal,
        content: Text('Mission status advanced to $newStatus. State updated in shared repository.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionService>();
    final repo = context.watch<MockRepository>();

    final mission = repo.getActiveMissionForDriver(session.userName);

    if (mission == null) {
      return Scaffold(
        body: Center(
          child: EmptyState(
            'No Active Mission',
            subtitle: 'You are currently standing by at Karachi Central Depot. Ready for incoming dispatch triage.',
            icon: Icons.assignment_turned_in_rounded,
            action: widget.onNavigateToTab != null
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('View Completed History'),
                    onPressed: () => widget.onNavigateToTab!(3),
                  )
                : null,
          ),
        ),
      );
    }

    final isAssigned = mission.status == EmergencyStatus.assigned || mission.status == EmergencyStatus.reported;
    final isEnRoute = mission.status == EmergencyStatus.enRoute;
    final isOnScene = mission.status == EmergencyStatus.onScene;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mission Header Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.emergencyGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emergencyPink.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRIORITY DISPATCH MISSION',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${mission.id} · ${mission.category}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Target: ${mission.locationLabel}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(status: mission.status),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Mission Timeline Progression Bar
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
                      Text(
                        'Mission Progression Workflow',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStepIndicator('Assigned', isDone: true, isActive: isAssigned),
                          _buildStepDivider(isDone: isEnRoute || isOnScene),
                          _buildStepIndicator('En Route', isDone: isEnRoute || isOnScene, isActive: isEnRoute),
                          _buildStepDivider(isDone: isOnScene),
                          _buildStepIndicator('On Scene', isDone: isOnScene, isActive: isOnScene),
                          _buildStepDivider(isDone: false),
                          _buildStepIndicator('Completed', isDone: false, isActive: false),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Incident Details Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incident Intelligence',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(Icons.place_rounded, 'Destination', mission.locationLabel),
                        _buildInfoRow(Icons.description_rounded, 'Description', mission.description),
                        _buildInfoRow(Icons.warning_amber_rounded, 'Severity / Urgency', '${mission.severity}/5 (Severity) · ${mission.urgency}/5 (Urgency)'),
                        _buildInfoRow(Icons.people_alt_outlined, 'Casualties Reported', '${mission.peopleAffected} persons'),
                        _buildInfoRow(Icons.local_shipping_rounded, 'Your Vehicle Unit', '${mission.assignedVehicle?.type ?? "Ambulance"} (${mission.assignedVehicle?.licensePlate ?? "KHI-1122-AMB"})'),
                        if (mission.allocationReason != null)
                          _buildInfoRow(Icons.psychology_alt_rounded, 'DP Dispatch Reason', mission.allocationReason!),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Navigation Shortcut Tile
                Card(
                  color: AppColors.primaryTeal.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.navigation_rounded, color: AppColors.primaryTeal, size: 30),
                    title: Text(
                      'Turn-by-Turn Simulated Navigation',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Simulated shortest path through Karachi central grid (ETA: ~6 min)',
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                    trailing: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                      onPressed: () {
                        if (widget.onNavigateToTab != null) widget.onNavigateToTab!(2);
                      },
                      child: const Text('Open Map'),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Step Buttons (Progression Engine)
                Text(
                  'Update Operational Status',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),

                if (isAssigned)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.statusAssigned,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.directions_car_rounded),
                    label: Text(
                      _isUpdating ? 'Updating Status...' : 'Depart Now: Mark as EN ROUTE',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    onPressed: _isUpdating
                        ? null
                        : () => _advanceMissionStatus(context, repo, mission, EmergencyStatus.enRoute),
                  )
                else if (isEnRoute)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.statusPending,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.place_rounded),
                    label: Text(
                      _isUpdating ? 'Updating Status...' : 'Arrived at Destination: Mark ON SCENE',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    onPressed: _isUpdating
                        ? null
                        : () => _advanceMissionStatus(context, repo, mission, EmergencyStatus.onScene),
                  )
                else if (isOnScene)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.statusCompleted,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.task_alt_rounded),
                    label: Text(
                      _isUpdating ? 'Updating Status...' : 'Complete Mission & Return to Standby',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    onPressed: _isUpdating
                        ? null
                        : () => _advanceMissionStatus(context, repo, mission, EmergencyStatus.resolved),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(String label, {required bool isDone, required bool isActive}) {
    final color = isDone
        ? AppColors.statusCompleted
        : (isActive ? AppColors.primaryTeal : Colors.grey.withValues(alpha: 0.5));

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isActive ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: Icon(
            isDone ? Icons.check : Icons.circle,
            color: Colors.white,
            size: isDone ? 16 : 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: isDone ? AppColors.statusCompleted : Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
