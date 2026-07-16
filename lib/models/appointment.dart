class Appointment {
  final String id;
  final String patientId;
  final String doctorId; // could be doctor, dentist, physiotherapist
  final DateTime dateTime;
  final String type; // e.g. "consultation", "procedure"
  final String notes;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.dateTime,
    required this.type,
    required this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patientId'],
      doctorId: json['doctorId'],
      dateTime: DateTime.parse(json['dateTime']),
      type: json['type'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'doctorId': doctorId,
    'dateTime': dateTime.toIso8601String(),
    'type': type,
    'notes': notes,
  };
}
