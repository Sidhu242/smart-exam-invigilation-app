import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://sidhu2005-seis-backend.hf.space';

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

  Future<bool> login(String id, String password) async {
    final response = await _post('/login', {
      'id': id,
      'password': password,
    });
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      // Aligned with backend: Checks "success" field and gets token from "data"
      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        final token = jsonResponse['data']['token'];
        if (token != null) {
          await setToken(token);
          return true;
        }
      }
    }
    return false;
  }

  Future<bool> register(
      String name, String id, String password, String role, String institution) async {
    // Aligned with backend: Changed /register to /signup and used correct fields
    final response = await _post('/signup', {
      'name': name,
      'id': id,
      'password': password,
      'role': role,
      'institution': institution,
    });
    
    if (response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['success'] == true;
    }
    return false;
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
