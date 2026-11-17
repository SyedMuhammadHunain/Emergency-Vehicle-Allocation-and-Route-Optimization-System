import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:resq/features/auth/screens/register_screen.dart';

void main() {
  group('Task 1 - Pakistani Contact Number Format & Validation Tests', () {
    late MockRepository mockRepo;
    late SessionService sessionService;

    setUp(() {
      mockRepo = MockRepository();
      sessionService = SessionService();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<MockRepository>.value(value: mockRepo),
          ChangeNotifierProvider<SessionService>.value(value: sessionService),
        ],
        child: const MaterialApp(home: RegisterScreen()),
      );
    }

    testWidgets(
      'RegisterScreen shows 03XXXXXXXXX hint and format explanation',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('03XXXXXXXXX'), findsOneWidget);
        expect(
          find.text('Expected format: 03XXXXXXXXX (11 digits, digits only)'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Rejects contact numbers that do not start with 03', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g., Ali Khan'),
        'Tariq Mehmood',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g., ali@mail.com'),
        'tariq@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '03XXXXXXXXX'),
        '04212345678',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a secure password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'password123',
      );

      final submitBtn = find.widgetWithText(InkWell, 'Create Account');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Must start with 03 (e.g., 03001234567)'),
        findsOneWidget,
      );
      // Verify account was NOT created
      expect(
        mockRepo.accounts.any((a) => a.email == 'tariq@test.com'),
        isFalse,
      );
    });

    testWidgets('Rejects contact numbers with fewer than 11 digits', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g., Ali Khan'),
        'Tariq Mehmood',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g., ali@mail.com'),
        'tariq@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '03XXXXXXXXX'),
        '030012345',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a secure password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'password123',
      );

      final submitBtn = find.widgetWithText(InkWell, 'Create Account');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Must be exactly 11 digits (e.g., 03001234567)'),
        findsOneWidget,
      );
      expect(
        mockRepo.accounts.any((a) => a.email == 'tariq@test.com'),
        isFalse,
      );
    });

    testWidgets(
      'Accepts valid 03XXXXXXXXX number and saves account with correct phone',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'e.g., Ali Khan'),
          'Zubair Ahmed',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'e.g., ali@mail.com'),
          'zubair@resq.pk',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, '03XXXXXXXXX'),
          '03331234567',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Create a secure password'),
          'pass123456',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Re-enter your password'),
          'pass123456',
        );

        final submitBtn = find.widgetWithText(InkWell, 'Create Account');
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pump(); // Start async action

        // Check account saved in repository
        final created = mockRepo.accounts.firstWhere(
          (a) => a.email == 'zubair@resq.pk',
        );
        expect(created.name, equals('Zubair Ahmed'));
        expect(created.phone, equals('03331234567'));
        expect(created.role, equals('citizen'));

        // Usable for authentication
        final authResult = mockRepo.authenticate(
          'zubair@resq.pk',
          'pass123456',
        );
        expect(authResult, isNotNull);
        expect(authResult!.phone, equals('03331234567'));
      },
    );
  });
}
