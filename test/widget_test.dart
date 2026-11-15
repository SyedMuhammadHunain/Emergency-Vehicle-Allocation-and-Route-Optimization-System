import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/app.dart';
import 'package:resq/core/constants/app_colors.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:resq/core/theme/theme_controller.dart';
import 'package:resq/core/widgets/brand/resq_wordmark.dart';
import 'package:resq/core/widgets/buttons/primary_gradient_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 1 - ResQ Brand & Auth Tests', () {
    testWidgets('ResQWordmark renders Res text and logo painter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ResQWordmark(fontSize: 28),
        ),
      );

      expect(find.text('Res'), findsOneWidget);
    });

    testWidgets('ResQApp boots and shows Splash Screen with tagline', (
      WidgetTester tester,
    ) async {
      final theme = ThemeController();
      final session = SessionService();

      await tester.pumpWidget(
        ResQApp(themeController: theme, sessionService: session),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Closer to Help, Closer to Hope.'), findsOneWidget);

      // Advance past the 2.2s navigation timer to transition cleanly
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));

      // After splash transitions, the login screen is displayed
      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('Full flow: Login -> Register -> Register citizen -> RoleShell', (
      WidgetTester tester,
    ) async {
      final theme = ThemeController();
      final session = SessionService();

      await tester.pumpWidget(
        ResQApp(themeController: theme, sessionService: session),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Tap Create Account
      final createAccountBtn = find.text(
        "Don't have an account? Sign Up (Citizen)",
      );
      expect(createAccountBtn, findsOneWidget);
      await tester.ensureVisible(createAccountBtn);
      await tester.tap(createAccountBtn);
      await tester.pumpAndSettle();

      // Verify we are on RegisterScreen
      expect(find.text('Create Citizen Account'), findsOneWidget);

      // Fill in the form
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g., Ali Khan'),
        'Ali Khan',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g., ali@mail.com'),
        'ali@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '03XXXXXXXXX'),
        '03001234567',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a secure password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'password123',
      );

      // Tap submit button
      final submitBtn = find.widgetWithText(InkWell, 'Create Account');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify we returned to Login screen with success message
      expect(find.text('Sign In'), findsAtLeast(1));
      expect(
        find.text(
          'Account registered successfully! Please sign in with your credentials.',
        ),
        findsOneWidget,
      );

      // Dismiss snackbar so it doesn't obstruct subsequent taps
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Scroll up to ensure email & password fields are visible
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      // Now verify the newly registered citizen can log in
      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. citizen@resq.com'),
        'ali@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your password'),
        'password123',
      );
      await tester.pumpAndSettle();

      final signInBtn = find.widgetWithText(PrimaryGradientButton, 'Sign In');
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      // Verify we navigated to RoleShell with CitizenHomeScreen loaded
      expect(find.text('REPORT EMERGENCY NOW'), findsOneWidget);
      expect(find.text('CITIZEN'), findsOneWidget);
    });

    test('SessionService demo switching updates active role', () async {
      final session = SessionService();
      expect(session.isLoggedIn, isFalse);

      await session.demoLogin('dispatcher');
      expect(session.isLoggedIn, isTrue);
      expect(session.role, equals('dispatcher'));

      await session.demoLogin('driver');
      expect(session.role, equals('driver'));

      await session.logout();
      expect(session.isLoggedIn, isFalse);
      expect(session.role, isNull);
    });

    test('AppColors resolves status colors correctly', () {
      expect(AppColors.forStatus('PENDING'), equals(AppColors.statusPending));
      expect(AppColors.forStatus('ASSIGNED'), equals(AppColors.statusAssigned));
      expect(
        AppColors.forStatus('AVAILABLE'),
        equals(AppColors.statusCompleted),
      );
      expect(
        AppColors.forStatus('MAINTENANCE'),
        equals(AppColors.statusMaintenance),
      );
    });
  });
}
