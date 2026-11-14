import 'dart:convert';
import 'package:controle_clinica/models/appointment.dart';
import 'package:controle_clinica/services/api_exception.dart';
import 'package:controle_clinica/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AppointmentService {
  static const String _baseUrl = "http://localhost:8080";

  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${AuthService().token}",
  };

  static ApiException _error(String fallback, http.Response response) {
    final body = response.body.trim();
    return ApiException(body.isNotEmpty ? body : fallback);
  }

  /// Agendamentos (sem os cancelados) de [from] (inclusive) até [to]
  /// (exclusivo). Sem [doctorId] traz todos os profissionais da clínica.
  static Future<List<Appointment>> getAppointments({
    required DateTime from,
    required DateTime to,
    int? doctorId,
  }) async {
    final format = DateFormat('yyyy-MM-dd');

    final uri = Uri.parse("$_baseUrl/appointments").replace(
      queryParameters: {
        "from": format.format(from),
        "to": format.format(to),
        if (doctorId != null) "doctor_id": "$doctorId",
      },
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;

      return data
          .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw _error("Erro ao carregar agenda", response);
  }

  static Future<Appointment> getAppointment(int appointmentId) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/appointments/get?id=$appointmentId"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Appointment.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw _error("Erro ao carregar o agendamento", response);
  }

  /// Atendimentos anteriores do paciente (mais recentes primeiro).
  static Future<List<Appointment>> getPatientHistory(
    int patientId, {
    int? excludeAppointmentId,
  }) async {
    final uri = Uri.parse("$_baseUrl/appointments/history").replace(
      queryParameters: {
        "patient_id": "$patientId",
        if (excludeAppointmentId != null) "exclude": "$excludeAppointmentId",
      },
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;

      return data
          .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw _error("Erro ao carregar o histórico", response);
  }

  static Future<void> updateClinicalNotes(
    int appointmentId,
    String notes,
  ) async {
    final response = await http.put(
      Uri.parse("$_baseUrl/appointments/clinical-notes?id=$appointmentId"),
      headers: _headers,
      body: jsonEncode({"clinical_notes": notes}),
    );

    if (response.statusCode != 200) {
      throw _error("Erro ao salvar as anotações", response);
    }
  }

  static Future<void> createAppointment(Map<String, dynamic> values) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/appointments/create"),
      headers: _headers,
      body: jsonEncode(values),
    );

    if (response.statusCode != 201) {
      throw _error("Erro ao criar agendamento", response);
    }
  }

  static Future<void> updateAppointment(
    int appointmentId,
    Map<String, dynamic> values,
  ) async {
    final response = await http.put(
      Uri.parse("$_baseUrl/appointments/update?id=$appointmentId"),
      headers: _headers,
      body: jsonEncode(values),
    );

    if (response.statusCode != 200) {
      throw _error("Erro ao atualizar agendamento", response);
    }
  }

  /// Muda só o status: confirmed, in_progress, completed ou canceled.
  static Future<void> updateStatus(int appointmentId, String status) async {
    final response = await http.put(
      Uri.parse("$_baseUrl/appointments/status?id=$appointmentId"),
      headers: _headers,
      body: jsonEncode({"status": status}),
    );

    if (response.statusCode != 200) {
      throw _error("Erro ao atualizar o status", response);
    }
  }

  /// Exclusão definitiva (só administrador). No dia a dia use o status
  /// "canceled", que mantém o histórico.
  static Future<void> deleteAppointment(int appointmentId) async {
    final response = await http.delete(
      Uri.parse("$_baseUrl/appointments/delete?id=$appointmentId"),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw _error("Erro ao excluir agendamento", response);
    }
  }
}
