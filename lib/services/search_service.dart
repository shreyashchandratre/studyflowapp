import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SearchService {
  static const String _base = 'https://studyflow-k4cn.onrender.com/api/search';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Map<String, String> _headers(String token) => {'Authorization': 'Bearer $token'};

  /// Global search across all study materials
  Future<List<dynamic>> search(String query) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.get(
      Uri.parse('$_base?q=${Uri.encodeComponent(query)}'),
      headers: _headers(token),
    );
    return _parseList(res);
  }

  /// Filtered search for topics only
  Future<List<dynamic>> searchTopics(String query) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.get(
      Uri.parse('$_base/topics?q=${Uri.encodeComponent(query)}'),
      headers: _headers(token),
    );
    return _parseList(res);
  }

  /// Auto-complete suggestions and recent history
  Future<List<dynamic>> getSuggestions(String query) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.get(
      Uri.parse('$_base/suggestions?q=${Uri.encodeComponent(query)}'),
      headers: _headers(token),
    );
    return _parseList(res);
  }

  /// User's most recent search queries
  Future<List<dynamic>> getRecentSearches() async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.get(
      Uri.parse('$_base/recent'),
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
