import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/incident_model.dart';
import '../../../data/models/responder_model.dart';
import '../../incidents/providers/incident_provider.dart';
import '../providers/map_provider.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapProvider = context.watch<MapProvider>();
    final incidentProvider = context.watch<IncidentProvider>();

    // Build markers for incidents
    final incidentMarkers = <Marker>[];
    if (mapProvider.showIncidents) {
      for (final inc in incidentProvider.allIncidents) {
        if (mapProvider.mapFilterType == null || inc.type == mapProvider.mapFilterType) {
          final isSelected = mapProvider.selectedIncident?.id == inc.id;

          incidentMarkers.add(
            Marker(
              point: LatLng(inc.latitude, inc.longitude),
              width: isSelected ? 48 : 38,
              height: isSelected ? 48 : 38,
              child: GestureDetector(
                onTap: () => mapProvider.selectIncident(inc),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: inc.type.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.yellowAccent : Colors.white,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: inc.type.color.withValues(alpha: 0.5),
                        blurRadius: isSelected ? 12 : 6,
                        spreadRadius: isSelected ? 3 : 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    inc.type.icon,
                    color: Colors.white,
                    size: isSelected ? 24 : 18,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    // Build markers for responders
    final responderMarkers = <Marker>[];
    if (mapProvider.showResponders) {
      for (final resp in mapProvider.responders) {
        final isSelected = mapProvider.selectedResponder?.id == resp.id;

        responderMarkers.add(
          Marker(
            point: LatLng(resp.latitude, resp.longitude),
            width: isSelected ? 46 : 36,
            height: isSelected ? 46 : 36,
            child: GestureDetector(
              onTap: () => mapProvider.selectResponder(resp),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.greenAccent : Colors.white,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  resp.type.icon,
                  color: Colors.white,
                  size: isSelected ? 22 : 16,
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
          // 2D OpenStreetMap Layer
          FlutterMap(
            mapController: mapProvider.mapController,
            options: MapOptions(
              initialCenter: mapProvider.currentCenter,
              initialZoom: mapProvider.currentZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (_, _) => mapProvider.clearSelection(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.resq.emergency.app',
                tileBuilder: isDark
                    ? (context, tileWidget, tile) {
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            -0.2, 0, 0, 0, 255, // red
                            0, -0.2, 0, 0, 255, // green
                            0, 0, -0.2, 0, 255, // blue
                            0, 0, 0, 1, 0,      // alpha
                          ]),
                          child: tileWidget,
                        );
                      }
                    : null,
              ),
              MarkerLayer(markers: [...incidentMarkers, ...responderMarkers]),
            ],
          ),

          // Top Header & Filter Controls Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search / Status Header Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emergency_share_rounded, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Live Incident Map (${incidentMarkers.length} Active)',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            mapProvider.showResponders
                                ? Icons.shield_rounded
                                : Icons.shield_outlined,
                            color: mapProvider.showResponders ? AppColors.primary : Colors.grey,
                            size: 20,
                          ),
                          tooltip: 'Toggle Responder Units',
                          onPressed: () =>
                              mapProvider.toggleResponders(!mapProvider.showResponders),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Horizontal Category Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All Incidents',
                          isSelected: mapProvider.mapFilterType == null,
                          onTap: () => mapProvider.setFilterType(null),
                        ),
                        _FilterChip(
                          label: 'Medical',
                          color: AppColors.medical,
                          isSelected: mapProvider.mapFilterType == EmergencyType.medical,
                          onTap: () => mapProvider.setFilterType(EmergencyType.medical),
                        ),
                        _FilterChip(
                          label: 'Fire',
                          color: AppColors.fire,
                          isSelected: mapProvider.mapFilterType == EmergencyType.fire,
                          onTap: () => mapProvider.setFilterType(EmergencyType.fire),
                        ),
                        _FilterChip(
                          label: 'Accidents',
                          color: AppColors.accent,
                          isSelected: mapProvider.mapFilterType == EmergencyType.accident,
                          onTap: () => mapProvider.setFilterType(EmergencyType.accident),
                        ),
                        _FilterChip(
                          label: 'Police',
                          color: AppColors.police,
                          isSelected: mapProvider.mapFilterType == EmergencyType.police,
                          onTap: () => mapProvider.setFilterType(EmergencyType.police),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Controls (Re-center and Zoom)
          Positioned(
            right: 16,
            bottom: mapProvider.selectedIncident != null || mapProvider.selectedResponder != null
                ? 210
                : 24,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter_map',
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () => mapProvider.resetToDefault(),
                  child: const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'report_from_map',
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: () => context.push('/incidents/new'),
                  child: const Icon(Icons.add_alert_rounded),
                ),
              ],
            ),
          ),

          // Bottom Preview Card when an Incident is tapped
          if (mapProvider.selectedIncident != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _IncidentMapPreview(
                incident: mapProvider.selectedIncident!,
                onClose: () => mapProvider.clearSelection(),
                onViewDetails: () =>
                    context.push('/incidents/${mapProvider.selectedIncident!.id}'),
              ),
            ),

          // Bottom Preview Card when a Responder is tapped
          if (mapProvider.selectedResponder != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _ResponderMapPreview(
                responder: mapProvider.selectedResponder!,
                onClose: () => mapProvider.clearSelection(),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
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

class _IncidentMapPreview extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  const _IncidentMapPreview({
    required this.incident,
    required this.onClose,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: incident.type.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(incident.type.icon, color: incident.type.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      incident.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                label: incident.status.displayName,
                color: incident.status.color,
              ),
              ElevatedButton(
                onPressed: onViewDetails,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                child: const Text('View Incident'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponderMapPreview extends StatelessWidget {
  final ResponderModel responder;
  final VoidCallback onClose;

  const _ResponderMapPreview({
    required this.responder,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: responder.type.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(responder.type.icon, color: responder.type.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      responder.callSign,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      responder.stationName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                label: responder.isAvailable ? 'Available • On Standby' : 'Dispatched',
                color: responder.isAvailable ? AppColors.success : AppColors.warning,
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling ${responder.callSign} dispatch...')),
                  );
                },
                icon: const Icon(Icons.call, size: 16),
                label: const Text('Contact Unit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
