import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardModel {
  final String id;
  final String front;
  final String back;

  const FlashcardModel({
    required this.id,
    required this.front,
    required this.back,
  });

  factory FlashcardModel.fromMap(Map<String, dynamic> map, {String id = ''}) =>
      FlashcardModel(
        id: id,
        front: map['front']?.toString() ?? '',
        back: map['back']?.toString() ?? '',
      );

  factory FlashcardModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return FlashcardModel(id: doc.id, front: d['front'] ?? '', back: d['back'] ?? '');
  }

  Map<String, dynamic> toFirestore() => {'front': front, 'back': back};
}
