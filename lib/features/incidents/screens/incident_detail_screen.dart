import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/incident_model.dart';
import '../../map/providers/map_provider.dart';
import '../providers/incident_provider.dart';

class IncidentDetailScreen extends StatelessWidget {
  final String incidentId;

  const IncidentDetailScreen({
    super.key,
    required this.incidentId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final incidentProvider = context.watch<IncidentProvider>();
    final incident = incidentProvider.getIncidentById(incidentId);

    if (incident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Incident #$incidentId was not found in the registry.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Return to Incidents'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          incident.id,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_rounded),
            tooltip: 'View on Live Map',
            onPressed: () {
              context.read<MapProvider>().animateTo(
                    LatLng(incident.latitude, incident.longitude),
                    16.0,
                  );
              context.read<MapProvider>().selectIncident(incident);
              context.go('/map');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card with type icon, title, severity & status
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: incident.type.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(incident.type.icon, color: incident.type.color, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incident.type.displayName,
                              style: TextStyle(
                                color: incident.type.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              incident.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      StatusBadge(
                        label: incident.severity.displayName,
                        color: incident.severity.color,
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: incident.status.displayName,
                        color: incident.status.color,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Live Dispatch Timeline Stepper
            const Text(
              'Incident Lifecycle Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            _LifecycleStepper(
              currentStatus: incident.status,
              onStatusChange: (newStatus) {
                incidentProvider.updateIncidentStatus(incident.id, newStatus);
              },
            ),

            const SizedBox(height: 24),

            // Location & Address Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Location Details',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    incident.address,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GPS: ${incident.latitude.toStringAsFixed(4)}° N, ${incident.longitude.toStringAsFixed(4)}° W',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    onPressed: () {
                      context.read<MapProvider>().animateTo(
                            LatLng(incident.latitude, incident.longitude),
                            16.0,
                          );
                      context.read<MapProvider>().selectIncident(incident);
                      context.go('/map');
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Open on 2D Map'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Assigned Responder Unit Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned First Responders',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          incident.assignedResponderUnit ?? 'Assigning units...',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        if (incident.estimatedArrivalMinutes != null)
                          Text(
                            incident.estimatedArrivalMinutes == 0
                                ? 'Units currently On-Scene'
                                : 'Estimated Arrival: ~${incident.estimatedArrivalMinutes} mins',
                            style: TextStyle(
                              fontSize: 12,
                              color: incident.estimatedArrivalMinutes == 0
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Situation Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Situation Report',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    incident.description,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reported by: ${incident.reporterName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        DateFormat('h:mm a • MMM d').format(incident.reportedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Direct Call to Dispatch Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Contact Dispatch Unit'),
                    content: Text(
                      'Connecting to ${incident.assignedResponderUnit ?? "Emergency Dispatch"} hotline with incident ref ${incident.id}.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.phone_in_talk_rounded),
              label: const Text(
                'CALL EMERGENCY HOTLINE (911)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifecycleStepper extends StatelessWidget {
  final IncidentStatus currentStatus;
  final ValueChanged<IncidentStatus> onStatusChange;

  const _LifecycleStepper({
    required this.currentStatus,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = IncidentStatus.values;
    final currentIndex = statuses.indexOf(currentStatus);

    return Column(
      children: [
        Row(
          children: List.generate(statuses.length * 2 - 1, (index) {
            if (index.isOdd) {
              final stepIndex = index ~/ 2;
              final isPassed = stepIndex < currentIndex;
              return Expanded(
                child: Container(
                  height: 3,
                  color: isPassed ? AppColors.primary : Colors.grey.shade300,
                ),
              );
            } else {
              final stepIndex = index ~/ 2;
              final status = statuses[stepIndex];
              final isCompleted = stepIndex <= currentIndex;
              final isCurrent = stepIndex == currentIndex;

              return InkWell(
                onTap: () => onStatusChange(status),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.primary : Colors.grey.shade200,
                    border: Border.all(
                      color: isCurrent ? Colors.redAccent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${stepIndex + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: statuses.map((status) {
            final isCurrent = status == currentStatus;
            return Text(
              status.displayName.split(' ').first,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? AppColors.primary : Colors.grey,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
