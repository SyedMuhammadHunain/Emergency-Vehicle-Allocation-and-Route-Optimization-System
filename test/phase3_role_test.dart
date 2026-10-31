import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:resq/core/mock/demo_data.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:resq/core/theme/theme_controller.dart';
import 'package:resq/features/admin/screens/admin_dashboard_screen.dart';
import 'package:resq/features/admin/screens/admin_staff_screen.dart';
import 'package:resq/features/dispatcher/screens/dispatcher_allocation_screen.dart';
import 'package:resq/features/dispatcher/screens/dispatcher_dashboard_screen.dart';
import 'package:resq/features/dispatcher/screens/dispatcher_emergency_screen.dart';
import 'package:resq/features/driver/screens/driver_dashboard_screen.dart';
import 'package:resq/features/driver/screens/driver_mission_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3 - Role-Based Authentication & Repository Tests', () {
    test('Predefined demo accounts authenticate with correct roles', () {
      final repo = MockRepository();

      // Citizen
      final citizen = repo.authenticate('citizen@resq.com', 'Citizen123');
      expect(citizen, isNotNull);
      expect(citizen!.role, equals('citizen'));

      // Dispatcher
      final dispatcher = repo.authenticate('dispatcher@resq.com', 'Dispatch123');
      expect(dispatcher, isNotNull);
      expect(dispatcher!.role, equals('dispatcher'));

      // Driver
      final driver = repo.authenticate('driver@resq.com', 'Driver123');
      expect(driver, isNotNull);
      expect(driver!.role, equals('driver'));

      // Admin
      final admin = repo.authenticate('admin@resq.com', 'Admin123');
      expect(admin, isNotNull);
      expect(admin!.role, equals('admin'));
    });

    test('Invalid credentials return null (strict authentication)', () {
      final repo = MockRepository();
      expect(repo.authenticate('citizen@resq.com', 'WrongPassword'), isNull);
      expect(repo.authenticate('unknown@resq.com', 'Admin123'), isNull);
    });

    test('Admin staff account creation enables new staff authentication', () {
      final repo = MockRepository();

      // Admin creates a new Dispatcher staff account
      final newStaff = repo.createStaffAccount(
        name: 'Kamran Akmal',
        email: 'kamran.dispatch@resq.com',
        password: 'SecurePassword123',
        role: 'dispatcher',
        phone: '+92 300 1122334',
      );

      expect(newStaff.id.startsWith('USR-DIS-'), isTrue);
      expect(newStaff.role, equals('dispatcher'));

      // Verify the new staff can immediately authenticate
      final authenticated = repo.authenticate('kamran.dispatch@resq.com', 'SecurePassword123');
      expect(authenticated, isNotNull);
      expect(authenticated!.name, equals('Kamran Akmal'));
    });

    test('Vehicle assignment updates incident and vehicle statuses reactively', () {
      final repo = MockRepository();
      final pendingEmergency = repo.pendingEmergencies.first;
      final availableVehicle = repo.availableVehicles.first;

      repo.assignVehicleToEmergency(pendingEmergency.id, availableVehicle.id);

      // Emergency status should now be ASSIGNED
      final updatedEmergency = repo.getEmergencyById(pendingEmergency.id);
      expect(updatedEmergency!.status, equals(EmergencyStatus.assigned));
      expect(updatedEmergency.assignedVehicle, isNotNull);
      expect(updatedEmergency.assignedVehicle!.id, equals(availableVehicle.id));

      // Vehicle should now be marked Busy
      final updatedVehicle = repo.vehicles.firstWhere((v) => v.id == availableVehicle.id);
      expect(updatedVehicle.status, equals('Busy'));
      expect(updatedVehicle.assignedEmergencyId, equals(pendingEmergency.id));
    });

    test('Driver mission status progression transitions through valid states to RESOLVED', () {
      final repo = MockRepository();
      final pendingEmergency = repo.pendingEmergencies.first;
      final vehicle = repo.availableVehicles.first;

      // 1. Assign
      repo.assignVehicleToEmergency(pendingEmergency.id, vehicle.id);

      // 2. Driver transitions to EN_ROUTE
      repo.updateMissionStatus(pendingEmergency.id, EmergencyStatus.enRoute);
      expect(repo.getEmergencyById(pendingEmergency.id)!.status, equals(EmergencyStatus.enRoute));

      // 3. Driver arrives ON_SCENE
      repo.updateMissionStatus(pendingEmergency.id, EmergencyStatus.onScene);
      expect(repo.getEmergencyById(pendingEmergency.id)!.status, equals(EmergencyStatus.onScene));

      // 4. Mission Completed -> RESOLVED (vehicle freed)
      repo.updateMissionStatus(pendingEmergency.id, EmergencyStatus.resolved);
      expect(repo.getEmergencyById(pendingEmergency.id)!.status, equals(EmergencyStatus.resolved));

      // Vehicle is freed and available again
      final freedVehicle = repo.vehicles.firstWhere((v) => v.id == vehicle.id);
      expect(freedVehicle.status, equals('Available'));
      expect(freedVehicle.assignedEmergencyId, isNull);
    });
  });

  group('Phase 3 - UI Widget Rendering Tests', () {
    Widget createTestApp(Widget child, {MockRepository? repo, SessionService? session}) {
      final mockRepo = repo ?? MockRepository();
      final mockSession = session ?? SessionService();
      final theme = ThemeController();

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<MockRepository>.value(value: mockRepo),
          ChangeNotifierProvider<SessionService>.value(value: mockSession),
          ChangeNotifierProvider<ThemeController>.value(value: theme),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('Dispatcher Dashboard renders banner, metrics, and incident triage',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = SessionService();
      await session.demoLogin('dispatcher');

      await tester.pumpWidget(createTestApp(
        const DispatcherDashboardScreen(),
        session: session,
      ));
      await tester.pumpAndSettle();

      expect(find.text('DISPATCH CONTROL · KARACHI SECTOR'), findsOneWidget);
      expect(find.text('Total Emergencies'), findsOneWidget);
      expect(find.text('Pending Triage'), findsOneWidget);
    });

    testWidgets('Dispatcher Emergency Queue renders filter chips and incident cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const DispatcherEmergencyScreen()));
      await tester.pumpAndSettle();

      expect(find.text('REPORTED'), findsWidgets);
      expect(find.text('MEDICAL'), findsWidgets);
    });

    testWidgets('Dispatcher Allocation Assistant renders DP recommendation banner',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const DispatcherAllocationScreen()));
      await tester.pumpAndSettle();

      expect(find.text('DYNAMIC PROGRAMMING (DP) ALLOCATION ASSISTANT'), findsOneWidget);
      expect(find.text('Simulated Optimization Engine'), findsOneWidget);
    });

    testWidgets('Driver Dashboard renders responder banner and duty status toggle',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = SessionService();
      await session.demoLogin('driver');

      await tester.pumpWidget(createTestApp(
        const DriverDashboardScreen(),
        session: session,
      ));
      await tester.pumpAndSettle();

      expect(find.text('FIELD RESPONDER · DEMO DRIVER'), findsOneWidget);
      expect(find.text('STATUS: ON DUTY'), findsOneWidget);
    });

    testWidgets('Driver Mission Screen renders progression timeline and controls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = SessionService();
      await session.demoLogin('driver');

      await tester.pumpWidget(createTestApp(
        const DriverMissionScreen(),
        session: session,
      ));
      await tester.pumpAndSettle();

      // Either active mission or empty standby state renders cleanly without exception
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Admin Dashboard renders executive telemetry and module navigation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = SessionService();
      await session.demoLogin('admin');

      await tester.pumpWidget(createTestApp(
        const AdminDashboardScreen(),
        session: session,
      ));
      await tester.pumpAndSettle();

      expect(find.text('SYSTEM ADMINISTRATION · MASTER CONTROL'), findsOneWidget);
      expect(find.text('Staff Management'), findsOneWidget);
      expect(find.text('Fleet Management'), findsOneWidget);
    });

    testWidgets('Admin Staff Management renders staff list and provision button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const AdminStaffScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Provision Staff'), findsOneWidget);
      expect(find.text('DISPATCHER'), findsWidgets);
      expect(find.text('DRIVER'), findsWidgets);
    });
  });
}
