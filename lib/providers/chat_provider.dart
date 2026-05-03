import 'package:flutter/material.dart';
import '../services/cerebras_service.dart';
import '../models/document_model.dart';

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';

  // Legacy compat
  factory ChatMessage.local({
    required String role,
    required String content,
    String? sessionId,
  }) =>
      ChatMessage(role: role, content: content);

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role']?.toString() ?? 'user',
        content: json['content']?.toString() ?? '',
      );
}

// Legacy compat for old ChatSession references in chat_screen
class ChatSession {
  final String id;
  final String title;
  final int messageCount;
  ChatSession({required this.id, required this.title, this.messageCount = 0});
  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? 'Session',
        messageCount: (j['messageCount'] as num?)?.toInt() ?? 0,
      );
}

class ChatProvider with ChangeNotifier {
  final CerebrasService _ai = CerebrasService();

  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _history = []; // for Cerebras API
  bool _isSending = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _streamingContent; // accumulates tokens during streaming

  // Legacy compat
  List<ChatSession> get sessions => [];
  String? get currentSessionId => null;

  List<ChatMessage> get messages => _messages;
  bool get isSending => _isSending;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get streamingContent => _streamingContent;

  // ── Session management ─────────────────────────────────────────────────────

  void startNewSession() {
    _messages.clear();
    _history.clear();
    _streamingContent = null;
    notifyListeners();
  }

  // Legacy compat no-ops
  Future<void> loadSessions() async {}
  Future<void> loadHistory(String id) async {}
  Future<void> deleteSession(String id) async {}

  // ── Send with streaming ────────────────────────────────────────────────────

  Future<void> sendMessage(
    String text, {
    String? studyMaterial,
    List<DocumentModel>? documents,
  }) async {
    if (text.trim().isEmpty || _isSending) return;

    // Build system prompt with RAG context
    final sb = StringBuffer(
        'You are StudyFlow AI, an expert study assistant. '
        'Answer questions clearly and educationally.\n');

    if (studyMaterial != null && studyMaterial.trim().isNotEmpty) {
      final ctx = studyMaterial.length > 25000
          ? studyMaterial.substring(0, 25000)
          : studyMaterial;
      sb.write(
          '\nHere are the user\'s uploaded study materials (use these as primary context). '
          'If the answer is outside this material, use your general knowledge:\n"""\n$ctx\n"""');
    }

    // Add user message to UI and history
    _messages.add(ChatMessage(role: 'user', content: text));
    _history.add({'role': 'user', 'content': text});
    _isSending = true;
    _streamingContent = '';
    notifyListeners();

    // Add placeholder assistant message that will be updated token-by-token
    _messages.add(ChatMessage(role: 'assistant', content: ''));

    try {
      await for (final token
          in _ai.streamChat(_history, systemPrompt: sb.toString())) {
        _streamingContent = (_streamingContent ?? '') + token;
        // Update the last message in-place
        _messages[_messages.length - 1] =
            ChatMessage(role: 'assistant', content: _streamingContent!);
        notifyListeners();
      }

      final finalContent = _streamingContent ?? '';
      _history.add({'role': 'assistant', 'content': finalContent});
    } catch (e) {
      _messages[_messages.length - 1] = ChatMessage(
        role: 'assistant',
        content: '⚠️ ${e.toString().replaceAll("Exception: ", "")}',
      );
    } finally {
      _isSending = false;
      _streamingContent = null;
      notifyListeners();
    }
  }
}
