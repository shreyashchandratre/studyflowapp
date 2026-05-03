import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final int xp;
  final int streak;
  final int quizzesTaken;
  final double avgAccuracy;
  final DateTime? lastActiveDate;

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.xp = 0,
    this.streak = 0,
    this.quizzesTaken = 0,
    this.avgAccuracy = 0.0,
    this.lastActiveDate,
  });

  int get level => (xp ~/ 500) + 1;
  double get xpProgress => (xp % 500) / 500.0;
  int get xpToNextLevel => 500 - (xp % 500);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      username: d['username']?.toString() ?? '',
      email: d['email']?.toString() ?? '',
      xp: (d['xp'] as num?)?.toInt() ?? 0,
      streak: (d['streak'] as num?)?.toInt() ?? 0,
      quizzesTaken: (d['quizzesTaken'] as num?)?.toInt() ?? 0,
      avgAccuracy: (d['avgAccuracy'] as num?)?.toDouble() ?? 0.0,
      lastActiveDate: d['lastActiveDate'] != null
          ? (d['lastActiveDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'username': username,
        'email': email,
        'xp': xp,
        'streak': streak,
        'quizzesTaken': quizzesTaken,
        'avgAccuracy': avgAccuracy,
        'lastActiveDate': lastActiveDate != null
            ? Timestamp.fromDate(lastActiveDate!)
            : null,
      };

  UserModel copyWith({
    String? username,
    String? email,
    int? xp,
    int? streak,
    int? quizzesTaken,
    double? avgAccuracy,
    DateTime? lastActiveDate,
  }) =>
      UserModel(
        uid: uid,
        username: username ?? this.username,
        email: email ?? this.email,
        xp: xp ?? this.xp,
        streak: streak ?? this.streak,
        quizzesTaken: quizzesTaken ?? this.quizzesTaken,
        avgAccuracy: avgAccuracy ?? this.avgAccuracy,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      );
}
