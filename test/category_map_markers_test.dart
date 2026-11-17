import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:resq/core/mock/demo_data.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:resq/core/theme/theme_controller.dart';
import 'package:resq/features/citizen/screens/report_emergency_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestApp(Widget child, {MockRepository? repo}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
      ChangeNotifierProvider<SessionService>(create: (_) => SessionService()),
      ChangeNotifierProvider<MockRepository>(create: (_) => repo ?? MockRepository()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Task 1: MockRepository getEmergenciesByCategory tests', () {
    test('filters emergencies correctly by category', () {
      final repo = MockRepository();

      final medicalEmergencies = repo.getEmergenciesByCategory(EmergencyCategory.medical);
      expect(medicalEmergencies.isNotEmpty, isTrue);
      expect(medicalEmergencies.every((e) => e.category == EmergencyCategory.medical), isTrue);

      final fireEmergencies = repo.getEmergenciesByCategory(EmergencyCategory.fire);
      expect(fireEmergencies.every((e) => e.category == EmergencyCategory.fire), isTrue);

      final accidentEmergencies = repo.getEmergenciesByCategory(EmergencyCategory.accident);
      expect(accidentEmergencies.every((e) => e.category == EmergencyCategory.accident), isTrue);

      final rescueEmergencies = repo.getEmergenciesByCategory(EmergencyCategory.rescue);
      expect(rescueEmergencies.every((e) => e.category == EmergencyCategory.rescue), isTrue);

      // Case insensitivity test
      final lowercaseMedical = repo.getEmergenciesByCategory('medical');
      expect(lowercaseMedical.length, equals(medicalEmergencies.length));

      // Non-existent category
      final nonExistent = repo.getEmergenciesByCategory('UNKNOWN_CATEGORY');
      expect(nonExistent.isEmpty, isTrue);
    });
  });

  group('Task 2: ReportEmergencyScreen Category Map Markers tests', () {
    testWidgets('Map updates markers when Fire Hazard, Road Accident, Rescue / Other selected', (tester) async {
      final repo = MockRepository();

      // Ensure we have at least one emergency of each category
      repo.reportEmergency(
        category: EmergencyCategory.fire,
        severity: 4,
        urgency: 4,
        peopleAffected: 2,
        description: 'Fire in industrial zone',
        location: const LatLng(24.8500, 67.0100),
        locationLabel: 'Site Area',
        userId: 'USR-TEST-01',
      );

      repo.reportEmergency(
        category: EmergencyCategory.accident,
        severity: 3,
        urgency: 3,
        peopleAffected: 1,
        description: 'Road accident on highway',
        location: const LatLng(24.8700, 67.0300),
        locationLabel: 'Shahrah-e-Faisal',
        userId: 'USR-TEST-01',
      );

      repo.reportEmergency(
        category: EmergencyCategory.rescue,
        severity: 4,
        urgency: 4,
        peopleAffected: 3,
        description: 'Rescue operation needed',
        location: const LatLng(24.8900, 67.0500),
        locationLabel: 'Gulshan',
        userId: 'USR-TEST-01',
      );

      await tester.pumpWidget(createTestApp(const ReportEmergencyScreen(), repo: repo));
      await tester.pumpAndSettle();

      // Helper to count markers in MarkerLayer
      int countMarkers() {
        final markerLayerFinder = find.byType(MarkerLayer);
        expect(markerLayerFinder, findsOneWidget);
        final markerLayer = tester.widget<MarkerLayer>(markerLayerFinder);
        return markerLayer.markers.length;
      }

      // Initial category is Medical (widget default)
      final initialMedicalCount = repo.getEmergenciesByCategory(EmergencyCategory.medical).length;
      // 1 user pin + medical markers
      expect(countMarkers(), equals(initialMedicalCount + 1));

      // Select Fire Hazard
      await tester.tap(find.text('Fire Hazard'));
      await tester.pumpAndSettle();

      final fireCount = repo.getEmergenciesByCategory(EmergencyCategory.fire).length;
      expect(fireCount, greaterThan(0));
      expect(countMarkers(), equals(fireCount + 1));
      expect(find.textContaining('fire active'), findsOneWidget);

      // Select Road Accident
      await tester.tap(find.text('Road Accident'));
      await tester.pumpAndSettle();

      final accidentCount = repo.getEmergenciesByCategory(EmergencyCategory.accident).length;
      expect(accidentCount, greaterThan(0));
      expect(countMarkers(), equals(accidentCount + 1));
      expect(find.textContaining('accident active'), findsOneWidget);

      // Select Rescue / Other
      await tester.tap(find.text('Rescue / Other'));
      await tester.pumpAndSettle();

      final rescueCount = repo.getEmergenciesByCategory(EmergencyCategory.rescue).length;
      expect(rescueCount, greaterThan(0));
      expect(countMarkers(), equals(rescueCount + 1));
      expect(find.textContaining('rescue active'), findsOneWidget);
    });
  });
}
