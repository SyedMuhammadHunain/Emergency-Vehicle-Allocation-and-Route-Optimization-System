import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/incident_model.dart';
import '../../../data/models/responder_model.dart';

class MapProvider extends ChangeNotifier {
  final MapController mapController = MapController();

  LatLng _currentCenter = AppConstants.defaultLocation;
  double _currentZoom = AppConstants.defaultMapZoom;

  bool _showIncidents = true;
  bool _showResponders = true;
  bool _showTraffic = false;

  EmergencyType? _mapFilterType;
  IncidentModel? _selectedIncident;
  ResponderModel? _selectedResponder;

  final List<ResponderModel> _responders = List.from(MockData.nearbyResponders);

  LatLng get currentCenter => _currentCenter;
  double get currentZoom => _currentZoom;
  bool get showIncidents => _showIncidents;
  bool get showResponders => _showResponders;
  bool get showTraffic => _showTraffic;
  EmergencyType? get mapFilterType => _mapFilterType;
  IncidentModel? get selectedIncident => _selectedIncident;
  ResponderModel? get selectedResponder => _selectedResponder;
  List<ResponderModel> get responders => List.unmodifiable(_responders);

  void toggleIncidents(bool value) {
    _showIncidents = value;
    notifyListeners();
  }

  void toggleResponders(bool value) {
    _showResponders = value;
    notifyListeners();
  }

  void toggleTraffic(bool value) {
    _showTraffic = value;
    notifyListeners();
  }

  void setFilterType(EmergencyType? type) {
    _mapFilterType = type;
    notifyListeners();
  }

  void selectIncident(IncidentModel? incident) {
    _selectedIncident = incident;
    _selectedResponder = null;
    if (incident != null) {
      animateTo(LatLng(incident.latitude, incident.longitude), 15.0);
    }
    notifyListeners();
  }

  void selectResponder(ResponderModel? responder) {
    _selectedResponder = responder;
    _selectedIncident = null;
    if (responder != null) {
      animateTo(LatLng(responder.latitude, responder.longitude), 15.0);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIncident = null;
    _selectedResponder = null;
    notifyListeners();
  }

  void animateTo(LatLng location, double zoom) {
    _currentCenter = location;
    _currentZoom = zoom;
    mapController.move(location, zoom);
    notifyListeners();
  }

  void resetToDefault() {
    animateTo(AppConstants.defaultLocation, AppConstants.defaultMapZoom);
  }
}
