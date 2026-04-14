import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static const String baseUrl = 'https://studyflow-k4cn.onrender.com/api/chat';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Map<String, String> _headers(String token, {bool json = false}) => {
        'Authorization': 'Bearer $token',
        if (json) 'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>> sendMessage(String message, {String? sessionId}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final body = <String, dynamic>{'message': message};
    if (sessionId != null) body['sessionId'] = sessionId;
    final res = await http.post(
      Uri.parse('$baseUrl/message'),
      headers: _headers(token, json: true),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  Future<List<dynamic>> getHistory(String sessionId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.get(
      Uri.parse('$baseUrl/history/$sessionId'),
      headers: _headers(token),
    );
    final data = _parse(res);
    return data['data'] ?? data['messages'] ?? [];
  }

  Future<List<dynamic>> getSessions({int limit = 20, int skip = 0}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.get(
      Uri.parse('$baseUrl/sessions?limit=$limit&skip=$skip'),
      headers: _headers(token),
    );
    final data = _parse(res);
    return data['data'] ?? data['sessions'] ?? [];
  }

  Future<void> deleteSession(String sessionId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.delete(
      Uri.parse('$baseUrl/sessions/$sessionId'),
      headers: _headers(token),
    );
    _parse(res);
  }

  Future<List<dynamic>> getRecommendations() async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.get(
      Uri.parse('$baseUrl/recommendations'),
      headers: _headers(token),
    );
    final data = _parse(res);
    return data['data'] ?? data['recommendations'] ?? [];
  }

  Future<List<dynamic>> generateQuizFromChat({required List<String> topics, String? sessionId}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final body = <String, dynamic>{'topics': topics};
    if (sessionId != null) body['sessionId'] = sessionId;
    final res = await http.post(
      Uri.parse('$baseUrl/generate-quiz'),
      headers: _headers(token, json: true),
      body: jsonEncode(body),
    );
    final data = _parse(res);
    return data['data'] ?? data['questions'] ?? [];
  }

  Map<String, dynamic> _parse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      final msg = data['message'] ?? data['error'] ?? 'Error ${response.statusCode}';
      throw Exception(msg is String ? msg : msg.toString());
    } catch (e) {
      if (e is FormatException) throw Exception('Server error ${response.statusCode}');
      rethrow;
    }
  }
}
