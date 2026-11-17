import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/widgets/feedback/state_widgets.dart';
import '../../../core/widgets/feedback/status_chip.dart';

class MyReportsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToReport;

  const MyReportsScreen({super.key, this.onNavigateToReport});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _activeFilter = 'ALL'; // 'ALL' | 'ACTIVE' | 'RESOLVED'
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReports();
    });
  }

  Future<void> _fetchReports() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = context.read<SessionService>();
      final repo = context.read<MockRepository>();
      final api = ApiService();

      final res = await api.getEmergencies(
        mockRepo: repo,
        userId: session.userId,
        userEmail: session.userEmail,
        userName: session.userName,
      );

      if (!mounted) {
        return;
      }
      if (res.hasError && !res.isFromFallback) {
        setState(() {
          _errorMessage = res.error;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.watch<MockRepository>();
    final session = context.watch<SessionService>();

    final userEmergencies = repo.getEmergenciesForUser(
      session.userId ?? '',
      userEmail: session.userEmail,
      userName: session.userName,
    );

    final activeCount = userEmergencies
        .where((e) => e.status != EmergencyStatus.resolved)
        .length;
    final resolvedCount = userEmergencies
        .where((e) => e.status == EmergencyStatus.resolved)
        .length;

    List<DemoEmergency> list;
    if (_activeFilter == 'ACTIVE') {
      list = userEmergencies
          .where((e) => e.status != EmergencyStatus.resolved)
          .toList();
    } else if (_activeFilter == 'RESOLVED') {
      list = userEmergencies
          .where((e) => e.status == EmergencyStatus.resolved)
          .toList();
    } else {
      list = userEmergencies;
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchReports,
          color: AppColors.primaryTeal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                        Expanded(
                          child: Text(
                            'My Incident Reports',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Refresh Reports',
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              color: AppColors.primaryTeal,
                              onPressed: _isLoading ? null : _fetchReports,
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
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'ALL',
                          'All Reports (${userEmergencies.length})',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip('ACTIVE', 'Active ($activeCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'RESOLVED',
                          'Resolved ($resolvedCount)',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_isLoading && userEmergencies.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.primaryTeal,
                            ),
                            SizedBox(height: 16),
                            Text('Loading your incident reports...'),
                          ],
                        ),
                      ),
                    )
                  else if (_errorMessage != null && userEmergencies.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.statusMaintenance,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load reports',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retry'),
                              onPressed: _fetchReports,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: EmptyState(
                        'No reports found',
                        subtitle: _activeFilter == 'ACTIVE'
                            ? 'You have no active emergency reports pending triage.'
                            : 'You have not submitted any reports under this filter.',
                        icon: Icons.assignment_late_outlined,
                        action: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                          ),
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
                    ...list.map(
                      (e) => _buildEmergencyReportCard(context, e, isDark),
                    ),
                ],
              ),
            ),
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
        color: isSelected
            ? AppColors.primaryTeal
            : AppColors.primaryTeal.withValues(alpha: 0.3),
      ),
      onSelected: (_) => setState(() => _activeFilter = filterKey),
    );
  }

  Widget _buildEmergencyReportCard(
    BuildContext context,
    DemoEmergency item,
    bool isDark,
  ) {
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
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
                        Flexible(
                          child: Text(
                            item.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  const Icon(
                    Icons.place_rounded,
                    size: 14,
                    color: AppColors.primaryTeal,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dateStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
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
