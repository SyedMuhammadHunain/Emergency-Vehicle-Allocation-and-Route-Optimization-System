import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/incident_model.dart';
import '../providers/incident_provider.dart';

class ReportIncidentScreen extends StatefulWidget {
  final EmergencyType initialType;

  const ReportIncidentScreen({
    super.key,
    this.initialType = EmergencyType.medical,
  });

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();

  late EmergencyType _selectedType;
  IncidentSeverity _selectedSeverity = IncidentSeverity.high;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController(
    text: 'Current GPS Location (Market St & 5th Ave)',
  );
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _titleController.text = '${_selectedType.displayName} Reported';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final newId = 'INC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final incident = IncidentModel(
      id: newId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? 'Urgent citizen incident report submitted via ResQ app.'
          : _descriptionController.text.trim(),
      type: _selectedType,
      status: IncidentStatus.reported,
      severity: _selectedSeverity,
      latitude: 37.7749 + (DateTime.now().millisecond % 20 - 10) * 0.001,
      longitude: -122.4194 + (DateTime.now().millisecond % 20 - 10) * 0.001,
      address: _locationController.text.trim(),
      reporterName: 'Alex Vance (Citizen)',
      reportedAt: DateTime.now(),
      assignedResponderUnit: 'Dispatching Nearest Unit...',
      estimatedArrivalMinutes: 5,
    );

    context.read<IncidentProvider>().addIncident(incident);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Incident #$newId submitted to emergency dispatch.'),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Emergency Incident'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Category selector title
            const Text(
              'Select Emergency Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EmergencyType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  avatar: Icon(
                    type.icon,
                    size: 18,
                    color: isSelected ? Colors.white : type.color,
                  ),
                  label: Text(type.displayName),
                  selected: isSelected,
                  selectedColor: type.color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedType = type;
                        _titleController.text = '${type.displayName} Incident';
                      });
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Severity level selector
            const Text(
              'Severity Assessment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            Row(
              children: IncidentSeverity.values.map((sev) {
                final isSelected = _selectedSeverity == sev;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedSeverity = sev),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? sev.color
                              : sev.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? sev.color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              sev.displayName.split(' ').first,
                              style: TextStyle(
                                color: isSelected ? Colors.white : sev.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Incident Title Field
            const Text(
              'Incident Title / Headline',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
              decoration: const InputDecoration(
                hintText: 'e.g., Structure Fire on 3rd Floor',
              ),
            ),

            const SizedBox(height: 20),

            // Incident Location Field
            const Text(
              'Incident Location / Coordinates',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a location' : null,
              decoration: InputDecoration(
                hintText: 'Street address or landmark',
                prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Use Current GPS Location',
                  onPressed: () {
                    _locationController.text = 'Current GPS (37.7749° N, 122.4194° W)';
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Detailed Description Field
            const Text(
              'Situation Description & Notes',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe injuries, hazards, vehicle details, or any immediate dangers...',
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _isSubmitting ? null : _submitReport,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isSubmitting ? 'DISPATCHING...' : 'DISPATCH EMERGENCY REPORT',
                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
            ),

            const SizedBox(height: 16),
            const Center(
              child: Text(
                'False emergency reporting is punishable by law.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
