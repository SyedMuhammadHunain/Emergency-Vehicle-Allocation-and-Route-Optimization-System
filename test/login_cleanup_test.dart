import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:resq/features/auth/screens/login_screen.dart';

void main() {
  group('Task 2 - Login Screen Demo Artifacts Removal Tests', () {
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
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    testWidgets('LoginScreen does not render demo credentials container or role chips',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Demo credentials section must not exist
      expect(find.text('DEMO MODE CREDENTIALS'), findsNothing);
      expect(find.textContaining('Tap any role below to prefill'), findsNothing);
      expect(find.textContaining('Citizen (citizen@resq.com)'), findsNothing);
      expect(find.textContaining('Dispatcher (dispatcher@resq.com)'), findsNothing);
      expect(find.textContaining('Driver (driver@resq.com)'), findsNothing);
      expect(find.textContaining('Admin (admin@resq.com)'), findsNothing);
      expect(find.textContaining('DEMO ROLE SWITCHER'), findsNothing);

      // Normal login inputs and buttons must remain
      expect(find.text('Sign In'), findsAtLeast(1));
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text("Don't have an account? Sign Up (Citizen)"), findsOneWidget);
    });

    testWidgets('Invalid credentials displays clean message without demo references',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'e.g. citizen@resq.com'), 'wrong@resq.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your password'), 'WrongPass');

      final signInBtn = find.widgetWithText(InkWell, 'Sign In');
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      // Clean error without demo references
      expect(
        find.text(
            'Invalid email or password. Please verify your credentials and try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('DEMO MODE'), findsNothing);
    });
  });
}
