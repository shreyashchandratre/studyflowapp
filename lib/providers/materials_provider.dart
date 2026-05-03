import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/cerebras_service.dart';
import '../models/document_model.dart';
import '../models/flashcard_model.dart';
import '../core/constants.dart';

class MaterialsProvider with ChangeNotifier {
  final FirebaseService _fb = FirebaseService();
  final CerebrasService _ai = CerebrasService();

  List<DocumentModel> _documents = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  final Map<String, Map<String, String>> _summaryCache = {};
  final Map<String, List<FlashcardModel>> _flashcardCache = {};

  List<DocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? v) { _errorMessage = v; notifyListeners(); }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> fetchDocuments() async {
    _setLoading(true);
    _setError(null);
    try {
      _documents = await _fb.fetchDocuments();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  // ── Upload ─────────────────────────────────────────────────────────────────

  Future<DocumentModel?> saveDocument({
    required String title,
    required String rawText,
  }) async {
    _isUploading = true;
    _setError(null);
    notifyListeners();
    try {
      final doc = await _fb.saveDocument(title: title, rawText: rawText);
      _documents.insert(0, doc);
      // Award upload XP
      await _fb.addXp(AppConstants.xpUpload);
      notifyListeners();
      return doc;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDocument(String docId) async {
    try {
      await _fb.deleteDocument(docId);
      _documents.removeWhere((d) => d.id == docId);
      _summaryCache.remove(docId);
      _flashcardCache.remove(docId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Summaries ──────────────────────────────────────────────────────────────

  Future<Map<String, String>> getSummaries(String docId) async {
    if (_summaryCache.containsKey(docId)) return _summaryCache[docId]!;

    // Check Firestore cache first
    final doc = _documents.firstWhere(
      (d) => d.id == docId,
      orElse: () => DocumentModel(
          id: '', title: '', rawText: '', uploadedAt: DateTime.now()),
    );
    if (doc.summaries != null && doc.summaries!.isNotEmpty) {
      _summaryCache[docId] = doc.summaries!;
      return doc.summaries!;
    }

    final text = doc.rawText.trim().isEmpty ? doc.title : doc.rawText;
    final content =
        text.length > 12000 ? '${text.substring(0, 12000)}...' : text;

    final raw = await _ai.complete(
      '''Generate three summaries of the document below.
Return ONLY this JSON object — no markdown, no explanation:
{
  "brief": "3-5 bullet points overview",
  "detailed": "2-3 structured paragraphs covering all key points",
  "comprehensive": "Full study notes with headings, sub-points, and key takeaways"
}

Document:
"""
$content
"""''',
      systemPrompt:
          'You are an expert study assistant. Return ONLY valid JSON.',
    );

    final parsed = CerebrasService.parseJsonObject(raw);
    final summaries = {
      'brief': parsed['brief']?.toString() ?? 'Could not generate brief summary.',
      'detailed': parsed['detailed']?.toString() ?? 'Could not generate detailed summary.',
      'comprehensive': parsed['comprehensive']?.toString() ?? 'Could not generate comprehensive summary.',
    };

    _summaryCache[docId] = summaries;
    // Cache to Firestore in background
    _fb.cacheSummaries(docId, summaries).ignore();
    notifyListeners();
    return summaries;
  }

  // ── Flashcards ─────────────────────────────────────────────────────────────

  Future<List<FlashcardModel>> generateFlashcards(String docId) async {
    // Check local cache
    if (_flashcardCache.containsKey(docId) &&
        _flashcardCache[docId]!.isNotEmpty) {
      return _flashcardCache[docId]!;
    }

    // Check Firestore
    final existing = await _fb.fetchFlashcards(docId);
    if (existing.isNotEmpty) {
      _flashcardCache[docId] = existing;
      notifyListeners();
      return existing;
    }

    // Generate fresh
    final doc = _documents.firstWhere((d) => d.id == docId,
        orElse: () => DocumentModel(
            id: '', title: '', rawText: '', uploadedAt: DateTime.now()));
    final text = doc.rawText.trim().isEmpty ? doc.title : doc.rawText;
    final content =
        text.length > 8000 ? '${text.substring(0, 8000)}...' : text;

    final raw = await _ai.complete(
      '''Generate exactly ${AppConstants.flashcardCount} flashcards from the content below.
Return ONLY a JSON array — no markdown, no extra text:
[{"front": "concept or question", "back": "answer or definition"}]

Content:
"""
$content
"""''',
      systemPrompt:
          'You generate JSON flashcard data. Return ONLY raw JSON arrays.',
    );

    final parsed = CerebrasService.parseJsonList(raw);
    final cards = parsed
        .map((m) => FlashcardModel.fromMap(m))
        .where((c) => c.front.isNotEmpty && c.back.isNotEmpty)
        .toList();

    if (cards.isNotEmpty) {
      final saved = await _fb.saveFlashcards(docId, cards);
      _flashcardCache[docId] = saved;
      await _fb.addXp(AppConstants.xpFlashcard);
      notifyListeners();
      return saved;
    }
    return [];
  }

  // ── Quiz ───────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>?> generateQuiz(String docId) async {
    _setLoading(true);
    _setError(null);
    try {
      final doc = _documents.firstWhere((d) => d.id == docId,
          orElse: () => DocumentModel(
              id: '', title: '', rawText: '', uploadedAt: DateTime.now()));
      final text = doc.rawText.trim().isEmpty ? doc.title : doc.rawText;
      final content =
          text.length > 8000 ? '${text.substring(0, 8000)}...' : text;

      final raw = await _ai.complete(
        '''Generate exactly ${AppConstants.quizCount} multiple-choice quiz questions from this content.
Return ONLY a JSON array — no markdown, no extra text:
[{
  "question": "Question text?",
  "options": ["Option A", "Option B", "Option C", "Option D"],
  "answer": "Option A",
  "explanation": "Why this answer is correct."
}]

Content:
"""
$content
"""''',
        systemPrompt:
            'You generate JSON quiz data. Return ONLY raw JSON arrays.',
      );

      final parsed = CerebrasService.parseJsonList(raw);
      return parsed.isEmpty ? null : parsed;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ── Legacy compat ──────────────────────────────────────────────────────────

  String _docText(String documentId) {
    final doc = _documents.firstWhere(
      (d) => d.id == documentId,
      orElse: () => DocumentModel(
          id: '', title: 'Unknown', rawText: '', uploadedAt: DateTime.now()),
    );
    return doc.rawText.trim().isNotEmpty ? doc.rawText : doc.title;
  }

  Future<Map<String, dynamic>?> getRawSummary(String documentId) async {
    try {
      final sums = await getSummaries(documentId);
      return {'summaries': sums, 'topics': []};
    } catch (_) {
      return null;
    }
  }

  Future<String?> getSummary(String documentId) async {
    try {
      final sums = await getSummaries(documentId);
      return sums['detailed'];
    } catch (_) {
      return null;
    }
  }

  void clearSummaryCache(String documentId) {
    _summaryCache.remove(documentId);
  }

  // upload wrappers used by old UploadBottomSheet
  Future<DocumentModel?> uploadFile(String filePath, {String? filename}) async {
    return null; // handled by new flow via saveDocument
  }

  Future<DocumentModel?> uploadText(String text, {String? title}) async {
    return saveDocument(
      title: title ?? 'Text Note - ${DateTime.now().toIso8601String().substring(0, 10)}',
      rawText: text,
    );
  }
}

/// Backward-compat typedef so screens using DocumentProvider still compile.
typedef DocumentProvider = MaterialsProvider;
