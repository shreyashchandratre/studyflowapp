import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';
import '../services/gemini_ai_service.dart';

class DocumentProvider with ChangeNotifier {
  final DocumentService _documentService = DocumentService();
  final GeminiAiService _ai = GeminiAiService();

  List<Document> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, dynamic> _summaryCache = {};

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? v) { _errorMessage = v; notifyListeners(); }

  // ── Fetch documents list ────────────────────────────────────────────────────

  Future<void> fetchDocuments() async {
    _setLoading(true);
    _setError(null);
    try {
      _documents = await _documentService.fetchDocuments();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  // ── Upload ──────────────────────────────────────────────────────────────────

  Future<Document?> uploadFile(String filePath, {String? filename}) async {
    try {
      final newDoc = await _documentService.uploadFile(filePath, filename: filename);
      _documents.insert(0, newDoc);
      notifyListeners();
      return newDoc;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  Future<Document?> uploadText(String text, {String? title}) async {
    try {
      final newDoc = await _documentService.uploadText(text, title: title);
      _documents.insert(0, newDoc);
      notifyListeners();
      return newDoc;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _documentService.deleteDocument(documentId);
      _documents.removeWhere((d) => d.id == documentId);
      _summaryCache.remove(documentId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Returns the stored text for a document (prefers originalText, falls back to content/title).
  String _docText(String documentId) {
    final doc = _documents.firstWhere(
      (d) => d.id == documentId,
      orElse: () => Document(id: '', title: 'Unknown', createdAt: DateTime.now()),
    );
    return doc.originalText?.trim().isNotEmpty == true
        ? doc.originalText!
        : doc.content?.trim().isNotEmpty == true
            ? doc.content!
            : doc.title;
  }

  // ── Summarise — powered by local Cerebras AI ───────────────────────────────

  /// Clears the cached summary so it will be regenerated on next call.
  void clearSummaryCache(String documentId) {
    _summaryCache.remove(documentId);
  }

  /// Returns a Map compatible with the old backend shape so that
  /// ContentDetailScreen and SummaryBottomSheet can use brief/detailed/comprehensive.
  Future<Map<String, dynamic>?> getRawSummary(String documentId) async {
    try {
      if (_summaryCache.containsKey(documentId)) {
        return {
          'summaries': _summaryCache[documentId],
          'topics': [],
        };
      }
      final text = _docText(documentId);
      final summariesMap = await _ai.generateSummaries(text);
      _summaryCache[documentId] = summariesMap;
      notifyListeners();
      return {
        'summaries': summariesMap,
        'topics': [],
      };
    } catch (e) {
      return null;
    }
  }

  Future<String?> getSummary(String documentId) async {
    try {
      if (_summaryCache.containsKey(documentId)) {
        final cached = _summaryCache[documentId];
        if (cached is Map) return cached['detailed']?.toString();
        return cached.toString();
      }
      final text = _docText(documentId);
      final summariesMap = await _ai.generateSummaries(text);
      _summaryCache[documentId] = summariesMap;
      notifyListeners();
      return summariesMap['detailed']?.toString();
    } catch (e) {
      return 'Error: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }

  // ── Quiz — powered by local Gemini AI ──────────────────────────────────────

  Future<List<dynamic>?> generateQuiz(String documentId) async {
    _setLoading(true);
    _setError(null);
    try {
      final text = _docText(documentId);
      final quiz = await _ai.generateQuiz(text);
      return quiz.isEmpty ? null : quiz;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ── Flashcards — powered by local Gemini AI ────────────────────────────────

  Future<List<dynamic>?> generateFlashcards(String documentId) async {
    _setLoading(true);
    _setError(null);
    try {
      final text = _docText(documentId);
      final cards = await _ai.generateFlashcards(text);
      return cards.isEmpty ? null : cards;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      _setLoading(false);
    }
  }
}
