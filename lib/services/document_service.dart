// Legacy document service stub — all document operations now go through
// MaterialsProvider → FirebaseService.
import '../models/document_model.dart';

class DocumentService {
  Future<List<Document>> fetchDocuments() async => [];
  Future<Document> uploadFile(String filePath, {String? filename}) async =>
      throw Exception('Use MaterialsProvider.saveDocument()');
  Future<Document> uploadText(String text, {String? title}) async =>
      throw Exception('Use MaterialsProvider.saveDocument()');
  Future<void> deleteDocument(String documentId) async {}
  Future<dynamic> summarizeDocument(String documentId) async => null;
  Future<List<dynamic>> generateQuiz(String documentId) async => [];
  Future<List<dynamic>> generateFlashcards(String documentId) async => [];
}
