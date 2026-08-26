class Appointment {
  final int id;
  final int patientId;
  final String patientName;
  final int doctorId;
  final String doctorName;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String type; // e.g. "consultation", "procedure"
  final String notes;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      doctorId: json['doctorId'],
      doctorName: json['doctorName'],
      date: DateTime.parse(json['dateTime']),
      startTime: DateTime.parse(json['dateTime']),
      endTime: DateTime.parse(json['dateTime']),
      type: json['type'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'patientName': patientName,
    'doctorId': doctorId,
    'doctorName': doctorName,
    'date': date.toIso8601String(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'type': type,
    'notes': notes,
  };
}
