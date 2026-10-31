import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/widgets/feedback/state_widgets.dart';
import '../../../core/widgets/feedback/status_chip.dart';

class DispatcherVehiclesScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const DispatcherVehiclesScreen({super.key, this.onNavigateToTab});

  @override
  State<DispatcherVehiclesScreen> createState() => _DispatcherVehiclesScreenState();
}

class _DispatcherVehiclesScreenState extends State<DispatcherVehiclesScreen> {
  String _selectedType = 'ALL';
  String _searchQuery = '';

  final List<String> _types = ['ALL', 'Ambulance', 'Fire Brigade', 'Rescue Vehicle'];

  void _showVehicleDetails(BuildContext context, DemoVehicle vehicle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
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
                  Text(
                    vehicle.licensePlate,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  StatusChip(status: vehicle.status.toUpperCase()),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                vehicle.type,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Divider(height: 24),
              _buildRow('Assigned Driver', vehicle.driverName ?? 'Available Pool (Unassigned)', Icons.person_rounded),
              _buildRow('Base Sector', 'Karachi Central Depot', Icons.store_mall_directory_rounded),
              _buildRow(
                'Coordinates',
                '${vehicle.location.latitude.toStringAsFixed(4)}, ${vehicle.location.longitude.toStringAsFixed(4)} (Simulated)',
                Icons.location_on_rounded,
              ),
              if (vehicle.assignedEmergencyId != null)
                _buildRow('Active Mission', vehicle.assignedEmergencyId!, Icons.emergency_rounded),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryTeal),
          const SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.watch<MockRepository>();

    final vehicles = repo.vehicles.where((v) {
      if (_selectedType != 'ALL' && !v.type.toLowerCase().contains(_selectedType.toLowerCase())) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchPlate = v.licensePlate.toLowerCase().contains(q);
        final matchDriver = (v.driverName ?? '').toLowerCase().contains(q);
        final matchType = v.type.toLowerCase().contains(q);
        return matchPlate || matchDriver || matchType;
      }
      return true;
    }).toList();

    return Scaffold(
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
                    hintText: 'Search fleet by plate, driver, or type...',
                    hintStyle: GoogleFonts.inter(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _types.map((type) {
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedType = type),
                          selectedColor: AppColors.primaryTeal,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
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
                      subtitle: 'Try adjusting your search criteria.',
                      icon: Icons.local_shipping_outlined,
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
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _showVehicleDetails(context, v),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
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
                                      const SizedBox(height: 4),
                                      Text(
                                        '${v.type} · Driver: ${v.driverName ?? "Available Pool"}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              ],
                            ),
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
