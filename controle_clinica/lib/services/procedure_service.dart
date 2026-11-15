import 'dart:convert';
import 'package:controle_clinica/services/api_exception.dart';
import 'package:controle_clinica/services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class ProcedureService {
  static const String _baseUrl = apiBaseUrl;

  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${AuthService().token}",
  };

  static ApiException _error(String fallback, http.Response response) {
    final body = response.body.trim();
    return ApiException(body.isNotEmpty ? body : fallback);
  }

  static Future<List<dynamic>> getProcedures() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/procedures"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw _error("Erro ao carregar procedimentos", response);
  }

  static Future<void> createProcedure(Map<String, dynamic> values) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/procedures/create"),
      headers: _headers,
      body: jsonEncode(values),
    );

    if (response.statusCode != 201) {
      throw _error("Erro ao cadastrar procedimento", response);
    }
  }

  static Future<void> updateProcedure(
    int procedureId,
    Map<String, dynamic> values,
  ) async {
    final response = await http.put(
      Uri.parse("$_baseUrl/procedures/update?id=$procedureId"),
      headers: _headers,
      body: jsonEncode(values),
    );

    if (response.statusCode != 200) {
      throw _error("Erro ao atualizar procedimento", response);
    }
  }

  static Future<void> deleteProcedure(int procedureId) async {
    final response = await http.delete(
      Uri.parse("$_baseUrl/procedures/delete?id=$procedureId"),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw _error("Erro ao excluir procedimento", response);
    }
  }
}
