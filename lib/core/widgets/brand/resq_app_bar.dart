import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/role_constants.dart';
import '../../mock/mock_repository.dart';
import '../../services/session_service.dart';
import '../../theme/theme_controller.dart';
import 'resq_wordmark.dart';

/// Standardized, compact, fixed AppBar for the ResQ application.
/// Strictly adheres to Deep Teal + Aqua + Navy branding and never overflows on small screens.
class ResQAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? customActions;
  final bool showRoleSwitcher;
  final bool showNotifications;

  const ResQAppBar({
    super.key,
    this.subtitle,
    this.showBackButton = false,
    this.onBackPressed,
    this.customActions,
    this.showRoleSwitcher = true,
    this.showNotifications = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52.0);

  void _showRoleSwitcherSheet(BuildContext context) {
    final session = context.read<SessionService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
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
                            color: AppColors.statusPending,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'DEMO ROLE SWITCHER',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusPending,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Switch simulation role (frontend prototype mode):',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                ...UserRole.values.map((role) {
                  final isSelected = session.role == role.nameId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? AppColors.primaryTeal.withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryTeal.withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      leading: Icon(
                        role.icon,
                        color: isSelected ? AppColors.primaryTeal : Colors.grey,
                        size: 22,
                      ),
                      title: Text(
                        role.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : AppColors.lightTextNavy)
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 20)
                          : null,
                      onTap: () {
                        session.demoLogin(role.nameId);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.read<MockRepository>();
    final notifs = repo.notifications;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.35,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          repo.markAllNotificationsRead();
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Mark all read',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: notifs.isEmpty
                        ? Center(
                            child: Text(
                              'No notifications yet',
                              style: GoogleFonts.inter(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: notifs.length,
                            separatorBuilder: (_, _) => const Divider(height: 12),
                            itemBuilder: (context, idx) {
                              final n = notifs[idx];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: n.isRead
                                        ? Colors.grey.withValues(alpha: 0.1)
                                        : AppColors.primaryTeal.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.notifications_active_rounded,
                                    size: 18,
                                    color: n.isRead ? Colors.grey : AppColors.primaryTeal,
                                  ),
                                ),
                                title: Text(
                                  n.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  n.message,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                trailing: !n.isRead
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryTeal,
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  repo.markNotificationRead(n.id);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionService>();
    final currentRole = session.role ?? 'citizen';

    // Try reading mock repository for unread count
    int unreadCount = 0;
    try {
      final repo = context.watch<MockRepository>();
      unreadCount = repo.unreadCount;
    } catch (_) {}

    final canGoBack = showBackButton || Navigator.of(context).canPop();

    return AppBar(
      toolbarHeight: 52.0,
      elevation: 0,
      scrolledUnderElevation: 1.5,
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      titleSpacing: canGoBack ? 0 : 16,
      leading: canGoBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              color: isDark ? Colors.white : AppColors.lightTextNavy,
              tooltip: 'Back',
              onPressed: () {
                if (onBackPressed != null) {
                  onBackPressed!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResQWordmark(
            fontSize: 18,
            isLightBackground: !isDark,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              '·',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                subtitle!,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.lightTextNavy,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        ...?customActions,

        // Notifications button with badge
        if (showNotifications)
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: isDark ? Colors.white70 : AppColors.lightTextNavy,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.emergencyPink,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications',
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () => _showNotificationsSheet(context),
          ),

        // Compact DEMO Role Pill
        if (showRoleSwitcher)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => _showRoleSwitcherSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.statusPending,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentRole.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: AppColors.primaryTeal,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: AppColors.primaryTeal,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Theme toggle
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 18,
            color: isDark ? Colors.white70 : AppColors.lightTextNavy,
          ),
          tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: () {
            final theme = context.read<ThemeController>();
            theme.setMode(isDark ? ThemeMode.light : ThemeMode.dark);
          },
        ),

        const SizedBox(width: 6),
      ],
    );
  }
}
