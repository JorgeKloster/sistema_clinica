import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

export 'package:http/http.dart' show Response;

/// Same functions as package:http, but any 401 from the API logs the user out.
class _AuthClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode == 401) {
      await AuthService().handleUnauthorized();
    }
    return response;
  }
}

final _client = _AuthClient();

Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
    _client.get(url, headers: headers);

Future<http.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _client.post(url, headers: headers, body: body, encoding: encoding);

Future<http.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _client.put(url, headers: headers, body: body, encoding: encoding);

Future<http.Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _client.delete(url, headers: headers, body: body, encoding: encoding);
