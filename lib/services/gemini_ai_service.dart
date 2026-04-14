import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AI service using the Cerebras Cloud API (OpenAI-compatible format).
/// Works with any csk-... key from https://cloud.cerebras.ai
class GeminiAiService {
  final String _apiKey;
  final String _model;

  static const String _baseUrl = 'https://api.cerebras.ai/v1/chat/completions';

  // Conversation history for chat sessions
  final List<Map<String, String>> _chatHistory = [];

  GeminiAiService({
    String? apiKey,
    String? model,
  })  : _apiKey = apiKey ?? dotenv.env['CEREBRAS_API_KEY'] ?? '',
        _model = model ?? _kModel;

  // ---------------------------------------------------------------------------
  // 🔑 Credentials
  // ---------------------------------------------------------------------------
  static const String _kModel = 'llama3.1-8b';

  bool get _hasValidKey => _apiKey.isNotEmpty && !_apiKey.startsWith('YOUR_');

  // ---------------------------------------------------------------------------
  // Core API call
  // ---------------------------------------------------------------------------

  Future<String> _complete(List<Map<String, String>> messages) async {
    if (!_hasValidKey) {
      throw Exception('API key not configured.');
    }

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            'max_tokens': 2048,
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String? ??
          'No response from AI.';
    } else {
      String errMsg = 'AI request failed (${response.statusCode})';
      try {
        final errData = jsonDecode(response.body);
        errMsg = errData['error']?['message'] ?? errMsg;
      } catch (_) {}
      throw Exception(errMsg);
    }
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  static const String _systemPrompt =
      'You are StudyFlow AI, an expert study assistant. '
      'Help students understand concepts, summarize notes, explain difficult topics, '
      'and create study plans. Keep responses concise, friendly, and educational.';

  void startNewChat() => _chatHistory.clear();

  Future<String> sendChatMessage(String userMessage, {String? studyMaterialContext}) async {
    if (!_hasValidKey) {
      return '⚠️ AI key not configured. '
          'Open lib/services/gemini_ai_service.dart and set _kApiKey.';
    }
    try {
      _chatHistory.add({'role': 'user', 'content': userMessage});

      String currentSystemPrompt = _systemPrompt;
      if (studyMaterialContext != null && studyMaterialContext.trim().isNotEmpty) {
        currentSystemPrompt += '\n\nHere are the user\'s uploaded study materials to use as context (if relevant). If the external knowledge is out of scope of these documents, use your general knowledge to answer:\n"""\n';
        
        // Truncate study material to avoid easily exceeding token limits
        if (studyMaterialContext.length > 25000) {
          currentSystemPrompt += '${studyMaterialContext.substring(0, 25000)}...\n"""';
        } else {
          currentSystemPrompt += '$studyMaterialContext\n"""';
        }
      }

      final messages = [
        {'role': 'system', 'content': currentSystemPrompt},
        ..._chatHistory,
      ];

      final reply = await _complete(messages);
      _chatHistory.add({'role': 'assistant', 'content': reply});
      return reply;
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '');
      if (_chatHistory.isNotEmpty) _chatHistory.removeLast(); // remove failed user message
      return '⚠️ $err';
    }
  }

  // ---------------------------------------------------------------------------
  // Summarise
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> generateSummaries(String text) async {
    if (!_hasValidKey) {
      throw Exception('AI key not configured. Open lib/services/gemini_ai_service.dart and set _kApiKey.');
    }
    try {
      final content = text.length > 12000
          ? '${text.substring(0, 12000)}...(truncated)'
          : text;

      final raw = await _complete([
        {'role': 'system', 'content': 'You are an expert study assistant. Return ONLY a valid JSON object. No markdown, no explanations.'},
        {
          'role': 'user',
          'content': '''Read the document and generate three different summary lengths.
Return EXACTLY this JSON format:
{
  "brief": "A 1-2 sentence quick overview.",
  "detailed": "A medium-length summary covering the key points in 2-3 paragraphs.",
  "comprehensive": "A deeply comprehensive outline using bullet points."
}

Document:
"""
$content
"""'''
        },
      ]);

      final cleaned = raw
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start != -1 && end > start) {
        final decoded = jsonDecode(cleaned.substring(start, end + 1));
        if (decoded is Map) {
          return {
            'brief': decoded['brief']?.toString() ?? 'Brief summary failed.',
            'detailed': decoded['detailed']?.toString() ?? 'Detailed summary failed.',
            'comprehensive': decoded['comprehensive']?.toString() ?? 'Comprehensive summary failed.',
          };
        }
      }
      throw Exception('Invalid JSON structure from AI');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ---------------------------------------------------------------------------
  // Quiz
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> generateQuiz(String text,
      {int count = 5}) async {
    if (!_hasValidKey) return [];
    try {
      final content =
          text.length > 8000 ? '${text.substring(0, 8000)}...' : text;

      final raw = await _complete([
        {'role': 'system', 'content': 'You generate JSON quiz data. Return ONLY raw JSON arrays with no markdown or explanation.'},
        {
          'role': 'user',
          'content': '''Generate exactly $count multiple-choice quiz questions from this content.
Return ONLY a JSON array — no markdown, no extra text.

[
  {
    "question": "Question text?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "answer": "Option A",
    "explanation": "Why this answer is correct."
  }
]

Content:
"""
$content
"""'''
        },
      ]);
      return _parseList(raw);
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Flashcards
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> generateFlashcards(String text,
      {int count = 8}) async {
    if (!_hasValidKey) return [];
    try {
      final content =
          text.length > 8000 ? '${text.substring(0, 8000)}...' : text;

      final raw = await _complete([
        {'role': 'system', 'content': 'You generate JSON flashcard data. Return ONLY raw JSON arrays with no markdown or explanation.'},
        {
          'role': 'user',
          'content': '''Generate exactly $count flashcards from this content.
Return ONLY a JSON array — no markdown, no extra text.

[
  {
    "front": "Concept or question",
    "back": "Answer or definition"
  }
]

Content:
"""
$content
"""'''
        },
      ]);
      return _parseList(raw);
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // JSON helper
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _parseList(String raw) {
    try {
      final cleaned = raw
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final start = cleaned.indexOf('[');
      final end = cleaned.lastIndexOf(']');
      if (start == -1 || end <= start) return [];
      final decoded = jsonDecode(cleaned.substring(start, end + 1));
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
