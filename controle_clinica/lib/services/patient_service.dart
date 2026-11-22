import 'dart:convert';
import 'package:controle_clinica/services/api_exception.dart';
import 'package:controle_clinica/services/auth_service.dart';
import 'api_http.dart' as http;
import '../config.dart';

ApiException _apiError(String fallback, http.Response response) {
  final body = response.body.trim();
  return ApiException(body.isNotEmpty ? body : fallback);
}

class PatientService {
  static Future<void> createPatient(Map<String, dynamic> values) async {
    final url = Uri.parse("$apiBaseUrl/patients/create");
    final authService = AuthService();
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${authService.token}",
      },
      body: jsonEncode({
        "first_name": values["first_name"],
        "last_name": values["last_name"],
        "cpf": values["cpf"],
        "birth_date": values["birth_date"],
        "email": values["email"],
        "phone": values["phone"],
        "gender": values["gender"],
      }),
    );

    if (response.statusCode != 201) {
      throw _apiError("Falha ao criar paciente", response);
    }
  }

  static Future<List<dynamic>> getPatients() async {
    final authService = AuthService();

    final response = await http.get(
      Uri.parse("$apiBaseUrl/patients"),
      headers: {"Authorization": "Bearer ${authService.token}"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      "Erro ao carregar pacientes: ${response.statusCode} - ${response.body}",
    );
  }

  static Future<void> deletePatient(int patientId) async {
    final authService = AuthService();

    final response = await http.delete(
      Uri.parse("$apiBaseUrl/patients/delete?id=$patientId"),
      headers: {"Authorization": "Bearer ${authService.token}"},
    );

    if (response.statusCode != 204) {
      throw _apiError("Erro ao excluir paciente", response);
    }
  }

  static Future<void> updatePatient(
    int patientId,
    Map<String, dynamic> values,
  ) async {
    final authService = AuthService();

    final response = await http.put(
      Uri.parse("$apiBaseUrl/patients/update?id=$patientId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${authService.token}",
      },
      body: jsonEncode(values),
    );

    if (response.statusCode != 200) {
      throw _apiError("Erro ao atualizar paciente", response);
    }
  }

  /// Alergias, condições e medicamentos: um item por linha. Alterados só pela
  /// tela de atendimento; o servidor registra quem alterou e quando.
  static Future<void> updatePatientHealth(
    int patientId, {
    required List<String> allergies,
    required List<String> conditions,
    required List<String> medications,
  }) async {
    final response = await http.put(
      Uri.parse("$apiBaseUrl/patients/health?id=$patientId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AuthService().token}",
      },
      body: jsonEncode({
        "allergies": allergies.join("\n"),
        "medical_conditions": conditions.join("\n"),
        "medications": medications.join("\n"),
      }),
    );

    if (response.statusCode != 200) {
      throw _apiError("Erro ao salvar as informações de saúde", response);
    }
  }
}
