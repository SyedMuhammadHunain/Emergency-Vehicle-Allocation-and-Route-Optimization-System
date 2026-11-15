import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/brand/resq_wordmark.dart';
import '../../../data/models/user_profile_model.dart';

class CitizenProfileScreen extends StatelessWidget {
  const CitizenProfileScreen({super.key});

  void _showThemePicker(BuildContext context) {
    final theme = context.read<ThemeController>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Appearance Theme',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
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
        title: Text(
          'Sign Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to sign out of your ResQ account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.statusMaintenance,
            ),
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

  void _showEditMedicalDialog(
    BuildContext context,
    MockRepository repo,
    UserProfileModel currentProfile,
  ) {
    final formKey = GlobalKey<FormState>();
    String selectedBloodType = currentProfile.bloodType.isNotEmpty
        ? currentProfile.bloodType
        : 'None';
    final allergiesCtrl = TextEditingController(
      text: currentProfile.allergies.join(', '),
    );
    final contactNameCtrl = TextEditingController(
      text: currentProfile.emergencyContacts.isNotEmpty
          ? currentProfile.emergencyContacts.first.name
          : '',
    );
    final contactPhoneCtrl = TextEditingController(
      text: currentProfile.emergencyContacts.isNotEmpty
          ? currentProfile.emergencyContacts.first.phoneNumber
          : '',
    );
    final hospitalCtrl = TextEditingController(
      text: currentProfile.preferredHospital,
    );

    final bloodTypes = [
      'None',
      'A+',
      'A-',
      'B+',
      'B-',
      'AB+',
      'AB-',
      'O+',
      'O-',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: AppColors.primaryTeal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Edit Medical Details',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: bloodTypes.contains(selectedBloodType)
                            ? selectedBloodType
                            : 'None',
                        decoration: InputDecoration(
                          labelText: 'Blood Group',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: bloodTypes
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(b == 'None' ? 'Not specified' : b),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedBloodType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: allergiesCtrl,
                        decoration: InputDecoration(
                          labelText: 'Known Allergies (comma-separated)',
                          hintText: 'e.g. Penicillin, Pollen',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contactNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact Name',
                          hintText: 'e.g. Fatima Khan',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contactPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact Phone',
                          hintText: '03XXXXXXXXX',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: hospitalCtrl,
                        decoration: InputDecoration(
                          labelText: 'Preferred Hospital',
                          hintText: 'e.g. Aga Khan Hospital, Karachi',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final rawAllergies = allergiesCtrl.text.trim();
                    final parsedAllergies = rawAllergies.isNotEmpty
                        ? rawAllergies
                              .split(',')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList()
                        : <String>[];

                    final contacts = <EmergencyContact>[];
                    if (contactNameCtrl.text.trim().isNotEmpty ||
                        contactPhoneCtrl.text.trim().isNotEmpty) {
                      contacts.add(
                        EmergencyContact(
                          id: 'EC-${DateTime.now().millisecondsSinceEpoch}',
                          name: contactNameCtrl.text.trim(),
                          relationship: 'Next of Kin',
                          phoneNumber: contactPhoneCtrl.text.trim(),
                          isPrimary: true,
                        ),
                      );
                    }

                    final updated = currentProfile.copyWith(
                      bloodType: selectedBloodType == 'None'
                          ? ''
                          : selectedBloodType,
                      allergies: parsedAllergies,
                      preferredHospital: hospitalCtrl.text.trim(),
                      emergencyContacts: contacts,
                    );

                    repo.saveUserProfile(updated);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.statusCompleted,
                        content: Text(
                          'Medical ID and emergency details saved successfully.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Save Details'),
                ),
              ],
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
    final theme = context.watch<ThemeController>();
    final repo = context.watch<MockRepository>();
    final profile = repo.getProfileForUser(
      session.userId ?? 'USR-CIT-DEFAULT',
      name: session.userName,
      email: session.userEmail,
      phone: session.userPhone,
    );

    final themeLabel = theme.mode == ThemeMode.system
        ? 'System Default'
        : (theme.mode == ThemeMode.light ? 'Light Mode' : 'Dark Mode');

    final emailText = session.userEmail.isNotEmpty
        ? session.userEmail
        : 'No email registered';
    final phoneText = session.userPhone.isNotEmpty
        ? session.userPhone
        : 'No contact registered';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Avatar & Identity Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              session.userName.isNotEmpty
                                  ? session.userName[0].toUpperCase()
                                  : 'C',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
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
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$emailText · $phoneText',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'REGISTERED CITIZEN',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Medical Emergency ID Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Medical ID & Emergency Contacts',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primaryTeal,
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 14),
                      label: Text(
                        'Edit Details',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () =>
                          _showEditMedicalDialog(context, repo, profile),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Blood Group',
                          profile.bloodType.isNotEmpty
                              ? profile.bloodType
                              : 'Not specified',
                          Icons.bloodtype_rounded,
                          AppColors.emergencyPink,
                        ),
                        const Divider(height: 16),
                        _buildInfoRow(
                          'Known Allergies',
                          profile.allergies.isNotEmpty
                              ? profile.allergies.join(', ')
                              : 'None recorded',
                          Icons.medical_services_outlined,
                          AppColors.statusPending,
                        ),
                        const Divider(height: 16),
                        _buildInfoRow(
                          'Next of Kin',
                          profile.emergencyContacts.isNotEmpty
                              ? '${profile.emergencyContacts.first.name} (${profile.emergencyContacts.first.phoneNumber})'
                              : 'No emergency contact entered',
                          Icons.contact_phone_outlined,
                          AppColors.primaryTeal,
                        ),
                        const Divider(height: 16),
                        _buildInfoRow(
                          'Preferred Hospital',
                          profile.preferredHospital.isNotEmpty
                              ? profile.preferredHospital
                              : 'Not specified',
                          Icons.local_hospital_outlined,
                          AppColors.infoCyan,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Settings & Preferences
                Text(
                  'App Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.palette_outlined,
                          color: AppColors.primaryTeal,
                        ),
                        title: Text(
                          'Appearance Theme',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          themeLabel,
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showThemePicker(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.primaryTeal,
                        ),
                        title: Text(
                          'Push Notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Enabled for dispatch alerts',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        trailing: Switch(
                          value: true,
                          activeThumbColor: AppColors.primaryTeal,
                          onChanged: (_) {},
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primaryTeal,
                        ),
                        title: Text(
                          'Location Permission',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Device GPS active for Karachi region',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        trailing: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.statusCompleted,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // App Info & Branding
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Center(child: ResQWordmark(fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(
                          'ResQ Emergency Response Platform · Karachi',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Frontend Prototype v1.0.0 (Phase 2)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Sign Out Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.statusMaintenance),
                    foregroundColor: AppColors.statusMaintenance,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    'Sign Out of ResQ',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => _showLogoutDialog(context),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
