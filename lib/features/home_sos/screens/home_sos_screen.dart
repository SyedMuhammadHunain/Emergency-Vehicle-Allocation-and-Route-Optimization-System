import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/incident_card.dart';
import '../../../data/models/incident_model.dart';
import '../../incidents/providers/incident_provider.dart';
import '../providers/emergency_provider.dart';

class HomeSosScreen extends StatelessWidget {
  const HomeSosScreen({super.key});

  void _triggerSos(BuildContext context) {
    final emergencyProvider = context.read<EmergencyProvider>();
    final incidentProvider = context.read<IncidentProvider>();

    emergencyProvider.startSosCountdown(
      onSosTriggered: () {
        // Auto-generate SOS incident in the provider
        final sosIncident = IncidentModel(
          id: 'SOS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          title: '🚨 Citizen Distress Signal (SOS Activated)',
          description: 'Emergency panic button triggered by citizen. Immediate response required.',
          type: EmergencyType.medical,
          status: IncidentStatus.dispatched,
          severity: IncidentSeverity.critical,
          latitude: 37.7749,
          longitude: -122.4194,
          address: 'Current Citizen GPS Coordinates (Market St vicinity)',
          reporterName: 'Alex Vance (SOS User)',
          reportedAt: DateTime.now(),
          assignedResponderUnit: 'Medic 12 & Patrol 24',
          estimatedArrivalMinutes: 3,
        );

        incidentProvider.addIncident(sosIncident);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              '⚠️ EMERGENCY BEACON ACTIVATED: Dispatcher & ICE Contacts notified!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            duration: Duration(seconds: 4),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emergencyProvider = context.watch<EmergencyProvider>();
    final incidentProvider = context.watch<IncidentProvider>();
    final recentIncidents = incidentProvider.allIncidents.take(2).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'ResQ',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 4, backgroundColor: AppColors.success),
                SizedBox(width: 6),
                Text(
                  'GPS Active',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active SOS Emergency Alert Banner
            if (emergencyProvider.isSosActive) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'EMERGENCY SOS BROADCASTING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your live coordinates and medical profile have been dispatched to nearby emergency services and emergency contacts.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(40),
                      ),
                      onPressed: () {
                        emergencyProvider.cancelActiveEmergency();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Emergency beacon cancelled.')),
                        );
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text(
                        'CANCEL EMERGENCY BEACON',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Safety Status Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Emergency Network Operational • 4 Units Nearby',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Pulsing SOS Distress Button
            EmergencyButton(
              isActivated: emergencyProvider.isSosActive,
              isCountingDown: emergencyProvider.isCountingDown,
              countdownRemaining: emergencyProvider.countdownRemaining,
              onPressed: () => _triggerSos(context),
              onCancelCountdown: () {
                emergencyProvider.cancelCountdown();
              },
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                emergencyProvider.isCountingDown
                    ? 'Release or tap to cancel'
                    : 'Tap in an emergency to alert authorities & ICE contacts',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Hotlines
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickCallButton(
                      label: 'Police',
                      number: '911',
                      icon: Icons.local_police_rounded,
                      color: AppColors.police,
                      onTap: () => _showCallDialog(context, 'Police (911)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickCallButton(
                      label: 'Ambulance',
                      number: '911',
                      icon: Icons.medical_services_rounded,
                      color: AppColors.medical,
                      onTap: () => _showCallDialog(context, 'Ambulance (911)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickCallButton(
                      label: 'Fire Dept',
                      number: '911',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.fire,
                      onTap: () => _showCallDialog(context, 'Fire Department (911)'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Quick Report Categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Report an Incident',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () => context.push('/incidents/new'),
                    child: const Text('Custom Report'),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.05,
                children: [
                  _CategoryCard(
                    type: EmergencyType.medical,
                    onTap: () => context.push('/incidents/new?type=medical'),
                  ),
                  _CategoryCard(
                    type: EmergencyType.fire,
                    onTap: () => context.push('/incidents/new?type=fire'),
                  ),
                  _CategoryCard(
                    type: EmergencyType.accident,
                    onTap: () => context.push('/incidents/new?type=accident'),
                  ),
                  _CategoryCard(
                    type: EmergencyType.police,
                    onTap: () => context.push('/incidents/new?type=police'),
                  ),
                  _CategoryCard(
                    type: EmergencyType.rescue,
                    onTap: () => context.push('/incidents/new?type=rescue'),
                  ),
                  _CategoryCard(
                    type: EmergencyType.disaster,
                    onTap: () => context.push('/incidents/new?type=disaster'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Recent Incidents Ticker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Alerts in Area',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () => context.go('/incidents'),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            ...recentIncidents.map(
              (incident) => IncidentCard(
                incident: incident,
                onTap: () => context.push('/incidents/${incident.id}'),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showCallDialog(BuildContext context, String serviceName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Emergency Call: $serviceName'),
        content: const Text(
          'In a live deployment, this dials emergency dispatch directly with your GPS location pre-transmitted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.call),
            label: const Text('Simulate Call'),
          ),
        ],
      ),
    );
  }
}

class _QuickCallButton extends StatelessWidget {
  final String label;
  final String number;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickCallButton({
    required this.label,
    required this.number,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              number,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final EmergencyType type;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(type.icon, color: type.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              type.displayName.split(' ').first,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
