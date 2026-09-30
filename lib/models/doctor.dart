class Doctor {
  final int id;
  final int clinicId;
  final String name;
  final String specialty;
  final String phone;
  final String email;

  Doctor({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.specialty,
    required this.phone,
    required this.email,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      clinicId: json['clinicId'],
      name: json['name'],
      specialty: json['specialty'],
      phone: json['phone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clinicId': clinicId,
    'name': name,
    'specialty': specialty,
    'phone': phone,
    'email': email,
  };
}
