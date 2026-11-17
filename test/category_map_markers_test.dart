import 'package:flutter_test/flutter_test.dart';
import 'package:resq/core/mock/demo_data.dart';
import 'package:resq/core/mock/mock_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 1: MockRepository getEmergenciesByCategory tests', () {
    test('filters emergencies correctly by category', () {
      final repo = MockRepository();

      final medicalEmergencies = repo.getEmergenciesByCategory(EmergencyCategory.medical);
      expect(medicalEmergencies.isNotEmpty, isTrue);
      expect(medicalEmergencies.every((e) => e.category == EmergencyCategory.medical), isTrue);

      final fireEmergencies = repo.getEmergenciesByCategory(EmergencyCategory.fire);
      expect(fireEmergencies.every((e) => e.category == EmergencyCategory.fire), isTrue);

      final accidentEmergencies = repo.getEmergenciesByCategory(EmergencyCategory.accident);
      expect(accidentEmergencies.every((e) => e.category == EmergencyCategory.accident), isTrue);

      final rescueEmergencies = repo.getEmergenciesByCategory(EmergencyCategory.rescue);
      expect(rescueEmergencies.every((e) => e.category == EmergencyCategory.rescue), isTrue);

      // Case insensitivity test
      final lowercaseMedical = repo.getEmergenciesByCategory('medical');
      expect(lowercaseMedical.length, equals(medicalEmergencies.length));

      // Non-existent category
      final nonExistent = repo.getEmergenciesByCategory('UNKNOWN_CATEGORY');
      expect(nonExistent.isEmpty, isTrue);
    });
  });
}
