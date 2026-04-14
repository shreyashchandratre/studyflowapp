import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ResourceService {
  static const String _base = 'https://studyflow-k4cn.onrender.com/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Map<String, String> _headers(String token) => {'Authorization': 'Bearer $token'};

  Future<List<dynamic>> getResources(String topic) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.get(
      Uri.parse('$_base/resources/topic/${Uri.encodeComponent(topic)}'),
      headers: _headers(token),
    );
    return _parseList(res);
  }

  Future<List<dynamic>> getVideos(String topic) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.get(
      Uri.parse('$_base/resources/videos/${Uri.encodeComponent(topic)}'),
      headers: _headers(token),
    );
    return _parseList(res);
  }

  Future<List<dynamic>> getArticles(String topic) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.get(
      Uri.parse('$_base/resources/articles/${Uri.encodeComponent(topic)}'),
      headers: _headers(token),
    );
    return _parseList(res);
  }

  Future<List<dynamic>> getCourses(String topic) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.get(
      Uri.parse('$_base/resources/courses/${Uri.encodeComponent(topic)}'),
      headers: _headers(token),
    );
    return _parseList(res);
  }

  List<dynamic> _parseList(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data['data'] ?? data['results'] ?? (data is List ? data : []);
      }
      final msg = data['message'] ?? data['error'] ?? 'Error ${res.statusCode}';
      throw Exception(msg.toString());
    } catch (e) {
      if (e is FormatException) throw Exception('Server error ${res.statusCode}');
      rethrow;
    }
  }
}
