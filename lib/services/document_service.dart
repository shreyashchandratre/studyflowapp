import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_model.dart';

class DocumentService {
  static const String baseUrl = 'https://studyflow-k4cn.onrender.com/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<Document>> fetchDocuments() async {
    final token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token found");

    final response = await http.get(
      Uri.parse('$baseUrl/content'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final List dataList = decoded['data'] ?? decoded;
      return dataList.map((doc) => Document.fromJson(doc)).toList();
    } else {
      throw _parseError(response);
    }
  }

  Future<Document> uploadFile(String filePath, {String? filename}) async {
    final token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token found");

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/content/upload'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = filename ?? filePath.split('/').last;
    request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: filename));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final docData = decoded['data'] ?? decoded['document'] ?? decoded;
      return Document.fromJson(docData);
    } else {
      throw _parseError(response);
    }
  }

  Future<Document> uploadText(String text, {String? title}) async {
    final token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token found");

    final computedTitle = (title != null && title.isNotEmpty)
        ? title
        : 'Text Note - ${DateTime.now().toIso8601String().substring(0, 10)}';

    final response = await http.post(
      Uri.parse('$baseUrl/content/upload'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': computedTitle, 'text': text}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final docData = decoded['data'] ?? decoded['document'] ?? decoded;
      return Document.fromJson(docData);
    } else {
      throw _parseError(response);
    }
  }

  Future<void> deleteDocument(String documentId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized: No token found');
    final response = await http.delete(
      Uri.parse('$baseUrl/content/$documentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _parseError(response);
    }
  }

  Future<dynamic> summarizeDocument(String documentId) async {
    final token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token found");

    final response = await http.post(
      Uri.parse('$baseUrl/content/$documentId/summarize'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? decoded;
    } else {
      throw _parseError(response);
    }
  }

  Future<List<dynamic>> generateQuiz(String documentId) async {
    final token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token found");

    final response = await http.post(
      Uri.parse('$baseUrl/quiz/generate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'contentId': documentId}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final payload = decoded['data'] ?? decoded;
      if (payload is Map && payload.containsKey('questions')) {
        return payload['questions'] as List<dynamic>;
      } else if (payload is List) {
        return payload;
      }
      return decoded['questions'] ?? [];
    } else {
      throw _parseError(response);
    }
  }

  Future<List<dynamic>> generateFlashcards(String documentId) async {
    final token = await _getToken();
    if (token == null) throw Exception("Unauthorized: No token found");

    final response = await http.post(
      Uri.parse('$baseUrl/flashcards/generate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'contentId': documentId}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final payload = decoded['data'] ?? decoded;
      if (payload is Map && payload.containsKey('flashcards')) {
        return payload['flashcards'] as List<dynamic>;
      } else if (payload is List) {
        return payload;
      }
      return decoded['flashcards'] ?? [];
    } else {
      throw _parseError(response);
    }
  }

  Exception _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      var errorData = data['message'] ?? data['error'] ?? 'An error occurred';
      if (errorData is Map) return Exception(errorData.values.join(', '));
      if (errorData is List) return Exception(errorData.join(', '));
      return Exception(errorData.toString());
    } catch (_) {
      return Exception('Server error (${response.statusCode})');
    }
  }
}
