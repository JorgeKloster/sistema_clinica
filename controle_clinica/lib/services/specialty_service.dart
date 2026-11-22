import 'dart:convert';
import 'package:controle_clinica/services/api_exception.dart';
import 'package:controle_clinica/services/auth_service.dart';
import 'api_http.dart' as http;
import '../config.dart';

/// Especialidades oferecidas pela clínica (ex.: Dentista, Fisioterapeuta).
class SpecialtyService {
  static const String _baseUrl = apiBaseUrl;

  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${AuthService().token}",
  };

  static ApiException _error(String fallback, http.Response response) {
    final body = response.body.trim();
    return ApiException(body.isNotEmpty ? body : fallback);
  }

  /// Cada item: {"specialty_id": int, "name": String}
  static Future<List<dynamic>> getSpecialties() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/specialties"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw _error("Erro ao carregar especialidades", response);
  }

  static Future<void> createSpecialty(String name) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/specialties/create"),
      headers: _headers,
      body: jsonEncode({"name": name}),
    );

    if (response.statusCode != 201) {
      throw _error("Erro ao cadastrar especialidade", response);
    }
  }

  static Future<void> deleteSpecialty(int specialtyId) async {
    final response = await http.delete(
      Uri.parse("$_baseUrl/specialties/delete?id=$specialtyId"),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw _error("Erro ao excluir especialidade", response);
    }
  }
}
