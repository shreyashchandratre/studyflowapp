import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String title;
  final String rawText;
  final DateTime uploadedAt;
  final Map<String, String>? summaries; // brief / detailed / comprehensive

  // Legacy aliases so existing screens still compile
  String? get content => rawText;
  String? get originalText => rawText;
  List<dynamic>? get topics => null;
  DateTime get createdAt => uploadedAt;

  const DocumentModel({
    required this.id,
    required this.title,
    required this.rawText,
    required this.uploadedAt,
    this.summaries,
  });

  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    Map<String, String>? sums;
    if (d['summaries'] is Map) {
      sums = Map<String, String>.from(d['summaries'] as Map);
    }
    return DocumentModel(
      id: doc.id,
      title: d['title']?.toString() ?? 'Untitled',
      rawText: d['rawText']?.toString() ?? '',
      uploadedAt: d['uploadedAt'] != null
          ? (d['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
      summaries: sums,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'rawText': rawText,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        if (summaries != null) 'summaries': summaries,
      };

  DocumentModel copyWith({Map<String, String>? summaries}) => DocumentModel(
        id: id,
        title: title,
        rawText: rawText,
        uploadedAt: uploadedAt,
        summaries: summaries ?? this.summaries,
      );
}

/// Backward-compat alias so old screens using `Document` still compile.
typedef Document = DocumentModel;
