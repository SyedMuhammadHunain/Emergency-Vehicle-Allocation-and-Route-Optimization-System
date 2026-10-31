import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/widgets/feedback/state_widgets.dart';
import '../../../core/widgets/feedback/status_chip.dart';

class AdminVehiclesScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const AdminVehiclesScreen({super.key, this.onNavigateToTab});

  @override
  State<AdminVehiclesScreen> createState() => _AdminVehiclesScreenState();
}

class _AdminVehiclesScreenState extends State<AdminVehiclesScreen> {
  String _selectedStatus = 'ALL';
  String _searchQuery = '';

  final List<String> _statuses = ['ALL', 'Available', 'Busy', 'Maintenance'];

  void _showAddVehicleDialog(BuildContext context, MockRepository repo) {
    final formKey = GlobalKey<FormState>();
    final plateCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    String selectedType = 'Ambulance';

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
                    child: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryTeal, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Add Fleet Vehicle',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Type',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Ambulance', child: Text('Ambulance (Paramedic Unit)')),
                        DropdownMenuItem(value: 'Fire Brigade', child: Text('Fire Brigade (Water/Foam)')),
                        DropdownMenuItem(value: 'Rescue Vehicle', child: Text('Rescue Vehicle (Heavy Extrication)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: plateCtrl,
                      decoration: InputDecoration(
                        labelText: 'License Plate / Identifier',
                        hintText: 'e.g. KHI-4499-RES',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter registration plate' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: driverCtrl,
                      decoration: InputDecoration(
                        labelText: 'Assigned Driver (Optional)',
                        hintText: 'e.g. Naveed Shah',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
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

                    repo.addVehicle(
                      licensePlate: plateCtrl.text.trim(),
                      type: selectedType,
                      driverName: driverCtrl.text.trim().isNotEmpty ? driverCtrl.text.trim() : null,
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.statusCompleted,
                        content: Text('Vehicle ${plateCtrl.text.trim()} added to fleet.'),
                      ),
                    );
                  },
                  child: const Text('Add Vehicle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangeStatusDialog(BuildContext context, DemoVehicle vehicle, MockRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Status: ${vehicle.licensePlate}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Available', 'Busy', 'Maintenance'].map((st) {
            return ListTile(
              leading: Icon(
                st == 'Available'
                    ? Icons.check_circle_rounded
                    : st == 'Busy'
                        ? Icons.timer_rounded
                        : Icons.build_rounded,
                color: AppColors.forStatus(st.toUpperCase()),
              ),
              title: Text(st),
              trailing: vehicle.status == st ? const Icon(Icons.check, color: AppColors.primaryTeal) : null,
              onTap: () {
                repo.updateVehicleStatus(vehicle.id, st);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.watch<MockRepository>();

    final vehicles = repo.vehicles.where((v) {
      if (_selectedStatus != 'ALL' && v.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchPlate = v.licensePlate.toLowerCase().contains(q);
        final matchType = v.type.toLowerCase().contains(q);
        final matchDriver = (v.driverName ?? '').toLowerCase().contains(q);
        return matchPlate || matchType || matchDriver;
      }
      return true;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Vehicle'),
        onPressed: () => _showAddVehicleDialog(context, repo),
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
                    hintText: 'Search fleet by plate, type, or driver...',
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
                    children: _statuses.map((st) {
                      final isSelected = _selectedStatus == st;
                      final count = st == 'ALL'
                          ? repo.vehicles.length
                          : repo.vehicles.where((v) => v.status.toLowerCase() == st.toLowerCase()).length;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$st ($count)'),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedStatus = st),
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

          // Vehicle List
          Expanded(
            child: vehicles.isEmpty
                ? const Center(
                    child: EmptyState(
                      'No Vehicles Found',
                      subtitle: 'Try adjusting your status filter or search query.',
                      icon: Icons.no_crash_rounded,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final v = vehicles[index];
                      final isAvailable = v.status == 'Available';

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
                                  color: (isAvailable ? AppColors.statusCompleted : AppColors.statusAssigned)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  v.type.contains('Fire')
                                      ? Icons.fire_truck_rounded
                                      : v.type.contains('Rescue')
                                          ? Icons.airport_shuttle_rounded
                                          : Icons.emergency_rounded,
                                  color: isAvailable ? AppColors.statusCompleted : AppColors.statusAssigned,
                                  size: 26,
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
                                          v.licensePlate,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StatusChip(status: v.status.toUpperCase()),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${v.type} · Driver: ${v.driverName ?? "Available Pool"}',
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                    ),
                                    if (v.assignedEmergencyId != null)
                                      Text(
                                        'Mission: ${v.assignedEmergencyId}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryTeal,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryTeal),
                                tooltip: 'Change Status',
                                onPressed: () => _showChangeStatusDialog(context, v, repo),
                              ),
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
