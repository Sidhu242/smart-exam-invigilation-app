import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoggedIn = false;
  String? _token;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;

  Future<bool> login(String email, String password) async {
    final success = await _apiService.login(email, password);
    _isLoggedIn = success;
    if (success) {
      _token = await _apiService.getToken();
    }
    notifyListeners();
    return success;
  }

  Future<bool> register(
      String name, String email, String password, String role) async {
    final success = await _apiService.register(name, email, password, role);
    notifyListeners();
    return success;
  }

  void logout() async {
    _isLoggedIn = false;
    _token = null;
    await _apiService.getToken();
    notifyListeners();
  }
}
