import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';
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
  String _activeFilter = 'ALL'; // 'ALL' | 'ACTIVE' | 'RESOLVED'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.watch<MockRepository>();

    List<DemoEmergency> list;
    if (_activeFilter == 'ACTIVE') {
      list = repo.activeEmergencies;
    } else if (_activeFilter == 'RESOLVED') {
      list = repo.resolvedEmergencies;
    } else {
      list = repo.emergencies;
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header & Filter bar
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

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All Reports (${repo.emergencies.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('ACTIVE', 'Active (${repo.activeEmergencies.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('RESOLVED', 'Resolved (${repo.resolvedEmergencies.length})'),
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

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _activeFilter == filterKey;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.primaryTeal,
      ),
      selectedColor: AppColors.primaryTeal,
      backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected ? AppColors.primaryTeal : AppColors.primaryTeal.withValues(alpha: 0.3),
      ),
      onSelected: (_) => setState(() => _activeFilter = filterKey),
    );
  }

  Widget _buildEmergencyReportCard(BuildContext context, DemoEmergency item, bool isDark) {
    final dateStr = DateFormat('MMM d, y · h:mm a').format(item.reportedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/citizen/details/${item.id}');
        },
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
                          item.id,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.category,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  StatusChip(status: item.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.place_rounded, size: 14, color: AppColors.primaryTeal),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Severity: ${item.severity}/5',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
