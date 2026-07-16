class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String contactInfo;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contactInfo,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      contactInfo: json['contactInfo'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'gender': gender,
    'contactInfo': contactInfo,
  };
}
