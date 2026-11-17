import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:resq/core/mock/demo_data.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:resq/core/theme/theme_controller.dart';
import 'package:resq/features/citizen/screens/my_reports_screen.dart';
import 'package:resq/features/citizen/screens/report_emergency_screen.dart';
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

  group('Task 7 - Citizen Emergency Submission & Scoped My Reports Tests', () {
    testWidgets(
      'New citizen starts with empty My Reports without unrelated demo emergencies',
      (WidgetTester tester) async {
        final session = SessionService();
        final repo = MockRepository();

        await session.loginAsRegisteredCitizen(
          DemoUserAccount(
            id: 'USR-CIT-EMPTY',
            name: 'Empty Citizen',
            email: 'empty@resq.pk',
            phone: '03001112233',
            role: 'citizen',
            password: 'Password123!',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        await tester.pumpWidget(
          createTestApp(const MyReportsScreen(), session: session, repo: repo),
        );
        await tester.pumpAndSettle();

        // Must show empty state
        expect(find.text('No reports found'), findsOneWidget);
        expect(find.text('0 reports'), findsOneWidget);
        // Must NOT show seed emergencies from demo citizen (USR-CIT-001)
        expect(find.text('EM-2026-0001'), findsNothing);
        expect(find.text('EM-2026-0002'), findsNothing);
      },
    );

    testWidgets(
      'Reported emergency is saved with citizen ID and appears in My Reports',
      (WidgetTester tester) async {
        final session = SessionService();
        final repo = MockRepository();

        const citizenId = 'USR-CIT-ACTIVE-01';
        const citizenEmail = 'active.citizen@resq.pk';

        await session.loginAsRegisteredCitizen(
          DemoUserAccount(
            id: citizenId,
            name: 'Active Citizen',
            email: citizenEmail,
            phone: '03123456789',
            role: 'citizen',
            password: 'Password123!',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        // Directly report an emergency for this citizen via MockRepository/ApiService
        final created = repo.reportEmergency(
          category: EmergencyCategory.medical,
          severity: 4,
          urgency: 5,
          peopleAffected: 1,
          description: 'Asthma attack near Clifton Karachi.',
          location: const LatLng(24.8138, 67.0299),
          locationLabel: 'Clifton Block 2, Karachi',
          userId: citizenId,
        );

        expect(created.reportedByUserId, equals(citizenId));

        // Open MyReportsScreen
        await tester.pumpWidget(
          createTestApp(const MyReportsScreen(), session: session, repo: repo),
        );
        await tester.pumpAndSettle();

        // Must display this citizen's emergency report
        expect(find.text(created.id), findsOneWidget);
        expect(find.text(EmergencyCategory.medical), findsOneWidget);
        expect(
          find.text('Asthma attack near Clifton Karachi.'),
          findsOneWidget,
        );
        expect(find.text('Clifton Block 2, Karachi'), findsOneWidget);
        expect(find.text('1 reports'), findsOneWidget);

        // Other unrelated emergencies still must NOT appear
        expect(find.text('EM-2026-0001'), findsNothing);
      },
    );

    testWidgets(
      'Full reporting flow: Citizen submits emergency on ReportEmergencyScreen -> appears in MyReportsScreen',
      (WidgetTester tester) async {
        final session = SessionService();
        final repo = MockRepository();

        const citizenId = 'USR-CIT-FLOW';
        await session.loginAsRegisteredCitizen(
          DemoUserAccount(
            id: citizenId,
            name: 'Flow Citizen',
            email: 'flow@resq.pk',
            phone: '03451122334',
            role: 'citizen',
            password: 'Password123!',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        // 1. Render ReportEmergencyScreen
        await tester.pumpWidget(
          createTestApp(
            const ReportEmergencyScreen(isStandalone: false),
            session: session,
            repo: repo,
          ),
        );
        await tester.pumpAndSettle();

        // Fill in Description
        final textFields = find.byType(TextFormField);
        // TextFormField: 0 is address, 1 is description
        await tester.enterText(
          textFields.last,
          'Severe traffic accident near Saddar Karachi.',
        );

        // Scroll down to submit button
        final submitBtn = find.text('SUBMIT EMERGENCY REPORT');
        await tester.scrollUntilVisible(
          submitBtn,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(submitBtn, findsOneWidget);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Dialog should appear
        expect(find.text('Report Dispatched!'), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('Track Status'));
        await tester.pumpAndSettle();

        // 2. Open MyReportsScreen and verify the newly reported emergency is visible
        await tester.pumpWidget(
          createTestApp(const MyReportsScreen(), session: session, repo: repo),
        );
        await tester.pumpAndSettle();

        expect(find.text('1 reports'), findsOneWidget);
        expect(
          find.text('Severe traffic accident near Saddar Karachi.'),
          findsOneWidget,
        );
      },
    );
  });
}
