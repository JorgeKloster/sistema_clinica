import 'package:controle_clinica/models/appointment.dart';

class Schedule {
  final String id;
  final String userId;
  final List<Appointment> appointments;

  Schedule({
    required this.id,
    required this.userId,
    required this.appointments,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      userId: json['userId'],
      appointments:
          (json['appointments'] as List)
              .map((a) => Appointment.fromJson(a))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'appointments': appointments.map((a) => a.toJson()).toList(),
  };
}
