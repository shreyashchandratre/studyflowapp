import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    checkAuthStatus();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final responseData = await _authService.login(email, password);
      
      // The API wraps the response in a "data" object natively!
      final payload = responseData['data'] ?? responseData;
      
      _token = payload['token'] ?? payload['access_token'];
      _user = payload['user'];
      
      if (_token == null) {
        throw Exception("Server did not return a token. Got: ${responseData.keys.join(', ')}");
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final responseData = await _authService.register(name, email, password);
      
      // The API wraps the response in a "data" object natively!
      final payload = responseData['data'] ?? responseData;
      
      _token = payload['token'] ?? payload['access_token'];
      _user = payload['user'];
      
      if (_token == null) {
        throw Exception("Server did not return a token. Got: ${responseData.keys.join(', ')}");
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    notifyListeners();
  }
}
