import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/mock/mock_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final profile = MockData.defaultProfile;
  bool _shareGpsOnSos = true;
  bool _enableSiren = true;
  bool _notifyIceContacts = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Medical ID', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Medical ID',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Medical ID edit mode.')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Medical Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFD32F2F), const Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              profile.phoneNumber,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Blood Group Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'BLOOD',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            profile.bloodType,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 32, color: Colors.white24),

                // Medical Conditions
                const Text(
                  'KNOWN CONDITIONS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: profile.medicalConditions.map((cond) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cond,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // Allergies
                const Text(
                  'ALLERGIES',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: profile.allergies.map((allergy) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.amberAccent),
                          const SizedBox(width: 4),
                          Text(
                            allergy,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ICE Contacts Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'In Case of Emergency (ICE) Contacts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
                tooltip: 'Add ICE Contact',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add new emergency contact.')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          ...profile.emergencyContacts.map((contact) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: contact.isPrimary
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.contact_phone_rounded,
                    color: contact.isPrimary ? AppColors.primary : Colors.grey,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (contact.isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRIMARY',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text('${contact.relationship} • ${contact.phoneNumber}'),
                trailing: IconButton(
                  icon: const Icon(Icons.phone, color: AppColors.success),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Call ${contact.name}?'),
                        content: Text('Dialing ${contact.phoneNumber}...'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Call'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Emergency Settings
          const Text(
            'Emergency Preferences',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Broadcast GPS on SOS Trigger'),
                  subtitle: const Text('Transmits high-precision coordinates to local dispatch'),
                  value: _shareGpsOnSos,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _shareGpsOnSos = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Audible Emergency Siren'),
                  subtitle: const Text('Plays loud strobe siren during distress beacon'),
                  value: _enableSiren,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _enableSiren = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Auto-Notify ICE Contacts via SMS'),
                  subtitle: const Text('Sends distress message with map link to primary contacts'),
                  value: _notifyIceContacts,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _notifyIceContacts = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
