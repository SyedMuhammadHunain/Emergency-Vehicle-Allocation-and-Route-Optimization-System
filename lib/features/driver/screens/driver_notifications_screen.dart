import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/widgets/feedback/state_widgets.dart';

/// Driver Notifications — shows notifications targeted to drivers and 'all'.
class DriverNotificationsScreen extends StatelessWidget {
  final void Function(int)? onNavigateToTab;

  const DriverNotificationsScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.watch<MockRepository>();
    final notifs = repo.notifications
        .where((n) => n.targetRole == 'all' || n.targetRole == 'driver')
        .toList();
    final unreadCount = notifs.where((n) => !n.isRead).length;

    return Column(
      children: [
        // Header with unread count and mark-all button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Mission Alerts',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyPink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount new',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                ],
              ),
              TextButton.icon(
                onPressed: () => repo.markAllNotificationsRead(),
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: Text(
                  'Mark all read',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.primaryTeal),
              ),
            ],
          ),
        ),

        // Notification list
        Expanded(
          child: notifs.isEmpty
              ? const Center(
                  child: EmptyState(
                    'No Mission Notifications',
                    subtitle: 'No mission assignments or route alerts at this time.',
                    icon: Icons.notifications_off_outlined,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: notifs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = notifs[idx];
                    final timeStr = DateFormat('MMM d · h:mm a').format(item.createdAt);

                    return Card(
                      elevation: item.isRead ? 0 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: item.isRead
                              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                              : AppColors.primaryTeal,
                          width: item.isRead ? 1 : 1.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: item.isRead
                                ? Colors.grey.withValues(alpha: 0.1)
                                : AppColors.primaryTeal.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _iconForNotification(item.title),
                            color: item.isRead ? Colors.grey : AppColors.primaryTeal,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                ),
                              ),
                            ),
                            if (!item.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.emergencyPink,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.targetRole == 'driver'
                                        ? Colors.orange.withValues(alpha: 0.1)
                                        : Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.targetRole == 'driver' ? 'MISSION' : 'SYSTEM',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: item.targetRole == 'driver'
                                          ? Colors.orange.shade800
                                          : Colors.blue,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  timeStr,
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          repo.markNotificationRead(item.id);
                        },
                      ),
                    );
                  },
                ),
        ),

        // DEMO MODE label
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'DEMO MODE — Simulated mission notifications',
            style: GoogleFonts.inter(fontSize: 9, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  IconData _iconForNotification(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('mission') || lower.contains('assigned')) {
      return Icons.assignment_turned_in_rounded;
    } else if (lower.contains('route') || lower.contains('navigation')) {
      return Icons.navigation_rounded;
    } else if (lower.contains('emergency') || lower.contains('incident')) {
      return Icons.emergency_rounded;
    }
    return Icons.notifications_active_rounded;
  }
}
