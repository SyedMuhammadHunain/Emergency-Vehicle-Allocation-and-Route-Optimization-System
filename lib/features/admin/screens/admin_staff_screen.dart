import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/widgets/feedback/state_widgets.dart';

class AdminStaffScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const AdminStaffScreen({super.key, this.onNavigateToTab});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  String _selectedRoleFilter = 'ALL';
  String _searchQuery = '';

  final List<String> _roles = ['ALL', 'dispatcher', 'driver', 'citizen'];

  void _showCreateStaffDialog(BuildContext context, MockRepository repo) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedRole = 'dispatcher';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: AppColors.primaryTeal, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Provision Staff Account',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
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
                      Text(
                        'Create an operational staff account for Karachi dispatch or field driver responders. (Admin exclusive)',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 14),

                      // Role Selector
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Operational Role',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'dispatcher', child: Text('Dispatcher (Control Room)')),
                          DropdownMenuItem(value: 'driver', child: Text('Driver (Field Responder)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedRole = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'e.g. Asad Siddiqui',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter staff full name' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Official Email',
                          hintText: 'e.g. asad@resq.com',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) {
                          if (v == null || !v.contains('@')) return 'Enter valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact / Phone',
                          hintText: '+92 300 9876543',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Initial Password',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Password must be >= 6 chars' : null,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    final newStaff = repo.createStaffAccount(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      password: passwordCtrl.text.trim(),
                      role: selectedRole,
                      phone: phoneCtrl.text.trim(),
                    );

                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.statusCompleted,
                        content: Text(
                          'Staff account created: ${newStaff.email} (${newStaff.role.toUpperCase()}). Can now log in on Login screen!',
                        ),
                      ),
                    );
                  },
                  child: const Text('Provision Account'),
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
    final repo = context.watch<MockRepository>();

    final accounts = repo.accounts.where((u) {
      if (_selectedRoleFilter != 'ALL' && u.role.toLowerCase() != _selectedRoleFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = u.name.toLowerCase().contains(q);
        final matchEmail = u.email.toLowerCase().contains(q);
        final matchRole = u.role.toLowerCase().contains(q);
        return matchName || matchEmail || matchRole;
      }
      return true;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Provision Staff'),
        onPressed: () => _showCreateStaffDialog(context, repo),
      ),
      body: Column(
        children: [
          // Filter & Search Controls Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search accounts by name, email, or role...',
                    hintStyle: GoogleFonts.inter(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _roles.map((r) {
                      final isSelected = _selectedRoleFilter == r;
                      final count = r == 'ALL'
                          ? repo.accounts.length
                          : repo.accounts.where((a) => a.role == r).length;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${r.toUpperCase()} ($count)'),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedRoleFilter = r),
                          selectedColor: AppColors.primaryTeal,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Users & Staff List
          Expanded(
            child: accounts.isEmpty
                ? const Center(
                    child: EmptyState(
                      'No Accounts Found',
                      subtitle: 'Try adjusting your search query or role filter.',
                      icon: Icons.person_off_rounded,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final user = accounts[index];
                      final isStaff = user.role == 'dispatcher' || user.role == 'driver';
                      final isAdmin = user.role == 'admin';

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
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (isAdmin
                                          ? AppColors.emergencyPink
                                          : isStaff
                                              ? AppColors.primaryTeal
                                              : AppColors.aquaAccent)
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isAdmin
                                      ? Icons.security_rounded
                                      : user.role == 'dispatcher'
                                          ? Icons.headset_mic_rounded
                                          : user.role == 'driver'
                                              ? Icons.local_shipping_rounded
                                              : Icons.person_rounded,
                                  color: isAdmin
                                      ? AppColors.emergencyPink
                                      : isStaff
                                          ? AppColors.primaryTeal
                                          : AppColors.primaryNavy,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          user.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            user.role.toUpperCase(),
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primaryTeal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.email,
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                    ),
                                    if (user.phone.isNotEmpty)
                                      Text(
                                        'Phone: ${user.phone}',
                                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),

                              // Active / Inactive Toggle (cannot deactivate root admin)
                              if (!isAdmin) ...[
                                Column(
                                  children: [
                                    Text(
                                      user.isActive ? 'Active' : 'Inactive',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: user.isActive ? AppColors.statusCompleted : Colors.red,
                                      ),
                                    ),
                                    Switch(
                                      value: user.isActive,
                                      activeThumbColor: AppColors.statusCompleted,
                                      onChanged: (val) {
                                        repo.toggleUserStatus(user.id);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
