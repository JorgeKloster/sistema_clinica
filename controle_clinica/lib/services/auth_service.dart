import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();
  Map<String, dynamic>? currentUser;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? token;

  Future<bool> login(String email, String password) async {
    final url = Uri.parse("$apiBaseUrl/users/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data["token"];
      currentUser = data["user"];

      await saveToken(token!);

      return true;
    }
    return false;
  }

  Future<void> saveToken(String t) async {
    token = t;
    await _storage.write(key: "jwt_token", value: t);
  }

  Future<void> loadToken() async {
    token = await _storage.read(key: "jwt_token");
  }

  Future<void> clearToken() async {
    token = null;
    await _storage.delete(key: "jwt_token");
  }

  Future<void> initialize() async {
    await loadToken();
  }

  /// Dados do usuário gravados dentro do JWT (user_id, clinic_id, role).
  /// Servem de reserva quando o app foi reaberto com o token salvo e o
  /// [currentUser] (preenchido só no login) está vazio.
  Map<String, dynamic>? _tokenClaims() {
    final parts = token?.split('.');

    if (parts == null || parts.length != 3) return null;

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  int? get clinicId =>
      currentUser?["clinic_id"] ?? _tokenClaims()?["clinic_id"];

  int? get userId => currentUser?["user_id"] ?? _tokenClaims()?["user_id"];

  /// admin | doctor | receptionist
  String? get role => currentUser?["role"] ?? _tokenClaims()?["role"];
}
