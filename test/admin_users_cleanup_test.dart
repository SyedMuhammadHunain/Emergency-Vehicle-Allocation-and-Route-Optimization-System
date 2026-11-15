import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:resq/core/theme/theme_controller.dart';
import 'package:resq/features/admin/screens/admin_staff_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestWidget(MockRepository repo) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MockRepository>.value(value: repo),
      ChangeNotifierProvider<SessionService>(
        create: (_) => SessionService(),
      ),
      ChangeNotifierProvider<ThemeController>(
        create: (_) => ThemeController(),
      ),
    ],
    child: const MaterialApp(
      home: AdminStaffScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Requirement 10 & 11: Admin Staff & Users Cleanup Tests', () {
    testWidgets('Demo Citizen does not appear in Admin Staff/Users screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockRepository();

      await tester.pumpWidget(createTestWidget(repo));
      await tester.pumpAndSettle();

      // Verify Demo Citizen and its email are absent
      expect(find.text('Demo Citizen'), findsNothing);
      expect(find.text('citizen@resq.com'), findsNothing);
      expect(find.text('USR-CIT-001'), findsNothing);

      // Verify legitimate staff are present
      expect(find.text('Karachi Central Dispatcher'), findsOneWidget);
      expect(find.text('Captain Tariq (Ambulance Unit 1)'), findsOneWidget);
      expect(find.text('System Administrator'), findsOneWidget);

      // Verify Citizen count in chip is 0 before any registration
      expect(find.text('CITIZEN (0)'), findsOneWidget);
    });

    testWidgets('Newly registered citizen appears dynamically in Admin list', (
      tester,
    ) async {
      final repo = MockRepository();

      await tester.pumpWidget(createTestWidget(repo));
      await tester.pumpAndSettle();

      expect(find.text('CITIZEN (0)'), findsOneWidget);

      // Register a real citizen
      repo.registerCitizen(
        name: 'Zainab Ahmed',
        email: 'zainab.ahmed@example.pk',
        password: 'Password123',
        phone: '03001234567',
      );

      await tester.pumpAndSettle();

      // Citizen count chip should now show 1
      expect(find.text('CITIZEN (1)'), findsOneWidget);

      // Filter by Citizen
      await tester.tap(find.text('CITIZEN (1)'));
      await tester.pumpAndSettle();

      // Zainab should now be visible in the list
      expect(find.text('Zainab Ahmed'), findsOneWidget);
      expect(find.text('zainab.ahmed@example.pk'), findsOneWidget);
      expect(find.text('Phone: 03001234567'), findsOneWidget);
    });

    testWidgets(
      'Admin can provision Driver who appears in list and can authenticate',
      (tester) async {
        final repo = MockRepository();

        await tester.pumpWidget(createTestWidget(repo));
        await tester.pumpAndSettle();

        // Tap "Provision Staff" FAB
        await tester.tap(find.text('Provision Staff'));
        await tester.pumpAndSettle();

        // Enter details in dialog
        // Select Driver role
        await tester.tap(find.text('Dispatcher (Control Room)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Driver (Field Responder)').last);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'e.g. Asad Siddiqui'),
          'Bilal Driver',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'e.g. asad@resq.com'),
          'bilal.driver@resq.pk',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, '+92 300 9876543'),
          '03129876543',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Initial Password'),
          'DriverPass123',
        );

        // Tap "Provision Account"
        await tester.tap(find.text('Provision Account'));
        await tester.pumpAndSettle();

        // Verify Driver appears in Staff list
        expect(find.text('Bilal Driver'), findsOneWidget);
        expect(find.text('bilal.driver@resq.pk'), findsOneWidget);

        // Verify newly created driver can authenticate directly
        final authResult = repo.authenticate(
          'bilal.driver@resq.pk',
          'DriverPass123',
        );
        expect(authResult, isNotNull);
        expect(authResult!.role, 'driver');
        expect(authResult.name, 'Bilal Driver');
      },
    );
  });
}
