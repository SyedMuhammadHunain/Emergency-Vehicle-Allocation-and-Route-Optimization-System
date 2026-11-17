import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/brand/resq_app_bar.dart';
import '../../../core/widgets/map/map_zoom_controls.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String emergencyId;

  const LiveTrackingScreen({super.key, required this.emergencyId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTracking();
    });
  }

  Future<void> _refreshTracking() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<MockRepository>();
      final api = ApiService();
      final res = await api.getEmergencyById(
        widget.emergencyId,
        mockRepo: repo,
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

  List<LatLng> _buildRoutePoints(LatLng start, LatLng end) {
    final mid1 = LatLng(
      start.latitude + (end.latitude - start.latitude) * 0.35,
      start.longitude,
    );
    final mid2 = LatLng(
      start.latitude + (end.latitude - start.latitude) * 0.7,
      end.longitude,
    );
    return [start, mid1, mid2, end];
  }

  void _showDriverCallDialog(BuildContext context, DemoVehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.phone_in_talk_rounded,
              color: AppColors.primaryTeal,
            ),
            const SizedBox(width: 8),
            Text(
              'Contact Driver',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Responder: ${vehicle.type} (${vehicle.licensePlate})',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Driver: ${vehicle.driverName ?? "Assigned Emergency Responder"}',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
            ),
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Initiate Call'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.primaryTeal,
                  content: Text('Secure dispatch call to driver initiated...'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.watch<MockRepository>();
    final emergency = repo.getEmergencyById(widget.emergencyId);

    if (emergency == null && !_isLoading) {
      return Scaffold(
        appBar: const ResQAppBar(
          subtitle: 'Tracking Unavailable',
          showBackButton: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_off_rounded,
                  size: 48,
                  color: AppColors.statusMaintenance,
                ),
                const SizedBox(height: 12),
                Text(
                  'Emergency Not Found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ??
                      'Tracking details are unavailable for ID "${widget.emergencyId}".',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back to Reports'),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/citizen');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final targetLoc = emergency?.location ?? const LatLng(24.8607, 67.0011);
    final vehicle = emergency?.assignedVehicle;
    final hasAssignedVehicle = vehicle != null;
    final vehicleLoc = vehicle?.location;

    List<LatLng> routePoints = [];
    double distanceKm = 0.0;
    int etaMins = 0;
    if (hasAssignedVehicle && vehicleLoc != null) {
      routePoints = _buildRoutePoints(vehicleLoc, targetLoc);
      distanceKm = const Distance().as(
        LengthUnit.Kilometer,
        vehicleLoc,
        targetLoc,
      );
      etaMins = ((distanceKm / 35.0) * 60).round().clamp(2, 45);
    }

    return Scaffold(
      appBar: ResQAppBar(
        subtitle: 'Live Tracking · ${emergency?.id ?? widget.emergencyId}',
        showBackButton: true,
      ),
      body: Stack(
        children: [
          // 2D OpenStreetMap Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: targetLoc, initialZoom: 13.5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: AppConstants.packageName,
                maxZoom: 18,
                panBuffer: 1,
              ),

              // Route Polyline only when vehicle is assigned
              if (hasAssignedVehicle && routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5.0,
                      color: AppColors.primaryTeal,
                    ),
                    Polyline(
                      points: routePoints,
                      strokeWidth: 8.0,
                      color: AppColors.aquaAccent.withValues(alpha: 0.35),
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // Emergency Destination Marker
                  Marker(
                    point: targetLoc,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.emergencyPink,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.crisis_alert_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // Vehicle Marker only if vehicle is assigned
                  if (hasAssignedVehicle && vehicleLoc != null)
                    Marker(
                      point: vehicleLoc,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkTeal,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.aquaAccent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Working Map Zoom Controls (+) and (-)
          MapZoomControls(
            mapController: _mapController,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(top: 60, right: 16),
          ),

          // Top Status Banner
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasAssignedVehicle
                      ? AppColors.primaryTeal.withValues(alpha: 0.6)
                      : AppColors.statusPending.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasAssignedVehicle
                        ? Icons.directions_car_rounded
                        : Icons.hourglass_top_rounded,
                    color: hasAssignedVehicle
                        ? AppColors.primaryTeal
                        : AppColors.statusPending,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasAssignedVehicle
                          ? 'Assigned: ${vehicle.type} (${vehicle.licensePlate}) en route to emergency location.'
                          : 'Awaiting Dispatcher Assignment · Vehicle tracking activates once dispatched.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recenter Map FAB (placed cleanly below zoom controls to avoid card collision)
          Positioned(
            right: 16,
            top: 155,
            child: FloatingActionButton.small(
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              foregroundColor: AppColors.primaryTeal,
              tooltip: 'Recenter on incident',
              onPressed: () {
                _mapController.move(targetLoc, 14.0);
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // Bottom Status Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: hasAssignedVehicle
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTeal.withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.directions_car_rounded,
                                    color: AppColors.primaryTeal,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              vehicle.licensePlate,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.statusAssigned
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            vehicle.type,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.statusAssigned,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${vehicle.driverName ?? "Responder"} · ${vehicle.status}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: _buildStat(
                                  'Estimated ETA',
                                  '~$etaMins mins',
                                  AppColors.primaryTeal,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              Expanded(
                                child: _buildStat(
                                  'Distance',
                                  '${distanceKm.toStringAsFixed(1)} km',
                                  isDark ? Colors.white : AppColors.lightTextNavy,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              Expanded(
                                child: _buildStat(
                                  'Status',
                                  vehicle.status,
                                  isDark ? Colors.white : AppColors.lightTextNavy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.primaryTeal,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.phone_in_talk_rounded,
                                    size: 16,
                                    color: AppColors.primaryTeal,
                                  ),
                                  label: Text(
                                    'Call Driver',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryTeal,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _showDriverCallDialog(context, vehicle),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primaryTeal,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Refresh',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onPressed: _refreshTracking,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.statusPending.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.access_time_rounded,
                                  color: AppColors.statusPending,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Awaiting Dispatcher Assignment',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Incident reported at ${emergency?.locationLabel ?? "Karachi Grid"}. Dispatchers are triaging.',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: _buildStat(
                                  'Category',
                                  emergency?.category ?? 'General',
                                  AppColors.primaryTeal,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              Expanded(
                                child: _buildStat(
                                  'Severity',
                                  'Level ${emergency?.severity ?? 3}',
                                  AppColors.emergencyPink,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              Expanded(
                                child: _buildStat(
                                  'Status',
                                  emergency?.status ?? EmergencyStatus.reported,
                                  AppColors.statusPending,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(
                                'Refresh Dispatch Status',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: _refreshTracking,
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
