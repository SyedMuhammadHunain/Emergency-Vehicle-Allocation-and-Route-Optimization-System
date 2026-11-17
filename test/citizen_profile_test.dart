import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:resq/core/mock/demo_data.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:resq/core/theme/theme_controller.dart';
import 'package:resq/features/citizen/screens/citizen_profile_screen.dart';
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

  group('Task 4 - Citizen Profile Data & Medical Empty State Tests', () {
    testWidgets(
      'Profile displays actual session name, email, and Pakistani contact number',
      (WidgetTester tester) async {
        final session = SessionService();
        await session.loginAsRegisteredCitizen(
          DemoUserAccount(
            id: 'USR-CIT-999',
            name: 'Ahmed Tariq',
            email: 'citizen.test@resq.pk',
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

        expect(find.text('Ahmed Tariq'), findsOneWidget);
        expect(find.text('citizen.test@resq.pk · 03001234567'), findsOneWidget);
        expect(find.text('REGISTERED CITIZEN'), findsOneWidget);
      },
    );

    testWidgets(
      'Initial profile has empty/unspecified medical and emergency contact details',
      (WidgetTester tester) async {
        final session = SessionService();
        await session.loginAsRegisteredCitizen(
          DemoUserAccount(
            id: 'USR-CIT-NEW',
            name: 'New Citizen',
            email: 'newuser@resq.pk',
            phone: '03129876543',
            role: 'citizen',
            password: 'Password123!',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        await tester.pumpWidget(
          createTestApp(const CitizenProfileScreen(), session: session),
        );
        await tester.pumpAndSettle();

        // Must NOT contain hardcoded demo data like "O+ (Positive)", "Fatima Khan", "Penicillin, Dust"
        expect(find.text('O+ (Positive)'), findsNothing);
        expect(find.text('Fatima Khan (+92 321 9876543)'), findsNothing);
        expect(find.text('Penicillin, Dust'), findsNothing);

        // Must show empty/default placeholders
        expect(
          find.text('Not specified'),
          findsNWidgets(2),
        ); // Blood Group & Preferred Hospital
        expect(find.text('None recorded'), findsOneWidget); // Allergies
        expect(
          find.text('No emergency contact entered'),
          findsOneWidget,
        ); // Next of Kin
      },
    );

    testWidgets(
      'Citizen can edit and save medical details, and saved details persist in repository',
      (WidgetTester tester) async {
        final session = SessionService();
        final repo = MockRepository();
        await session.loginAsRegisteredCitizen(
          DemoUserAccount(
            id: 'USR-CIT-EDIT',
            name: 'Edit User',
            email: 'edituser@resq.pk',
            phone: '03335551234',
            role: 'citizen',
            password: 'Password123!',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        await tester.pumpWidget(
          createTestApp(
            const CitizenProfileScreen(),
            session: session,
            repo: repo,
          ),
        );
        await tester.pumpAndSettle();

        // Tap Edit Details button
        final editButton = find.text('Edit Details');
        expect(editButton, findsOneWidget);
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // Modal should be open
        expect(find.text('Edit Medical Details'), findsOneWidget);

        // Select Blood Group 'B+'
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('B+').last);
        await tester.pumpAndSettle();

        // Enter allergies
        final textFields = find.byType(TextFormField);
        // Form has 4 text fields: allergies (text), contact name (text), contact phone (text), hospital (text)
        await tester.enterText(textFields.at(0), 'Peanuts, Aspirin');
        await tester.enterText(textFields.at(1), 'Bilal Khan');
        await tester.enterText(textFields.at(2), '03009988776');
        await tester.enterText(textFields.at(3), 'Indus Hospital, Karachi');

        // Save
        await tester.tap(find.text('Save Details'));
        await tester.pumpAndSettle();

        // Verify updated values displayed in UI
        expect(find.text('B+'), findsOneWidget);
        expect(find.text('Peanuts, Aspirin'), findsOneWidget);
        expect(find.text('Bilal Khan (03009988776)'), findsOneWidget);
        expect(find.text('Indus Hospital, Karachi'), findsOneWidget);

        // Verify repository received the update
        final saved = repo.getProfileForUser('USR-CIT-EDIT');
        expect(saved.bloodType, equals('B+'));
        expect(saved.allergies, contains('Peanuts'));
        expect(saved.allergies, contains('Aspirin'));
        expect(saved.preferredHospital, equals('Indus Hospital, Karachi'));
        expect(saved.emergencyContacts.first.name, equals('Bilal Khan'));
        expect(
          saved.emergencyContacts.first.phoneNumber,
          equals('03009988776'),
        );
      },
    );
  });
}
