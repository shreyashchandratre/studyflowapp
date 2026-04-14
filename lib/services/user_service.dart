import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'https://studyflow-k4cn.onrender.com/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Map<String, String> _headers(String token, {bool json = false}) {
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    // GET /users/ — returns the currently logged-in user's profile
    final res = await http.get(Uri.parse('$baseUrl/users/'), headers: _headers(token));
    return _parse(res);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.put(
      Uri.parse('$baseUrl/users/'),
      headers: _headers(token, json: true),
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> updateUsername(String username) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.put(
      Uri.parse('$baseUrl/compare/username'),
      headers: _headers(token, json: true),
      body: jsonEncode({'username': username}),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> getUserByUsername(String username) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$username'));
    return _parse(res);
  }

  Future<List<dynamic>> getLeaderboard({int limit = 10, String sortBy = 'xp'}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/users/leaderboard/top?limit=$limit&sortBy=$sortBy'),
    );
    final data = _parse(res);
    return data['data'] ?? data['users'] ?? [];
  }

  Future<void> followUser(String userId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.post(
      Uri.parse('$baseUrl/users/follow/$userId'),
      headers: _headers(token),
    );
    _parse(res);
  }

  Future<void> unfollowUser(String userId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final res = await http.post(
      Uri.parse('$baseUrl/users/unfollow/$userId'),
      headers: _headers(token),
    );
    _parse(res);
  }

  Future<Map<String, dynamic>> compareWithUser(String username) async {
    try {
      final myProfile = await getMyProfile();
      // Mock data since backend compare endpoint is missing/404
      final mocks = [
        {'name': 'Alex Johnson', 'username': 'alexj', 'xp': 1200, 'streak': 12, 'quizzesTaken': 45, 'avgAccuracy': 88},
        {'name': 'Sarah Smith', 'username': 'sarah_study', 'xp': 850, 'streak': 5, 'quizzesTaken': 20, 'avgAccuracy': 75},
        {'name': 'Michael T.', 'username': 'mike_t', 'xp': 430, 'streak': 2, 'quizzesTaken': 10, 'avgAccuracy': 60},
        {'name': 'Emma Davis', 'username': 'emma_d', 'xp': 2100, 'streak': 30, 'quizzesTaken': 88, 'avgAccuracy': 95},
        {'name': 'David Kim', 'username': 'dkim99', 'xp': 150, 'streak': 1, 'quizzesTaken': 3, 'avgAccuracy': 50},
      ];
      final them = mocks.firstWhere(
        (m) => m['username'].toString().toLowerCase() == username.toLowerCase(), 
        orElse: () => {'name': 'Student', 'username': username, 'xp': 500, 'streak': 3, 'quizzesTaken': 15, 'avgAccuracy': 70}
      );
      
      return {
        'currentUser': myProfile,
        'comparedUser': them
      };
    } catch (e) {
      throw Exception('Failed to compare: $e');
    }
  }

  Future<List<dynamic>> searchUsers(String query) async {
    // Mock user search since backend /compare/search endpoint returns 404
    final q = query.toLowerCase();
    final mocks = [
      {'name': 'Alex Johnson', 'username': 'alexj', 'xp': 1200, 'streak': 12, 'quizzesTaken': 45},
      {'name': 'Sarah Smith', 'username': 'sarah_study', 'xp': 850, 'streak': 5, 'quizzesTaken': 20},
      {'name': 'Michael T.', 'username': 'mike_t', 'xp': 430, 'streak': 2, 'quizzesTaken': 10},
      {'name': 'Emma Davis', 'username': 'emma_d', 'xp': 2100, 'streak': 30, 'quizzesTaken': 88},
      {'name': 'David Kim', 'username': 'dkim99', 'xp': 150, 'streak': 1, 'quizzesTaken': 3},
    ];
    return mocks.where((u) => 
      u['username'].toString().toLowerCase().contains(q) || 
      u['name'].toString().toLowerCase().contains(q)
    ).toList();
  }

  Map<String, dynamic> _parse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      final msg = data['message'] ?? data['error'] ?? 'Server error ${response.statusCode}';
      throw Exception(msg is String ? msg : msg.toString());
    } catch (e) {
      if (e is FormatException) throw Exception('Server error ${response.statusCode}');
      rethrow;
    }
  }
}
