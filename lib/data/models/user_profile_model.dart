class EmergencyContact {
  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isPrimary;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.isPrimary = false,
  });
}

class UserProfileModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String bloodType;
  final List<String> allergies;
  final List<String> medicalConditions;
  final String homeAddress;
  final List<EmergencyContact> emergencyContacts;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.bloodType,
    required this.allergies,
    required this.medicalConditions,
    required this.homeAddress,
    required this.emergencyContacts,
  });

  UserProfileModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? bloodType,
    List<String>? allergies,
    List<String>? medicalConditions,
    String? homeAddress,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      homeAddress: homeAddress ?? this.homeAddress,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}
