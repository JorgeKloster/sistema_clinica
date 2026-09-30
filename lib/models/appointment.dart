class Appointment {
  final int id;
  final int clinicId;
  final int patientId;
  final int doctorId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String procedure; // e.g. "consultation", "procedure"
  final String status;
  final String notes;

  Appointment({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.procedure,
    required this.status,
    required this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      clinicId: json['clinicId'],
      patientId: json['patientId'],
      doctorId: json['doctorId'],
      date: DateTime.parse(json['dateTime']),
      startTime: DateTime.parse(json['dateTime']),
      endTime: DateTime.parse(json['dateTime']),
      procedure: json['procedure'],
      status: json['status'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clinicId': clinicId,
    'patientId': patientId,
    'doctorId': doctorId,
    'date': date.toIso8601String(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'procedure': procedure,
    'status': status,
    'notes': notes,
  };
}
