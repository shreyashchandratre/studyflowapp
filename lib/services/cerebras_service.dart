import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// All AI calls go through this single service.
/// - [streamChat]   → yields tokens as they arrive (SSE / streaming)
/// - [complete]     → single-shot completion
class CerebrasService {
  final String _apiKey;

  CerebrasService()
      : _apiKey = const String.fromEnvironment('CEREBRAS_API_KEY', defaultValue: '').isNotEmpty
            ? const String.fromEnvironment('CEREBRAS_API_KEY')
            : dotenv.env['CEREBRAS_API_KEY'] ?? '';

  bool get _hasKey => _apiKey.isNotEmpty && !_apiKey.startsWith('YOUR_');

  // ── Streaming chat ─────────────────────────────────────────────────────────

  /// Streams text tokens from Cerebras for an ongoing conversation.
  /// [history]      → list of {role, content} maps already exchanged
  /// [systemPrompt] → injected as the first system message
  Stream<String> streamChat(
    List<Map<String, String>> history, {
    String systemPrompt = '',
  }) async* {
    if (!_hasKey) {
      yield '⚠️ CEREBRAS_API_KEY not configured. '
          'Run with --dart-define=CEREBRAS_API_KEY=<key>';
      return;
    }

    final messages = [
      if (systemPrompt.isNotEmpty) {'role': 'system', 'content': systemPrompt},
      ...history,
    ];

    final request = http.Request('POST', Uri.parse(AppConstants.cerebrasBaseUrl))
      ..headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      })
      ..body = jsonEncode({
        'model': AppConstants.cerebrasModel,
        'messages': messages,
        'stream': true,
        'max_tokens': 2048,
        'temperature': 0.7,
      });

    try {
      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.stream.bytesToString();
        yield '⚠️ API error (${response.statusCode}): $body';
        client.close();
        return;
      }

      final buffer = StringBuffer();
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer.write(chunk);
        // Process complete SSE lines
        final raw = buffer.toString();
        final lines = raw.split('\n');
        // Keep the last possibly-incomplete line in the buffer
        buffer.clear();
        buffer.write(lines.last);

        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') break;
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final delta = (json['choices'] as List?)
                      ?.firstOrNull?['delta']?['content']
                  as String?;
              if (delta != null && delta.isNotEmpty) yield delta;
            } catch (_) {
              // Skip malformed SSE lines
            }
          }
        }
      }
      client.close();
    } catch (e) {
      yield '⚠️ ${e.toString().replaceAll('Exception: ', '')}';
    }
  }

  // ── Single-shot complete ────────────────────────────────────────────────────

  /// One-shot completion (summaries, quizzes, flashcards).
  Future<String> complete(String prompt, {String? systemPrompt}) async {
    if (!_hasKey) throw Exception('CEREBRAS_API_KEY not configured.');

    final messages = [
      if (systemPrompt != null && systemPrompt.isNotEmpty)
        {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': prompt},
    ];

    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.cerebrasBaseUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': AppConstants.cerebrasModel,
              'messages': messages,
              'max_tokens': 2048,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String? ??
            'No response.';
      } else {
        String errMsg = 'AI request failed (${response.statusCode})';
        try {
          final err = jsonDecode(response.body);
          errMsg = err['error']?['message'] ?? errMsg;
        } catch (_) {}
        throw Exception(errMsg);
      }
    } catch (e) {
      if (e is TimeoutException) throw Exception('Request timed out. Try again.');
      rethrow;
    }
  }

  // ── Convenience helpers ────────────────────────────────────────────────────

  /// Parse a JSON list out of a raw LLM response (strips markdown fences).
  static List<Map<String, dynamic>> parseJsonList(String raw) {
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
    } catch (e) {
      debugPrint('parseJsonList error: $e');
    }
    return [];
  }

  /// Parse a JSON object out of a raw LLM response.
  static Map<String, dynamic> parseJsonObject(String raw) {
    try {
      final cleaned = raw
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start == -1 || end <= start) return {};
      return jsonDecode(cleaned.substring(start, end + 1))
          as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
