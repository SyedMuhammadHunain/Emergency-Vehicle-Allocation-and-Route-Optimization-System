import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/brand/resq_wordmark.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  void _showThemePicker(BuildContext context) {
    final theme = context.read<ThemeController>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Appearance Theme', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings_suggest_rounded),
              title: const Text('System Default'),
              trailing: theme.mode == ThemeMode.system
                  ? const Icon(Icons.check, color: AppColors.primaryTeal)
                  : null,
              onTap: () {
                theme.setMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_rounded),
              title: const Text('Light Mode'),
              trailing: theme.mode == ThemeMode.light
                  ? const Icon(Icons.check, color: AppColors.primaryTeal)
                  : null,
              onTap: () {
                theme.setMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded),
              title: const Text('Dark Mode'),
              trailing: theme.mode == ThemeMode.dark
                  ? const Icon(Icons.check, color: AppColors.primaryTeal)
                  : null,
              onTap: () {
                theme.setMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to end your administrative session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.statusMaintenance),
            onPressed: () async {
              Navigator.pop(ctx);
              final session = context.read<SessionService>();
              await session.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionService>();
    final theme = context.watch<ThemeController>();

    final themeLabel = theme.mode == ThemeMode.system
        ? 'System Default'
        : theme.mode == ThemeMode.dark
            ? 'Dark Mode'
            : 'Light Mode';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Identity Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.userName,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              session.userEmail,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.aquaAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'SYSTEM ADMINISTRATOR · ROOT AUTHORITY',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Access Card
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
                          'Administrative Credentials & Security',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const Divider(height: 20),
                        _buildRow(Icons.badge_rounded, 'Administrator ID', 'ADM-SYS-001', isDark),
                        _buildRow(Icons.vpn_key_rounded, 'Access Level', 'Superuser / Full Operational Control', isDark),
                        _buildRow(Icons.rule_rounded, 'Public Signup Policy', 'Enforced Citizen-Only (Staff Restricted)', isDark),
                        _buildRow(Icons.lock_rounded, 'Session Cryptography', 'Client Session Token [SIMULATED DEMO]', isDark),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Preferences
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
                          'Theme & Frontend Settings',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const Divider(height: 20),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.palette_rounded, color: AppColors.primaryTeal),
                          title: Text('Display Theme', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(themeLabel, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showThemePicker(context),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.hub_rounded, color: AppColors.primaryTeal),
                          title: Text('Django REST Framework Client', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text('Prepared for future DRF API endpoints and MySQL schema', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Out
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusMaintenance,
                    side: const BorderSide(color: AppColors.statusMaintenance),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('End Administrator Session'),
                  onPressed: () => _showLogoutDialog(context),
                ),

                const SizedBox(height: 32),

                // Footer
                const Center(child: ResQWordmark(fontSize: 18)),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'ResQ Emergency Response Platform · Version 1.0.0 (Demo Prototype)',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryTeal),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
