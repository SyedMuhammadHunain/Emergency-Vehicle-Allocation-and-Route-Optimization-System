import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:resq/core/mock/demo_data.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:resq/core/theme/theme_controller.dart';
import 'package:resq/core/widgets/map/map_zoom_controls.dart';
import 'package:resq/features/citizen/screens/emergency_detail_screen.dart';
import 'package:resq/features/citizen/screens/live_tracking_screen.dart';
import 'package:resq/features/citizen/screens/report_emergency_screen.dart';
import 'package:resq/features/dispatcher/screens/dispatcher_map_screen.dart';
import 'package:resq/features/driver/screens/driver_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestApp(
  Widget child, {
  SessionService? session,
  MockRepository? repo,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
      ChangeNotifierProvider<SessionService>(
        create: (_) => session ?? SessionService(),
      ),
      ChangeNotifierProvider<MockRepository>(
        create: (_) => repo ?? MockRepository(),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Task 8 - Citizen Live Tracking Map Tests', () {
    testWidgets(
      'Displays Awaiting Dispatcher Assignment state when vehicle is unassigned without fake routes',
      (WidgetTester tester) async {
        final repo = MockRepository();
        final unassignedEmergency = DemoEmergency(
          id: 'EM-TEST-UNASSIGNED',
          category: EmergencyCategory.medical,
          status: EmergencyStatus.reported,
          severity: 3,
          urgency: 4,
          peopleAffected: 1,
          description: 'Emergency awaiting vehicle dispatch.',
          location: const LatLng(24.8607, 67.0011),
          locationLabel: 'Gulshan Block 5, Karachi',
          reportedAt: DateTime.now(),
          reportedByUserId: 'USR-CIT-01',
          assignedVehicle: null,
        );
        repo.addEmergency(unassignedEmergency);

        await tester.pumpWidget(
          createTestApp(
            const LiveTrackingScreen(emergencyId: 'EM-TEST-UNASSIGNED'),
            repo: repo,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Shows "Awaiting Dispatcher Assignment" in banner and card
        expect(
          find.text(
            'Awaiting Dispatcher Assignment · Vehicle tracking activates once dispatched.',
          ),
          findsOneWidget,
        );
        expect(find.text('Awaiting Dispatcher Assignment'), findsOneWidget);

        // 2. Map rendered
        expect(find.byType(FlutterMap), findsOneWidget);

        // 3. No fake vehicle route polylines
        expect(find.byType(PolylineLayer), findsNothing);

        // 4. Has Zoom controls
        expect(find.byType(MapZoomControls), findsOneWidget);
      },
    );

    testWidgets(
      'Displays assigned vehicle and route when responder is assigned',
      (WidgetTester tester) async {
        final repo = MockRepository();
        final vehicle = DemoVehicle(
          id: 'VH-AMB-01',
          licensePlate: 'KHI-9988',
          type: 'Ambulance',
          status: 'En Route',
          location: const LatLng(24.8700, 67.0200),
          driverName: 'Rashid Khan',
        );

        final assignedEmergency = DemoEmergency(
          id: 'EM-TEST-ASSIGNED',
          category: EmergencyCategory.fire,
          status: EmergencyStatus.enRoute,
          severity: 5,
          urgency: 5,
          peopleAffected: 3,
          description: 'Fire incident with ambulance dispatched.',
          location: const LatLng(24.8607, 67.0011),
          locationLabel: 'Karachi Central',
          reportedAt: DateTime.now(),
          reportedByUserId: 'USR-CIT-02',
          assignedVehicle: vehicle,
        );
        repo.addEmergency(assignedEmergency);

        await tester.pumpWidget(
          createTestApp(
            const LiveTrackingScreen(emergencyId: 'EM-TEST-ASSIGNED'),
            repo: repo,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Shows assigned vehicle details
        expect(find.text('KHI-9988'), findsOneWidget);
        expect(find.text('Ambulance'), findsOneWidget);
        expect(find.text('Rashid Khan · En Route'), findsOneWidget);

        // 2. Shows polyline route for assigned vehicle
        expect(find.byType(PolylineLayer), findsOneWidget);

        // 3. Has Zoom controls
        expect(find.byType(MapZoomControls), findsOneWidget);
      },
    );

    testWidgets(
      'Handles non-existent emergency ID gracefully with unavailable state',
      (WidgetTester tester) async {
        final repo = MockRepository();

        await tester.pumpWidget(
          createTestApp(
            const LiveTrackingScreen(emergencyId: 'EM-NON-EXISTENT'),
            repo: repo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Emergency Not Found'), findsOneWidget);
        expect(find.text('Back to Reports'), findsOneWidget);
      },
    );
  });

  group('Task 9 - Universal Map Zoom Controls Tests Across All Maps', () {
    testWidgets(
      'MapZoomControls zoom in and zoom out functions on controller',
      (WidgetTester tester) async {
        final mapController = MapController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: const MapOptions(
                      initialCenter: LatLng(24.8607, 67.0011),
                      initialZoom: 12.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                    ],
                  ),
                  MapZoomControls(mapController: mapController),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MapZoomControls), findsOneWidget);
        expect(mapController.camera.zoom, equals(12.0));

        // Tap Zoom In (+)
        final zoomInBtn = find.byIcon(Icons.add_rounded);
        expect(zoomInBtn, findsOneWidget);
        await tester.tap(zoomInBtn);
        await tester.pumpAndSettle();

        expect(mapController.camera.zoom, equals(13.0));

        // Tap Zoom Out (-)
        final zoomOutBtn = find.byIcon(Icons.remove_rounded);
        expect(zoomOutBtn, findsOneWidget);
        await tester.tap(zoomOutBtn);
        await tester.pumpAndSettle();

        expect(mapController.camera.zoom, equals(12.0));
      },
    );

    testWidgets(
      'EmergencyDetailScreen renders map with working MapZoomControls',
      (WidgetTester tester) async {
        final repo = MockRepository();
        final firstId = repo.emergencies.first.id;

        await tester.pumpWidget(
          createTestApp(
            EmergencyDetailScreen(emergencyId: firstId),
            repo: repo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MapZoomControls), findsOneWidget);
      },
    );

    testWidgets(
      'ReportEmergencyScreen renders map with working MapZoomControls',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(const ReportEmergencyScreen(isStandalone: false)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MapZoomControls), findsOneWidget);
      },
    );

    testWidgets(
      'DispatcherMapScreen renders map with working MapZoomControls',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(const DispatcherMapScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(MapZoomControls), findsOneWidget);
      },
    );

    testWidgets(
      'DriverNavigationScreen renders map with working MapZoomControls',
      (WidgetTester tester) async {
        final session = SessionService();
        final repo = MockRepository();
        // Give driver a vehicle and mission
        await session.loginAsRegisteredCitizen(
          DemoUserAccount(
            id: 'USR-DRV-001',
            name: 'Driver Test',
            email: 'driver@resq.pk',
            phone: '03001234567',
            role: 'driver',
            password: 'Password123!',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        await tester.pumpWidget(
          createTestApp(
            const DriverNavigationScreen(),
            session: session,
            repo: repo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MapZoomControls), findsOneWidget);
      },
    );
  });
}
