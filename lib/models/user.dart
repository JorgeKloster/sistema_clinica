class User {
  final String id;
  final int clinicId;
  final String username;
  final String email;
  final String
  role; // e.g. "reception", "doctor", "dentist", "admin", "physiotherapist"

  User({
    required this.id,
    required this.clinicId,
    required this.username,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      clinicId: json['clinicId'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clinicId': clinicId,
    'username': username,
    'email': email,
    'role': role,
  };
}
