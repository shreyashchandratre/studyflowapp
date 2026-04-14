class Document {
  final String id;
  final String title;
  final String? content;
  final String? originalText;
  final List<dynamic>? topics;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.title,
    this.content,
    this.originalText,
    this.topics,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      content: json['content'],
      originalText: json['originalText'],
      topics: (json['topics'] as List?)?.cast<dynamic>(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
