class Patient {
  final String id;
  final int clinicId;
  final String name;
  final int birthDate;
  final String gender;
  final String phone;
  final String email;

  Patient({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.phone,
    required this.email,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      clinicId: json['clinicId'],
      name: json['name'],
      birthDate: json['birthDate'],
      gender: json['gender'],
      phone: json['phone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clinicId': clinicId,
    'name': name,
    'birthDate': birthDate,
    'gender': gender,
    'phone': phone,
    'email': email,
  };
}
