import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/widgets/brand/resq_app_bar.dart';
import '../../../core/widgets/feedback/state_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.watch<MockRepository>();
    final notifs = repo.notifications;

    return Scaffold(
      appBar: ResQAppBar(
        subtitle: 'Notifications (${repo.unreadCount} new)',
        showBackButton: true,
        customActions: [
          TextButton(
            onPressed: () => repo.markAllNotificationsRead(),
            child: Text(
              'Mark all read',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryTeal),
            ),
          ),
        ],
      ),
      body: notifs.isEmpty
          ? const Center(
              child: EmptyState(
                'No Notifications',
                subtitle: 'You have no dispatch or emergency notifications at this time.',
                icon: Icons.notifications_off_outlined,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        Icons.notifications_active_rounded,
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
                              fontSize: 14,
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
                              color: AppColors.primaryTeal,
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
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          timeStr,
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () {
                      repo.markNotificationRead(item.id);
                      if (item.relatedEmergencyId != null) {
                        context.push('/citizen/details/${item.relatedEmergencyId}');
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
