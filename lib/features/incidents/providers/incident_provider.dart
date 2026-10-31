import 'package:flutter/material.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/incident_model.dart';

class IncidentProvider extends ChangeNotifier {
  final List<IncidentModel> _incidents = List.from(MockData.initialIncidents);
  EmergencyType? _filterType;
  IncidentStatus? _filterStatus;
  String _searchQuery = '';

  List<IncidentModel> get allIncidents => List.unmodifiable(_incidents);

  EmergencyType? get filterType => _filterType;
  IncidentStatus? get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;

  List<IncidentModel> get filteredIncidents {
    return _incidents.where((inc) {
      if (_filterType != null && inc.type != _filterType) {
        return false;
      }
      if (_filterStatus != null && inc.status != _filterStatus) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = inc.title.toLowerCase().contains(query);
        final matchesDesc = inc.description.toLowerCase().contains(query);
        final matchesAddress = inc.address.toLowerCase().contains(query);
        return matchesTitle || matchesDesc || matchesAddress;
      }
      return true;
    }).toList();
  }

  IncidentModel? getIncidentById(String id) {
    try {
      return _incidents.firstWhere((inc) => inc.id == id);
    } catch (_) {
      return null;
    }
  }

  void setFilterType(EmergencyType? type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterStatus(IncidentStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _filterType = null;
    _filterStatus = null;
    _searchQuery = '';
    notifyListeners();
  }

  void addIncident(IncidentModel incident) {
    _incidents.insert(0, incident);
    notifyListeners();
  }

  void updateIncidentStatus(String id, IncidentStatus newStatus) {
    final index = _incidents.indexWhere((inc) => inc.id == id);
    if (index != -1) {
      _incidents[index] = _incidents[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }
}
