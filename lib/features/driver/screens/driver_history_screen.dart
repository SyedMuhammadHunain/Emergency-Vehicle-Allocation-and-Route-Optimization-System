import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/services/session_service.dart';
import '../../../core/widgets/feedback/state_widgets.dart';
import '../../../core/widgets/feedback/status_chip.dart';

class DriverHistoryScreen extends StatelessWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const DriverHistoryScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionService>();
    final repo = context.watch<MockRepository>();

    final history = repo.getMissionHistoryForDriver(session.userName);

    return Scaffold(
      body: history.isEmpty
          ? Center(
              child: EmptyState(
                'No Completed Missions Yet',
                subtitle: 'Missions you complete and resolve will appear in this historical record log.',
                icon: Icons.history_toggle_off_rounded,
                action: onNavigateToTab != null
                    ? OutlinedButton(
                        onPressed: () => onNavigateToTab!(0),
                        child: const Text('Back to Dashboard'),
                      )
                    : null,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
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
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.forCategory(item.category).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.category == EmergencyCategory.medical
                                        ? Icons.medical_services_rounded
                                        : item.category == EmergencyCategory.fire
                                            ? Icons.local_fire_department_rounded
                                            : Icons.car_crash_rounded,
                                    color: AppColors.forCategory(item.category),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.id,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ],
                            ),
                            const StatusChip(status: 'RESOLVED'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.locationLabel,
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.statusCompleted),
                                const SizedBox(width: 6),
                                Text(
                                  'Successfully resolved on site',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              item.reportedAt.toLocal().toString().split('.')[0],
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
