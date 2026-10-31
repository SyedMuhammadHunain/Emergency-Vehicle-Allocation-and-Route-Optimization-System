import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:resq/core/mock/demo_data.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:resq/core/theme/theme_controller.dart';
import 'package:resq/features/citizen/screens/citizen_home_screen.dart';
import 'package:resq/features/citizen/screens/citizen_profile_screen.dart';
import 'package:resq/features/citizen/screens/emergency_detail_screen.dart';
import 'package:resq/features/citizen/screens/my_reports_screen.dart';
import 'package:resq/features/citizen/screens/report_emergency_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Citizen Module - MockRepository Tests', () {
    test('MockRepository seeds emergencies and notifications', () {
      final repo = MockRepository();
      expect(repo.emergencies.length, greaterThanOrEqualTo(3));
      expect(repo.notifications.length, greaterThanOrEqualTo(3));
      expect(repo.vehicles.length, greaterThanOrEqualTo(4));
      expect(repo.activeEmergencies.isNotEmpty, isTrue);
    });

    test('MockRepository reportEmergency adds incident and creates notification', () {
      final repo = MockRepository();
      final initialCount = repo.emergencies.length;
      final initialNotifs = repo.notifications.length;

      final emergency = repo.reportEmergency(
        category: EmergencyCategory.fire,
        severity: 5,
        urgency: 4,
        peopleAffected: 3,
        description: 'Test fire incident in Karachi',
        location: const LatLng(24.8607, 67.0011),
        locationLabel: 'Saddar, Karachi',
        userId: 'Demo Citizen',
      );

      expect(repo.emergencies.length, equals(initialCount + 1));
      expect(repo.notifications.length, equals(initialNotifs + 1));
      expect(emergency.id.startsWith('EM-2026-'), isTrue);
      expect(emergency.category, equals(EmergencyCategory.fire));
      expect(emergency.status, equals(EmergencyStatus.reported));
    });

    test('MockRepository status update and notification read', () {
      final repo = MockRepository();
      final target = repo.emergencies.first;
      repo.updateEmergencyStatus(target.id, EmergencyStatus.resolved);
      expect(target.status, equals(EmergencyStatus.resolved));

      expect(repo.unreadCount, greaterThan(0));
      repo.markAllNotificationsRead();
      expect(repo.unreadCount, equals(0));
    });
  });

  group('Citizen Module - UI Widget Tests', () {
    Widget createTestApp(Widget child, {MockRepository? repo, SessionService? session, ThemeController? theme}) {
      final mockRepo = repo ?? MockRepository();
      final sessionService = session ?? SessionService();
      final themeController = theme ?? ThemeController();

      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: mockRepo),
          ChangeNotifierProvider.value(value: sessionService),
          ChangeNotifierProvider.value(value: themeController),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('CitizenHomeScreen renders welcome, CTA, categories, and hotlines',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const CitizenHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('REPORT EMERGENCY NOW'), findsOneWidget);
      expect(find.text('Quick Report by Category'), findsOneWidget);
      expect(find.text('Medical'), findsOneWidget);
      expect(find.text('Fire'), findsOneWidget);
      expect(find.text('Accident'), findsOneWidget);
      expect(find.text('Rescue'), findsOneWidget);
      expect(find.text('Emergency Hotlines (Karachi)'), findsOneWidget);
      expect(find.text('1122'), findsOneWidget);
    });

    testWidgets('MyReportsScreen displays reports and filter chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const MyReportsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Incident Reports'), findsOneWidget);
      expect(find.textContaining('All Reports'), findsOneWidget);
      expect(find.textContaining('Active'), findsOneWidget);
      expect(find.textContaining('Resolved'), findsOneWidget);
    });

    testWidgets('ReportEmergencyScreen renders form and map components',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const ReportEmergencyScreen()));
      await tester.pumpAndSettle();

      expect(find.text('1. Select Emergency Type'), findsOneWidget);
      expect(find.text('2. Incident Location'), findsOneWidget);
      expect(find.text('3. Severity & Impact Details'), findsOneWidget);
      expect(find.text('SUBMIT EMERGENCY REPORT'), findsOneWidget);
      expect(find.text('Use My GPS'), findsOneWidget);
    });

    testWidgets('EmergencyDetailScreen displays status timeline and metrics',
        (WidgetTester tester) async {
      final repo = MockRepository();
      final firstId = repo.emergencies.first.id;

      await tester.pumpWidget(createTestApp(
        EmergencyDetailScreen(emergencyId: firstId),
        repo: repo,
      ));
      await tester.pumpAndSettle();

      expect(find.text(firstId), findsWidgets);
      expect(find.text('Dispatch Progress Timeline'), findsOneWidget);
      expect(find.text('Severity Level'), findsOneWidget);
      expect(find.text('DEMO STATE SIMULATOR'), findsOneWidget);
    });

    testWidgets('CitizenProfileScreen displays verified citizen badge and medical ID',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const CitizenProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('VERIFIED CITIZEN (DEMO)'), findsOneWidget);
      expect(find.text('Medical ID & Emergency Contacts'), findsOneWidget);
      expect(find.text('Blood Group'), findsOneWidget);
      expect(find.text('Appearance Theme'), findsOneWidget);
      expect(find.text('Sign Out of ResQ'), findsOneWidget);
    });
  });
}
