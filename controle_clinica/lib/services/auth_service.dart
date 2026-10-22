import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  Map<String, dynamic>? currentUser;
  final _storage = const FlutterSecureStorage();
  String? token;

  Future<bool> login(String email, String password) async {
    final url = Uri.parse("http://localhost:8080/users/login");
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

  int get clinicId => currentUser?["clinic_id"];
  int get userId => currentUser?["user_id"];
}
