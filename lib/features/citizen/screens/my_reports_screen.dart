// Citizen My Reports Screen – integrated with live Django backend API.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart'; // DemoEmergency model definition
import '../../../core/services/api_service.dart';
import '../../../core/widgets/feedback/state_widgets.dart';
import '../../../core/widgets/feedback/status_chip.dart';

class MyReportsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToReport;

  const MyReportsScreen({
    super.key,
    this.onNavigateToReport,
  });

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _activeFilter = 'ALL'; // ALL | ACTIVE | RESOLVED
  bool _loading = true;
  String? _error;
  List<DemoEmergency> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      // Query backend for the current user's emergencies.
      final raw = await ApiService.instance.getEmergencies(mine: true);
      // Assume the API returns a list of JSON objects matching DemoEmergency fields.
      final List<DemoEmergency> list = (raw.data?['results'] as List<dynamic>?)?.map((e) => DemoEmergency.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      setState(() {
        _reports = list;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<DemoEmergency> get _filtered {
    if (_activeFilter == 'ACTIVE') {
      return _reports.where((e) => e.status == EmergencyStatus.reported || e.status == EmergencyStatus.assigned || e.status == EmergencyStatus.enRoute || e.status == EmergencyStatus.onScene).toList();
    } else if (_activeFilter == 'RESOLVED') {
      return _reports.where((e) => e.status == EmergencyStatus.resolved).toList();
    }
    return _reports;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = _filtered;
    return Scaffold(
      body: _loading
          ? const Center(child: LoadingState())
          : _error != null
              ? Center(child: ErrorState(message: _error!, onRetry: _loadReports))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header & filter bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Incident Reports',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.lightTextNavy,
                                ),
                              ),
                              Text(
                                '${list.length} reports',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Filter chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('ALL', 'All Reports (${_reports.length})'),
                                const SizedBox(width: 8),
                                _buildFilterChip('ACTIVE', 'Active (${_reports.where((e) => e.status == EmergencyStatus.reported || e.status == EmergencyStatus.assigned || e.status == EmergencyStatus.enRoute || e.status == EmergencyStatus.onScene).length})'),
                                const SizedBox(width: 8),
                                _buildFilterChip('RESOLVED', 'Resolved (${_reports.where((e) => e.status == EmergencyStatus.resolved).length})'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (list.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: EmptyState(
                                'No reports found',
                                subtitle: _activeFilter == 'ACTIVE'
                                    ? 'You have no active emergency reports pending triage.'
                                    : 'No incidents recorded under this filter.',
                                icon: Icons.assignment_late_outlined,
                                action: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                                  onPressed: () {
                                    if (widget.onNavigateToReport != null) {
                                      widget.onNavigateToReport!();
                                    } else {
                                      context.push('/citizen/report');
                                    }
                                  },
                                  child: const Text('Report Emergency'),
                                ),
                              ),
                            )
                          else
                            ...list.map((e) => _buildEmergencyReportCard(context, e, isDark)),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _activeFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? Colors.white : AppColors.primaryTeal,
      ),
      selectedColor: AppColors.primaryTeal,
      backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
      side: BorderSide(color: selected ? AppColors.primaryTeal : AppColors.primaryTeal.withValues(alpha: 0.3)),
      onSelected: (_) => setState(() => _activeFilter = key),
    );
  }

  Widget _buildEmergencyReportCard(BuildContext ctx, DemoEmergency e, bool isDark) {

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ctx.push('/citizen/details/${e.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          e.id,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryTeal),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        e.category,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  StatusChip(status: e.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                e.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
