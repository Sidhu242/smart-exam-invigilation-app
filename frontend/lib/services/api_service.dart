import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body,
      {bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return await http.post(Uri.parse('$baseUrl$path'),
        headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> _get(String path, {bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return await http.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  Future<bool> login(String email, String password) async {
    final response = await _post('/login', {
      'username': email,
      'password': password,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['access_token']);
      return true;
    }
    return false;
  }

  Future<bool> register(
      String name, String email, String password, String role) async {
    final response = await _post('/register', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    return response.statusCode == 200;
  }

  Future<bool> sendFlag(Map<String, dynamic> flagData) async {
    final response = await _post('/api/flags', flagData, auth: true);
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getFlags(int examId) async {
    final response = await _get('/api/flags?exam_id=$examId', auth: true);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }
}
