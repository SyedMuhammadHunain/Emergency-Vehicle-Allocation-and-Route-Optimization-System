import 'package:flutter_test/flutter_test.dart';
import 'package:resq/core/mock/mock_repository.dart';
import 'package:resq/core/services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 3 - Driver Authentication & Role Enforcement Tests', () {
    late MockRepository mockRepo;
    late SessionService sessionService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockRepo = MockRepository();
      sessionService = SessionService();
    });

    test('Admin creates new Driver account; Driver logs in with valid credentials',
        () async {
      // 1. Admin provisions a new driver account
      final newDriver = mockRepo.createStaffAccount(
        name: 'Captain Imran Khan',
        email: 'imran.driver@resq.pk',
        password: 'SecureDriverPass123',
        role: 'driver',
        phone: '03009988776',
      );

      expect(newDriver.role, equals('driver'));
      expect(newDriver.email, equals('imran.driver@resq.pk'));

      // 2. Driver authenticates using those exact assigned credentials
      final authResult = await sessionService.loginWithCredentials(
        'imran.driver@resq.pk',
        'SecureDriverPass123',
        mockRepo,
      );

      expect(authResult, isNotNull);
      expect(authResult!.role, equals('driver'));
      expect(sessionService.isLoggedIn, isTrue);
      expect(sessionService.role, equals('driver'));
      expect(sessionService.userName, equals('Captain Imran Khan'));
      expect(sessionService.userEmail, equals('imran.driver@resq.pk'));
      expect(sessionService.userPhone, equals('03009988776'));
      expect(sessionService.userId, equals(newDriver.id));
    });

    test('Non-driver account cannot authenticate as Driver', () async {
      // Citizen registers
      final citizen = mockRepo.registerCitizen(
        name: 'Saad Ali',
        email: 'saad@test.com',
        password: 'Password123',
        phone: '03112233445',
      );

      // Logs in with citizen credentials
      await sessionService.loginWithCredentials(
        'saad@test.com',
        'Password123',
        mockRepo,
      );

      // Must remain citizen role, never driver
      expect(sessionService.isLoggedIn, isTrue);
      expect(sessionService.role, equals('citizen'));
      expect(sessionService.role, isNot('driver'));
      expect(sessionService.userId, equals(citizen.id));
      expect(sessionService.userPhone, equals('03112233445'));
    });

    test('Driver session state persists and restores userPhone and userId correctly',
        () async {
      final driver = mockRepo.createStaffAccount(
        name: 'Driver Bilal',
        email: 'bilal@resq.pk',
        password: 'DriverPass456',
        role: 'driver',
        phone: '03215554433',
      );

      await sessionService.loginWithCredentials(
        'bilal@resq.pk',
        'DriverPass456',
        mockRepo,
      );

      expect(sessionService.role, equals('driver'));
      expect(sessionService.userPhone, equals('03215554433'));

      // Create new session instance and restore
      final restoredSession = SessionService();
      await restoredSession.restore();

      expect(restoredSession.isLoggedIn, isTrue);
      expect(restoredSession.role, equals('driver'));
      expect(restoredSession.userName, equals('Driver Bilal'));
      expect(restoredSession.userEmail, equals('bilal@resq.pk'));
      expect(restoredSession.userPhone, equals('03215554433'));
      expect(restoredSession.userId, equals(driver.id));
    });
  });
}
