import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../feedback/status_chip.dart';

class EmergencyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  final VoidCallback? onTrack;

  const EmergencyCard({
    super.key,
    required this.data,
    this.onTap,
    this.onTrack,
  });

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'FIRE':
        return Icons.local_fire_department_rounded;
      case 'MEDICAL':
        return Icons.medical_services_rounded;
      case 'ACCIDENT':
        return Icons.car_crash_rounded;
      case 'RESCUE':
        return Icons.healing_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type.toUpperCase()) {
      case 'FIRE':
        return const Color(0xFFE65100);
      case 'MEDICAL':
        return AppColors.infoCyan;
      case 'ACCIDENT':
        return AppColors.statusPending;
      case 'RESCUE':
        return AppColors.emergencyPink;
      default:
        return AppColors.primaryTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] ?? 'EMERGENCY').toString();
    final status = (data['status'] ?? 'PENDING').toString();
    final id = data['id']?.toString() ?? '—';
    final severity = data['severity']?.toString() ?? '3';
    final time = data['created_at']?.toString() ?? '';
    final eta = data['eta']?.toString();
    final typeColor = _colorForType(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForType(type), color: typeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency #$id',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          type,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyPink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Severity: $severity/5',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.emergencyPink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (eta != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ETA: $eta',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (time.isNotEmpty)
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              if (onTrack != null) ...[
                const Divider(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onTrack,
                    icon: const Icon(Icons.navigation_rounded, size: 16),
                    label: const Text('Live Tracking'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
