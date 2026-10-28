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
        "clinic_id": authService.clinicId,
        "name": values["name"],
        "cpf": values["cpf"],
        "birth_date": values["birth_date"],
        "email": values["email"],
        "phone": values["phone"],
        "updated_by": authService.userId,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Falha ao criar paciente: ${response.body}");
    }
  }
}
