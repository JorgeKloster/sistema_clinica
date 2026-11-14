/// Status aceitos pela API -> texto exibido.
const Map<String, String> appointmentStatusLabels = {
  "scheduled": "Agendado",
  "confirmed": "Confirmado",
  "in_progress": "Em atendimento",
  "completed": "Concluído",
  "canceled": "Cancelado",
};

class Appointment {
  final int id;
  final int patientId;
  final String patientName;
  final int doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final int procedureId;
  final String procedureName;

  /// Horário local da clínica (a API não envia fuso).
  final DateTime start;
  final DateTime end;

  /// scheduled | confirmed | completed | canceled
  final String status;
  final String notes;

  /// Início/fim reais do atendimento (nulos até acontecerem).
  final DateTime? startedAt;
  final DateTime? finishedAt;

  /// Anotações clínicas do atendimento.
  final String clinicalNotes;

  /// Sala em que o atendimento acontece (a do procedimento).
  final int roomId;
  final String roomName;

  /// Segundos desde o início, calculados pelo servidor (só em atendimento).
  /// Não depende do relógio nem do fuso do computador.
  final int elapsedSeconds;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    this.doctorSpecialty = "",
    required this.procedureId,
    required this.procedureName,
    required this.start,
    required this.end,
    required this.status,
    this.notes = "",
    this.startedAt,
    this.finishedAt,
    this.clinicalNotes = "",
    this.roomId = 0,
    this.roomName = "",
    this.elapsedSeconds = 0,
  });

  DateTime get date => DateTime(start.year, start.month, start.day);

  int get durationMinutes => end.difference(start).inMinutes;

  String get statusLabel => appointmentStatusLabels[status] ?? status;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['appointment_id'],
      patientId: json['patient_id'],
      patientName: json['patient_name'] ?? "",
      doctorId: json['doctor_id'],
      doctorName: json['doctor_name'] ?? "",
      doctorSpecialty: json['doctor_specialty'] ?? "",
      procedureId: json['procedure_id'],
      procedureName: json['procedure_name'] ?? "",
      // "2026-11-16T08:00:00" (sem fuso) vira um DateTime local.
      start: DateTime.parse(json['starts_at']),
      end: DateTime.parse(json['ends_at']),
      status: json['status'] ?? "scheduled",
      notes: json['notes'] ?? "",
      startedAt: _optionalDate(json['started_at']),
      finishedAt: _optionalDate(json['finished_at']),
      clinicalNotes: json['clinical_notes'] ?? "",
      roomId: json['room_id'] ?? 0,
      roomName: json['room_name'] ?? "",
      elapsedSeconds: json['elapsed_seconds'] ?? 0,
    );
  }

  static DateTime? _optionalDate(dynamic value) {
    final text = value?.toString() ?? "";

    return text.isEmpty ? null : DateTime.tryParse(text);
  }

  Map<String, dynamic> toJson() => {
    'appointment_id': id,
    'patient_id': patientId,
    'patient_name': patientName,
    'doctor_id': doctorId,
    'doctor_name': doctorName,
    'doctor_specialty': doctorSpecialty,
    'procedure_id': procedureId,
    'procedure_name': procedureName,
    'starts_at': start.toIso8601String(),
    'ends_at': end.toIso8601String(),
    'status': status,
    'notes': notes,
    'started_at': startedAt?.toIso8601String() ?? "",
    'finished_at': finishedAt?.toIso8601String() ?? "",
    'clinical_notes': clinicalNotes,
    'room_id': roomId,
    'room_name': roomName,
    'elapsed_seconds': elapsedSeconds,
  };
}
