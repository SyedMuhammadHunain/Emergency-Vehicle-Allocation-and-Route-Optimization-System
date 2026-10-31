import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/widgets/cards/emergency_card.dart';
import '../../../core/widgets/feedback/state_widgets.dart';
import '../../../core/widgets/feedback/status_chip.dart';

class DispatcherEmergencyScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const DispatcherEmergencyScreen({super.key, this.onNavigateToTab});

  @override
  State<DispatcherEmergencyScreen> createState() => _DispatcherEmergencyScreenState();
}

class _DispatcherEmergencyScreenState extends State<DispatcherEmergencyScreen> {
  String _selectedStatusFilter = 'ALL';
  String _selectedCategoryFilter = 'ALL';
  String _searchQuery = '';

  final List<String> _statusFilters = ['ALL', 'REPORTED', 'ASSIGNED', 'EN_ROUTE', 'ON_SCENE', 'RESOLVED'];
  final List<String> _categoryFilters = ['ALL', 'MEDICAL', 'FIRE', 'ACCIDENT', 'RESCUE'];

  void _showEmergencyDetailsModal(BuildContext context, DemoEmergency emergency, MockRepository repo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.45,
          expand: false,
          builder: (context, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  Center(
                    child: Container(
                      width: 44,
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
                        emergency.id,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      StatusChip(status: emergency.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${emergency.category} EMERGENCY',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emergency.description,
                    style: GoogleFonts.inter(fontSize: 14, height: 1.4),
                  ),
                  const Divider(height: 28),
                  _buildDetailTile(Icons.place_rounded, 'Location', emergency.locationLabel),
                  _buildDetailTile(
                    Icons.warning_amber_rounded,
                    'Severity & Urgency',
                    'Severity: ${emergency.severity}/5  |  Urgency: ${emergency.urgency}/5',
                  ),
                  _buildDetailTile(
                    Icons.people_alt_outlined,
                    'Affected Persons',
                    '${emergency.peopleAffected} reported',
                  ),
                  _buildDetailTile(
                    Icons.person_pin_circle_outlined,
                    'Reported By',
                    'Citizen ID: ${emergency.reportedByUserId}',
                  ),
                  _buildDetailTile(
                    Icons.access_time_rounded,
                    'Report Timestamp',
                    emergency.reportedAt.toLocal().toString().split('.')[0],
                  ),
                  if (emergency.assignedVehicle != null)
                    _buildDetailTile(
                      Icons.directions_car_filled_rounded,
                      'Assigned Unit',
                      '${emergency.assignedVehicle!.type} (${emergency.assignedVehicle!.licensePlate}) - Driver: ${emergency.assignedVehicle!.driverName ?? "Assigned"}',
                    ),
                  if (emergency.allocationReason != null)
                    _buildDetailTile(
                      Icons.psychology_alt_rounded,
                      'DP Allocation Note',
                      emergency.allocationReason!,
                    ),
                  const SizedBox(height: 24),

                  // Actions
                  if (emergency.status == EmergencyStatus.reported)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.account_tree_rounded),
                      label: const Text('Open Allocation Assistant'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (widget.onNavigateToTab != null) {
                          widget.onNavigateToTab!(3); // Navigate to allocation tab
                        }
                      },
                    ),

                  if (emergency.status != EmergencyStatus.resolved) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusCompleted,
                        side: const BorderSide(color: AppColors.statusCompleted),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Mark Emergency as Resolved'),
                      onPressed: () {
                        repo.updateEmergencyStatus(emergency.id, EmergencyStatus.resolved);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.statusCompleted,
                            content: Text('${emergency.id} marked as RESOLVED.'),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.watch<MockRepository>();

    // Filter emergencies
    final filteredEmergencies = repo.emergencies.where((e) {
      if (_selectedStatusFilter != 'ALL' && e.status != _selectedStatusFilter) {
        return false;
      }
      if (_selectedCategoryFilter != 'ALL' && e.category != _selectedCategoryFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchId = e.id.toLowerCase().contains(query);
        final matchLoc = e.locationLabel.toLowerCase().contains(query);
        final matchCat = e.category.toLowerCase().contains(query);
        final matchDesc = e.description.toLowerCase().contains(query);
        return matchId || matchLoc || matchCat || matchDesc;
      }
      return true;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Filter & Search Controls Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by ID, location, or description...',
                    hintStyle: GoogleFonts.inter(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((status) {
                      final isSelected = _selectedStatusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedStatusFilter = status),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
                          ),
                          backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                          selectedColor: AppColors.primaryTeal,
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categoryFilters.map((category) {
                      final isSelected = _selectedCategoryFilter == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategoryFilter = category),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
                          ),
                          backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                          selectedColor: AppColors.primaryNavy,
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Incident List View
          Expanded(
            child: filteredEmergencies.isEmpty
                ? const Center(
                    child: EmptyState(
                      'No matching emergencies found',
                      subtitle: 'Try adjusting your search criteria or status filter.',
                      icon: Icons.search_off_rounded,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEmergencies.length,
                    itemBuilder: (context, index) {
                      final emergency = filteredEmergencies[index];
                      return EmergencyCard(
                        data: {
                          'id': emergency.id,
                          'type': emergency.category,
                          'status': emergency.status,
                          'created_at': emergency.reportedAt.toLocal().toString().split('.')[0],
                          'location': emergency.locationLabel,
                          'severity': emergency.severity,
                        },
                        onTap: () => _showEmergencyDetailsModal(context, emergency, repo),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
