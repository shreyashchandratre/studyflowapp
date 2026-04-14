import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../services/gemini_ai_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _service = ChatService();
  final GeminiAiService _ai = GeminiAiService();

  List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  String? _currentSessionId;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  List<ChatMessage> get messages => _messages;
  List<ChatSession> get sessions => _sessions;
  String? get currentSessionId => _currentSessionId;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  void _setError(String? v) { _errorMessage = v; notifyListeners(); }

  // ── Sessions (still fetched from backend if available) ─────────────────────

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final raw = await _service.getSessions();
      _sessions = raw.map((s) => ChatSession.fromJson(s as Map<String, dynamic>)).toList();
    } catch (_) {
      _sessions = []; // Sessions are optional — fail silently
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory(String sessionId) async {
    _isLoading = true;
    _currentSessionId = sessionId;
    _messages = [];
    notifyListeners();
    try {
      final raw = await _service.getHistory(sessionId);
      _messages = raw.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startNewSession() {
    _currentSessionId = null;
    _messages = [];
    _ai.startNewChat(); // Reset AI conversation context
    notifyListeners();
  }

  // ── Send message — routed through local AI ─────────────────────────────────

  Future<void> sendMessage(String text, {String? studyMaterial}) async {
    if (text.trim().isEmpty) return;

    // Optimistically show user message
    final userMsg = ChatMessage.local(
      role: 'user',
      content: text,
      sessionId: _currentSessionId,
    );
    _messages.add(userMsg);
    _isSending = true;
    notifyListeners();

    try {
      // Use Cerebras AI directly — bypass broken backend
      final reply = await _ai.sendChatMessage(text, studyMaterialContext: studyMaterial);
      _messages.add(ChatMessage.local(
        role: 'assistant',
        content: reply,
        sessionId: _currentSessionId,
      ));
    } catch (e) {
      _messages.add(ChatMessage.local(
        role: 'assistant',
        content: '⚠️ ${e.toString().replaceAll('Exception: ', '')}',
      ));
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _service.deleteSession(sessionId);
      _sessions.removeWhere((s) => s.id == sessionId);
      if (_currentSessionId == sessionId) startNewSession();
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
