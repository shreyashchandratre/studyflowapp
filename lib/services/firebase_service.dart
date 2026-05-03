import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/document_model.dart';
import '../models/flashcard_model.dart';

/// Single gateway for all Firestore reads/writes.
class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ── User doc ───────────────────────────────────────────────────────────────

  Future<UserModel?> fetchUser(String uid) async {
    try {
      final snap = await _db.collection(AppConstants.colUsers).doc(uid).get();
      if (!snap.exists) return null;
      return UserModel.fromFirestore(snap);
    } catch (e) {
      debugPrint('fetchUser error: $e');
      return null;
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection(AppConstants.colUsers).doc(user.uid).set(
            user.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('createUser error: $e');
    }
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    try {
      await _db.collection(AppConstants.colUsers).doc(_uid).update(data);
    } catch (e) {
      debugPrint('updateUser error: $e');
    }
  }

  // ── Streak & activity ──────────────────────────────────────────────────────

  /// Call on any app activity.  Updates streak and lastActiveDate in Firestore.
  Future<void> touchActivity(UserModel current) async {
    final now = DateTime.now();
    final last = current.lastActiveDate;
    int newStreak = current.streak;

    if (last != null) {
      final daysDiff = now.difference(last).inDays;
      if (daysDiff == 1) {
        newStreak += 1; // consecutive day
      } else if (daysDiff > 1) {
        newStreak = 1; // reset
      }
      // daysDiff == 0 → same day, no change
    } else {
      newStreak = 1;
    }

    try {
      await _db.collection(AppConstants.colUsers).doc(_uid).update({
        'streak': newStreak,
        'lastActiveDate': Timestamp.fromDate(now),
      });
    } catch (e) {
      debugPrint('touchActivity error: $e');
    }
  }

  // ── XP & gamification ─────────────────────────────────────────────────────

  Future<void> addXp(int amount) async {
    try {
      await _db.collection(AppConstants.colUsers).doc(_uid).update({
        'xp': FieldValue.increment(amount),
      });
      await _syncScores();
    } catch (e) {
      debugPrint('addXp error: $e');
    }
  }

  Future<void> recordQuizResult({
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    try {
      final snap = await _db.collection(AppConstants.colUsers).doc(_uid).get();
      final data = snap.data() ?? {};
      final oldCount = (data['quizzesTaken'] as num?)?.toInt() ?? 0;
      final oldAvg = (data['avgAccuracy'] as num?)?.toDouble() ?? 0.0;
      final accuracy = totalQuestions > 0
          ? (correctAnswers / totalQuestions) * 100
          : 0.0;
      final newAvg = oldCount == 0
          ? accuracy
          : ((oldAvg * oldCount) + accuracy) / (oldCount + 1);
      final xpEarned = correctAnswers * AppConstants.xpPerCorrect;

      await _db.collection(AppConstants.colUsers).doc(_uid).update({
        'quizzesTaken': FieldValue.increment(1),
        'avgAccuracy': newAvg,
        'xp': FieldValue.increment(xpEarned),
      });
      await _syncScores();
    } catch (e) {
      debugPrint('recordQuizResult error: $e');
    }
  }

  Future<void> _syncScores() async {
    try {
      final snap = await _db.collection(AppConstants.colUsers).doc(_uid).get();
      final data = snap.data() ?? {};
      await _db.collection(AppConstants.colScores).doc(_uid).set({
        'xp': data['xp'] ?? 0,
        'streak': data['streak'] ?? 0,
        'quizzesTaken': data['quizzesTaken'] ?? 0,
        'avgAccuracy': data['avgAccuracy'] ?? 0.0,
        'username': data['username'] ?? '',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('_syncScores error: $e');
    }
  }

  // ── Documents ──────────────────────────────────────────────────────────────

  Future<List<DocumentModel>> fetchDocuments() async {
    try {
      final snap = await _db
          .collection(AppConstants.colMaterials)
          .doc(_uid)
          .collection(AppConstants.colDocs)
          .orderBy('uploadedAt', descending: true)
          .get();
      return snap.docs.map(DocumentModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('fetchDocuments error: $e');
      return [];
    }
  }

  Future<DocumentModel> saveDocument(
      {required String title, required String rawText}) async {
    try {
      final ref = _db
          .collection(AppConstants.colMaterials)
          .doc(_uid)
          .collection(AppConstants.colDocs)
          .doc();
      final doc = DocumentModel(
        id: ref.id,
        title: title,
        rawText: rawText,
        uploadedAt: DateTime.now(),
      );
      await ref.set(doc.toFirestore());
      return doc;
    } catch (e) {
      debugPrint('saveDocument error: $e');
      rethrow;
    }
  }

  Future<void> deleteDocument(String docId) async {
    try {
      await _db
          .collection(AppConstants.colMaterials)
          .doc(_uid)
          .collection(AppConstants.colDocs)
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint('deleteDocument error: $e');
    }
  }

  Future<void> cacheSummaries(
      String docId, Map<String, String> summaries) async {
    try {
      await _db
          .collection(AppConstants.colMaterials)
          .doc(_uid)
          .collection(AppConstants.colDocs)
          .doc(docId)
          .update({'summaries': summaries});
    } catch (e) {
      debugPrint('cacheSummaries error: $e');
    }
  }

  // ── Flashcards ─────────────────────────────────────────────────────────────

  Future<List<FlashcardModel>> fetchFlashcards(String docId) async {
    try {
      final snap = await _db
          .collection(AppConstants.colMaterials)
          .doc(_uid)
          .collection(AppConstants.colDocs)
          .doc(docId)
          .collection(AppConstants.colFlashcards)
          .get();
      return snap.docs.map(FlashcardModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('fetchFlashcards error: $e');
      return [];
    }
  }

  Future<List<FlashcardModel>> saveFlashcards(
      String docId, List<FlashcardModel> cards) async {
    try {
      final colRef = _db
          .collection(AppConstants.colMaterials)
          .doc(_uid)
          .collection(AppConstants.colDocs)
          .doc(docId)
          .collection(AppConstants.colFlashcards);

      final batch = _db.batch();
      for (final card in cards) {
        final ref = colRef.doc();
        batch.set(ref, card.toFirestore());
      }
      await batch.commit();

      // Return fresh list
      return fetchFlashcards(docId);
    } catch (e) {
      debugPrint('saveFlashcards error: $e');
      return [];
    }
  }

  // ── Leaderboard ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 20}) async {
    try {
      final snap = await _db
          .collection(AppConstants.colScores)
          .orderBy('xp', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => {'uid': d.id, ...d.data()})
          .toList();
    } catch (e) {
      debugPrint('fetchLeaderboard error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchScoreByUsername(String username) async {
    try {
      final snap = await _db
          .collection(AppConstants.colScores)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return {'uid': snap.docs.first.id, ...snap.docs.first.data()};
    } catch (e) {
      debugPrint('fetchScoreByUsername error: $e');
      return null;
    }
  }
}
