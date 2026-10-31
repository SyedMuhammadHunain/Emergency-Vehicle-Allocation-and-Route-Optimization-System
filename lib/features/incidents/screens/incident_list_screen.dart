import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/incident_card.dart';
import '../../../data/models/incident_model.dart';
import '../providers/incident_provider.dart';

class IncidentListScreen extends StatelessWidget {
  const IncidentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final incidentProvider = context.watch<IncidentProvider>();
    final incidents = incidentProvider.filteredIncidents;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Incident Feed',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Incidents',
            onPressed: () {
              incidentProvider.clearFilters();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feed updated to latest alerts.')),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/incidents/new'),
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Report Incident', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (val) => incidentProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search incidents, location, keyword...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: incidentProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => incidentProvider.setSearchQuery(''),
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),

          // Horizontal Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _StatusFilterChip(
                  label: 'All (${incidentProvider.allIncidents.length})',
                  isSelected: incidentProvider.filterStatus == null,
                  onTap: () => incidentProvider.setFilterStatus(null),
                ),
                _StatusFilterChip(
                  label: 'Reported',
                  color: AppColors.warning,
                  isSelected: incidentProvider.filterStatus == IncidentStatus.reported,
                  onTap: () => incidentProvider.setFilterStatus(IncidentStatus.reported),
                ),
                _StatusFilterChip(
                  label: 'Dispatched',
                  color: AppColors.info,
                  isSelected: incidentProvider.filterStatus == IncidentStatus.dispatched,
                  onTap: () => incidentProvider.setFilterStatus(IncidentStatus.dispatched),
                ),
                _StatusFilterChip(
                  label: 'On Scene',
                  color: AppColors.primary,
                  isSelected: incidentProvider.filterStatus == IncidentStatus.onScene,
                  onTap: () => incidentProvider.setFilterStatus(IncidentStatus.onScene),
                ),
                _StatusFilterChip(
                  label: 'Resolved',
                  color: AppColors.success,
                  isSelected: incidentProvider.filterStatus == IncidentStatus.resolved,
                  onTap: () => incidentProvider.setFilterStatus(IncidentStatus.resolved),
                ),
              ],
            ),
          ),

          // Incident List
          Expanded(
            child: incidents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 64,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Incidents Found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No emergency reports match the selected filters.',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => incidentProvider.clearFilters(),
                            child: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: incidents.length,
                    itemBuilder: (context, index) {
                      final inc = incidents[index];
                      return IncidentCard(
                        incident: inc,
                        onTap: () => context.push('/incidents/${inc.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? chipColor
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
          ),
        ),
      ),
    );
  }
}
