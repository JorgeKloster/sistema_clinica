import 'dart:convert';
import 'package:controle_clinica/services/api_exception.dart';
import 'package:controle_clinica/services/auth_service.dart';
import 'api_http.dart' as http;
import '../config.dart';

/// Profissionais = usuários da clínica (tabela `users`).
class ProfessionalService {
  static const String _baseUrl = apiBaseUrl;

  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${AuthService().token}",
  };

  static ApiException _error(String fallback, http.Response response) {
    final body = response.body.trim();
    return ApiException(body.isNotEmpty ? body : fallback);
  }

  static Future<List<dynamic>> getProfessionals() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/users"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw _error("Erro ao carregar profissionais", response);
  }

  static Future<void> createProfessional(Map<String, dynamic> values) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/users/create"),
      headers: _headers,
      body: jsonEncode(values),
    );

    if (response.statusCode != 201) {
      throw _error("Erro ao cadastrar profissional", response);
    }
  }

  static Future<void> updateProfessional(
    int userId,
    Map<String, dynamic> values,
  ) async {
    final response = await http.put(
      Uri.parse("$_baseUrl/users/update?id=$userId"),
      headers: _headers,
      body: jsonEncode(values),
    );

    if (response.statusCode != 200) {
      throw _error("Erro ao atualizar profissional", response);
    }
  }

  static Future<void> deleteProfessional(int userId) async {
    final response = await http.delete(
      Uri.parse("$_baseUrl/users/delete?id=$userId"),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw _error("Erro ao excluir profissional", response);
    }
  }
}
