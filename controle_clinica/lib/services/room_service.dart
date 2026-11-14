import 'dart:convert';
import 'package:controle_clinica/services/api_exception.dart';
import 'package:controle_clinica/services/auth_service.dart';
import 'package:http/http.dart' as http;

/// Salas da clínica e seus tipos (consultório médico, odontológico...).
class RoomService {
  static const String _baseUrl = "http://localhost:8080";

  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${AuthService().token}",
  };

  static ApiException _error(String fallback, http.Response response) {
    final body = response.body.trim();
    return ApiException(body.isNotEmpty ? body : fallback);
  }

  /// Cada item: room_id, name, room_type_id, room_type_name, resources
  /// (um por linha), procedure_count.
  static Future<List<dynamic>> getRooms() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/rooms"),
      headers: _headers,
    );

    if (response.statusCode == 200) return jsonDecode(response.body);

    throw _error("Erro ao carregar salas", response);
  }

  /// Painel de atendimentos: por sala, o atendimento em andamento (current)
  /// e o próximo agendamento do dia (next). Ambos podem ser nulos.
  static Future<List<dynamic>> getLiveRooms() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/rooms/live"),
      headers: _headers,
    );

    if (response.statusCode == 200) return jsonDecode(response.body);

    throw _error("Erro ao carregar o painel de salas", response);
  }

  static Future<void> createRoom(Map<String, dynamic> values) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/rooms/create"),
      headers: _headers,
      body: jsonEncode(values),
    );

    if (response.statusCode != 201) {
      throw _error("Erro ao cadastrar sala", response);
    }
  }

  static Future<void> updateRoom(int roomId, Map<String, dynamic> values) async {
    final response = await http.put(
      Uri.parse("$_baseUrl/rooms/update?id=$roomId"),
      headers: _headers,
      body: jsonEncode(values),
    );

    if (response.statusCode != 200) {
      throw _error("Erro ao atualizar sala", response);
    }
  }

  static Future<void> deleteRoom(int roomId) async {
    final response = await http.delete(
      Uri.parse("$_baseUrl/rooms/delete?id=$roomId"),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw _error("Erro ao excluir sala", response);
    }
  }

  /// Cada item: {"room_type_id": int, "name": String}
  static Future<List<dynamic>> getRoomTypes() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/room-types"),
      headers: _headers,
    );

    if (response.statusCode == 200) return jsonDecode(response.body);

    throw _error("Erro ao carregar tipos de sala", response);
  }

  static Future<void> createRoomType(String name) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/room-types/create"),
      headers: _headers,
      body: jsonEncode({"name": name}),
    );

    if (response.statusCode != 201) {
      throw _error("Erro ao cadastrar tipo de sala", response);
    }
  }

  static Future<void> deleteRoomType(int roomTypeId) async {
    final response = await http.delete(
      Uri.parse("$_baseUrl/room-types/delete?id=$roomTypeId"),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw _error("Erro ao excluir tipo de sala", response);
    }
  }
}
