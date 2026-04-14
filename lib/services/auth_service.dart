import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'https://studyflow-k4cn.onrender.com/api';

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    return _processResponse(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return _processResponse(response);
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    try {
      var data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        // The message or error field might be a Map or List depending on the framework
        var errorData = data['message'] ?? data['error'] ?? 'An error occurred';
        String message;
        if (errorData is String) {
          message = errorData;
        } else if (errorData is Map) {
          // Backend sends { status, message, stack } — only show the message
          message = errorData['message']?.toString() ?? errorData.values.first.toString();
        } else if (errorData is List) {
          message = errorData.join(', ');
        } else {
          message = errorData.toString();
        }
        throw Exception(message);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Server error (${response.statusCode})');
      }
      rethrow;
    }
  }
}
