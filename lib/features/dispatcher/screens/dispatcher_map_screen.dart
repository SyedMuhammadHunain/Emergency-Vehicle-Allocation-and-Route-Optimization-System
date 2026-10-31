import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/demo_data.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/widgets/feedback/status_chip.dart';

class DispatcherMapScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const DispatcherMapScreen({super.key, this.onNavigateToTab});

  @override
  State<DispatcherMapScreen> createState() => _DispatcherMapScreenState();
}

class _DispatcherMapScreenState extends State<DispatcherMapScreen> {
  final MapController _mapController = MapController();
  String _activeFilter = 'ALL'; // 'ALL', 'EMERGENCIES', 'VEHICLES', 'ROADS'

  DemoEmergency? _selectedEmergency;
  DemoVehicle? _selectedVehicle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.watch<MockRepository>();

    final emergencies = repo.emergencies;
    final vehicles = repo.vehicles;
    final blockedRoads = repo.blockedRoads;

    // Filter markers
    final showEmergencies = _activeFilter == 'ALL' || _activeFilter == 'EMERGENCIES';
    final showVehicles = _activeFilter == 'ALL' || _activeFilter == 'VEHICLES';
    final showRoads = _activeFilter == 'ALL' || _activeFilter == 'ROADS';

    // Prepare route polylines between active emergencies and their assigned vehicles
    final polylines = <Polyline>[];
    if (showEmergencies && showVehicles) {
      for (final emergency in emergencies) {
        if (emergency.assignedVehicle != null && emergency.status != EmergencyStatus.resolved) {
          final start = emergency.assignedVehicle!.location;
          final end = emergency.location;
          polylines.add(
            Polyline(
              points: [
                start,
                LatLng(start.latitude + (end.latitude - start.latitude) * 0.4, start.longitude),
                LatLng(start.latitude + (end.latitude - start.latitude) * 0.75, end.longitude),
                end,
              ],
              strokeWidth: 4.0,
              color: AppColors.primaryTeal.withValues(alpha: 0.85),
            ),
          );
        }
      }
    }

    // Build markers
    final markers = <Marker>[];

    // Prepare blocked roads markers
    if (showRoads) {
      for (final r in blockedRoads.where((b) => b.isBlocked)) {
        markers.add(
          Marker(
            point: r.location,
            width: 32,
            height: 32,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.statusMaintenance,
                    content: Text('Blocked: ${r.roadName} - ${r.reason}'),
                  ),
                );
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.do_not_disturb_on_total_silence_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        );
      }
    }

    // 1. Emergency Markers
    if (showEmergencies) {
      for (final e in emergencies) {
        final isResolved = e.status == EmergencyStatus.resolved;
        final color = isResolved ? Colors.grey : AppColors.forCategory(e.category);

        markers.add(
          Marker(
            point: e.location,
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEmergency = e;
                  _selectedVehicle = null;
                });
                _mapController.move(e.location, 14.5);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: _selectedEmergency?.id == e.id ? 3.5 : 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  e.category == EmergencyCategory.medical
                      ? Icons.medical_services_rounded
                      : e.category == EmergencyCategory.fire
                          ? Icons.local_fire_department_rounded
                          : e.category == EmergencyCategory.accident
                              ? Icons.car_crash_rounded
                              : Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    // 2. Vehicle Markers
    if (showVehicles) {
      for (final v in vehicles) {
        final isAvailable = v.status == 'Available';
        final vColor = isAvailable ? AppColors.statusCompleted : AppColors.statusAssigned;

        markers.add(
          Marker(
            point: v.location,
            width: 42,
            height: 42,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedVehicle = v;
                  _selectedEmergency = null;
                });
                _mapController.move(v.location, 14.5);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: vColor,
                    width: _selectedVehicle?.id == v.id ? 3.5 : 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  v.type.contains('Fire')
                      ? Icons.fire_truck_rounded
                      : v.type.contains('Rescue')
                          ? Icons.airport_shuttle_rounded
                          : Icons.emergency_rounded,
                  color: vColor,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }



    return Scaffold(
      body: Stack(
        children: [
          // FlutterMap Karachi Base
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(24.8607, 67.0011),
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.resq.resq_app',
              ),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
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
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.statusPending.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.statusPending, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SIMULATED KARACHI DEMO OPERATIONS MAP · Live incidents, vehicle fleet & road blocks',
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

          // Filter Floating Bar (Top Below Banner)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildFilterPill('ALL', 'All Layers (${emergencies.length + vehicles.length})'),
                    _buildFilterPill('EMERGENCIES', 'Incidents (${emergencies.length})'),
                    _buildFilterPill('VEHICLES', 'Fleet (${vehicles.length})'),
                    _buildFilterPill('ROADS', 'Road Blocks (${blockedRoads.where((r) => r.isBlocked).length})'),
                  ],
                ),
              ),
            ),
          ),

          // Map Controls (Right Side)
          Positioned(
            right: 16,
            bottom: _selectedEmergency != null || _selectedVehicle != null ? 220 : 24,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomInBtn',
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  foregroundColor: AppColors.primaryTeal,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.camera.center, zoom);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOutBtn',
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  foregroundColor: AppColors.primaryTeal,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.camera.center, zoom);
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'recenterBtn',
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    _mapController.move(const LatLng(24.8607, 67.0011), 13.0);
                  },
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),

          // Selected Marker Detail Sheet (Bottom)
          if (_selectedEmergency != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildEmergencyBottomSheet(context, _selectedEmergency!, repo, isDark),
            )
          else if (_selectedVehicle != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildVehicleBottomSheet(context, _selectedVehicle!, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String filterKey, String label) {
    final isSelected = _activeFilter == filterKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => setState(() => _activeFilter = filterKey),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.primaryNavy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyBottomSheet(
      BuildContext context, DemoEmergency emergency, MockRepository repo, bool isDark) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.forCategory(emergency.category).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      emergency.category == EmergencyCategory.medical
                          ? Icons.medical_services_rounded
                          : emergency.category == EmergencyCategory.fire
                              ? Icons.local_fire_department_rounded
                              : Icons.car_crash_rounded,
                      color: AppColors.forCategory(emergency.category),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    emergency.id,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryTeal),
                  ),
                ],
              ),
              Row(
                children: [
                  StatusChip(status: emergency.status),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => setState(() => _selectedEmergency = null),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            emergency.locationLabel,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            emergency.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Severity: ${emergency.severity}/5 · Urgency: ${emergency.urgency}/5',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ),
              if (emergency.status == EmergencyStatus.reported)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.account_tree_rounded, size: 16),
                  label: const Text('Allocate Unit', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    if (widget.onNavigateToTab != null) {
                      widget.onNavigateToTab!(3); // Allocation tab
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleBottomSheet(BuildContext context, DemoVehicle vehicle, bool isDark) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                vehicle.licensePlate,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryTeal),
              ),
              Row(
                children: [
                  StatusChip(status: vehicle.status.toUpperCase()),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => setState(() => _selectedVehicle = null),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${vehicle.type} · Driver: ${vehicle.driverName ?? "Available Pool"}',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Simulated Location: Karachi Central (${vehicle.location.latitude.toStringAsFixed(4)}, ${vehicle.location.longitude.toStringAsFixed(4)})',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
