import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/widgets/brand/resq_app_bar.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String emergencyId;

  const LiveTrackingScreen({
    super.key,
    required this.emergencyId,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();

  // Simulated intermediate route waypoints in Karachi
  List<LatLng> _buildSimulatedRoute(LatLng start, LatLng end) {
    // Generate a simulated realistic path through Karachi grid
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
            const Icon(Icons.phone_in_talk_rounded, color: AppColors.primaryTeal),
            const SizedBox(width: 8),
            Text('Contact Driver', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Responder: ${vehicle.type} (${vehicle.licensePlate})',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Call driver via ResQ Dispatch secure bridge. [SIMULATED DEMO]',
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Initiate Call'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.primaryTeal,
                  content: Text('Simulated secure call to driver initiated...'),
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

    // Fallback if not found
    final targetLoc = emergency?.location ?? const LatLng(24.8607, 67.0011);
    final vehicle = emergency?.assignedVehicle ?? kDemoVehicles[0];
    final vehicleLoc = vehicle.location;

    final routePoints = _buildSimulatedRoute(vehicleLoc, targetLoc);

    return Scaffold(
      appBar: ResQAppBar(
        subtitle: 'Live Tracking · ${emergency?.id ?? "Simulated Route"}',
        showBackButton: true,
      ),
      body: Stack(
        children: [
          // 2D OpenStreetMap Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: targetLoc,
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.resq.resq_app',
              ),

              // Simulated Route Polyline
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

                  // Vehicle Marker
                  Marker(
                    point: vehicleLoc,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.aquaAccent, width: 2.5),
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

          // Top Prominent Simulation Disclaimer
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.statusPending.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.statusPending,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SIMULATED DEMO · Dijkstra optimal route estimate. No live GPS hardware tracking.',
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

          // Recenter Map FAB
          Positioned(
            right: 16,
            bottom: 230,
            child: FloatingActionButton.small(
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              foregroundColor: AppColors.primaryTeal,
              tooltip: 'Recenter on Karachi incident',
              onPressed: () {
                _mapController.move(targetLoc, 14.0);
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // Bottom Floating Status Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withValues(alpha: 0.15),
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
                                  Text(
                                    vehicle.licensePlate,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusAssigned.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
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
                                'En Route · Karachi Traffic Normal',
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
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Estimated ETA', '~6 mins', AppColors.primaryTeal),
                        Container(width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.2)),
                        _buildStat('Distance', '2.8 km', isDark ? Colors.white : AppColors.lightTextNavy),
                        Container(width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.2)),
                        _buildStat('Speed (Sim)', '48 km/h', isDark ? Colors.white : AppColors.lightTextNavy),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryTeal),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: AppColors.primaryTeal),
                            label: Text(
                              'Call Driver',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryTeal),
                            ),
                            onPressed: () => _showDriverCallDialog(context, vehicle),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(
                              'Refresh Route',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              _mapController.move(targetLoc, 14.0);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.primaryTeal,
                                  content: Text('Simulated Dijkstra shortest route recalculated.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
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
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
