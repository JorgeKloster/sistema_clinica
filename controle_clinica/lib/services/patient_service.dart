import 'dart:convert';
import 'package:controle_clinica/services/auth_service.dart';
import 'package:http/http.dart' as http;

class PatientService {
  static Future<void> createPatient(Map<String, dynamic> values) async {
    final url = Uri.parse("http://localhost:8080/patients/create");
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
      throw Exception("Falha ao criar paciente: ${response.body}");
    }
  }

  static Future<List<dynamic>> getPatients() async {
    final authService = AuthService();

    final response = await http.get(
      Uri.parse("http://localhost:8080/patients"),
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
      Uri.parse("http://localhost:8080/patients/delete?id=$patientId"),
      headers: {"Authorization": "Bearer ${authService.token}"},
    );

    if (response.statusCode != 204) {
      throw Exception("Erro ao excluir paciente");
    }
  }

  static Future<void> updatePatient(
    int patientId,
    Map<String, dynamic> values,
  ) async {
    final authService = AuthService();

    final response = await http.put(
      Uri.parse("http://localhost:8080/patients/update?id=$patientId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${authService.token}",
      },
      body: jsonEncode(values),
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao atualizar paciente");
    }
  }
}
