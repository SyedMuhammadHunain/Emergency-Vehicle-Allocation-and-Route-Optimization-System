import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:resq/core/mock/demo_data.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:resq/core/theme/theme_controller.dart';
import 'package:resq/features/admin/screens/admin_profile_screen.dart';
import 'package:resq/features/dispatcher/screens/dispatcher_profile_screen.dart';
import 'package:resq/features/driver/screens/driver_profile_screen.dart';
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

  group('Task 10 - Profile Architecture Labels Removal Tests', () {
    testWidgets(
      'DispatcherProfileScreen has Prototype Architecture and demo label removed',
      (WidgetTester tester) async {
        final session = SessionService();
        await session.loginAsRegisteredCitizen(
          DemoUserAccount(
            id: 'USR-DISP-001',
            name: 'Dispatcher User',
            email: 'dispatcher@resq.pk',
            phone: '03001234567',
            role: 'dispatcher',
            password: 'Password123!',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        await tester.pumpWidget(
          createTestApp(const DispatcherProfileScreen(), session: session),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Prototype Architecture'), findsNothing);
        expect(find.textContaining('(Demo Prototype)'), findsNothing);
        expect(find.text('End Session & Sign Out'), findsOneWidget);
      },
    );

    testWidgets(
      'DriverProfileScreen has Prototype Driver Engine and demo label removed',
      (WidgetTester tester) async {
        final session = SessionService();
        await session.loginAsRegisteredCitizen(
          DemoUserAccount(
            id: 'USR-DRV-001',
            name: 'Driver User',
            email: 'driver@resq.pk',
            phone: '03001234567',
            role: 'driver',
            password: 'Password123!',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        await tester.pumpWidget(
          createTestApp(const DriverProfileScreen(), session: session),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Prototype Driver Engine'), findsNothing);
        expect(find.textContaining('(Demo Prototype)'), findsNothing);
        expect(find.text('End Shift & Sign Out'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminProfileScreen has Django REST Framework and Session Cryptography removed',
      (WidgetTester tester) async {
        final session = SessionService();
        await session.loginAsRegisteredCitizen(
          DemoUserAccount(
            id: 'USR-ADM-001',
            name: 'Admin User',
            email: 'admin@resq.pk',
            phone: '03001234567',
            role: 'admin',
            password: 'Password123!',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        await tester.pumpWidget(
          createTestApp(const AdminProfileScreen(), session: session),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Django REST Framework'), findsNothing);
        expect(find.textContaining('Session Cryptography'), findsNothing);
        expect(find.textContaining('(Demo Prototype)'), findsNothing);
        expect(find.text('End Administrator Session'), findsOneWidget);
      },
    );
  });
}
