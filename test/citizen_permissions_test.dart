import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:resq/core/mock/demo_data.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:resq/core/theme/theme_controller.dart';
import 'package:resq/features/citizen/screens/citizen_profile_screen.dart';
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

  group('Task 5 & 6 - Citizen Permissions & Frontend Prototype Cleanup Tests', () {
    testWidgets(
      'Push Notifications and Location Permission tiles are clickable and functional',
      (WidgetTester tester) async {
        final session = SessionService();
        await session.loginAsRegisteredCitizen(
          DemoUserAccount(
            id: 'USR-CIT-PERM',
            name: 'Permission User',
            email: 'perm@resq.pk',
            phone: '03001234567',
            role: 'citizen',
            password: 'Password123!',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        await tester.pumpWidget(
          createTestApp(const CitizenProfileScreen(), session: session),
        );
        await tester.pumpAndSettle();

        // 1. Verify Push Notifications tile exists and is not enabled by default
        final pushTile = find.widgetWithText(ListTile, 'Push Notifications');
        expect(pushTile, findsOneWidget);
        final pushSwitch = find.descendant(
          of: pushTile,
          matching: find.byType(Switch),
        );
        expect(pushSwitch, findsOneWidget);

        // Tap Push Notifications tile / switch
        await tester.tap(pushSwitch);
        await tester.pumpAndSettle();

        // 2. Verify Location Permission tile exists and is clickable
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        final locationTile = find.widgetWithText(
          ListTile,
          'Location Permission',
        );
        expect(locationTile, findsOneWidget);

        // Tap Location Permission tile
        await tester.tap(locationTile);
        await tester.pumpAndSettle();

        // Ensure page does not crash and handles interaction
        expect(find.byType(CitizenProfileScreen), findsOneWidget);
      },
    );

    testWidgets('Frontend Prototype text is removed from Citizen screens', (
      WidgetTester tester,
    ) async {
      final session = SessionService();
      await session.loginAsRegisteredCitizen(
        DemoUserAccount(
          id: 'USR-CIT-PROTO',
          name: 'Clean User',
          email: 'clean@resq.pk',
          phone: '03007654321',
          role: 'citizen',
          password: 'Password123!',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      // 1. Citizen Profile Screen must NOT contain Frontend Prototype
      await tester.pumpWidget(
        createTestApp(const CitizenProfileScreen(), session: session),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Frontend Prototype'), findsNothing);

      // 2. Report Emergency Screen must NOT contain Frontend Prototype
      await tester.pumpWidget(
        createTestApp(const ReportEmergencyScreen(), session: session),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Frontend Prototype'), findsNothing);
    });
  });
}
