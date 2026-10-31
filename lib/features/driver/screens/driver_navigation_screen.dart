import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/services/session_service.dart';
import '../../../core/widgets/feedback/state_widgets.dart';

class DriverNavigationScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const DriverNavigationScreen({super.key, this.onNavigateToTab});

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  final MapController _mapController = MapController();

  List<LatLng> _buildSimulatedRoute(LatLng start, LatLng end) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionService>();
    final repo = context.watch<MockRepository>();

    final mission = repo.getActiveMissionForDriver(session.userName);

    if (mission == null) {
      return Scaffold(
        body: Center(
          child: EmptyState(
            'Navigation Inactive',
            subtitle: 'No emergency destination is currently assigned to your vehicle.',
            icon: Icons.navigation_outlined,
            action: widget.onNavigateToTab != null
                ? OutlinedButton(
                    onPressed: () => widget.onNavigateToTab!(0),
                    child: const Text('Back to Dashboard'),
                  )
                : null,
          ),
        ),
      );
    }

    // Default vehicle location: Karachi central
    final vehicleLocation = mission.assignedVehicle?.location ?? const LatLng(24.8607, 67.0011);
    final emergencyLocation = mission.location;
    final routePoints = _buildSimulatedRoute(vehicleLocation, emergencyLocation);

    return Scaffold(
      body: Stack(
        children: [
          // FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                (vehicleLocation.latitude + emergencyLocation.latitude) / 2,
                (vehicleLocation.longitude + emergencyLocation.longitude) / 2,
              ),
              initialZoom: 14.0,
              minZoom: 11.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.resq.resq_app',
              ),
              // Route Polylines
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 6.0,
                    color: AppColors.primaryTeal,
                  ),
                  Polyline(
                    points: routePoints,
                    strokeWidth: 10.0,
                    color: AppColors.aquaAccent.withValues(alpha: 0.3),
                  ),
                ],
              ),
              // Markers
              MarkerLayer(
                markers: [
                  // Vehicle Marker
                  Marker(
                    point: vehicleLocation,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.aquaAccent, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
                    ),
                  ),

                  // Destination Emergency Marker
                  Marker(
                    point: emergencyLocation,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.emergencyPink,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emergencyPink.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.place_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Simulation Banner (Top)
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
                  color: AppColors.statusPending.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.statusPending, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SIMULATED NAVIGATION · Shortest path estimated via Dijkstra graph search',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Turn-by-Turn Guidance Card (Top)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.turn_right_rounded, color: AppColors.primaryTeal, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'In 250m, turn right onto Main Boulevard',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Continuing towards ${mission.locationLabel}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Controls (Right Side)
          Positioned(
            right: 16,
            bottom: 170,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'driverZoomIn',
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  foregroundColor: AppColors.primaryTeal,
                  onPressed: () {
                    final z = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.camera.center, z);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'driverZoomOut',
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  foregroundColor: AppColors.primaryTeal,
                  onPressed: () {
                    final z = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.camera.center, z);
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'driverRecenter',
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    _mapController.move(vehicleLocation, 15.0);
                  },
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),

          // Floating ETA & Target Card (Bottom)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '~6 MIN',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          Text(
                            '2.8 km · Simulated Arrival 10:48 AM',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                        icon: const Icon(Icons.assignment_rounded, size: 16),
                        label: const Text('Update Status'),
                        onPressed: () {
                          if (widget.onNavigateToTab != null) widget.onNavigateToTab!(1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
