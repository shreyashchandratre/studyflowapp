class UserStats {
  final String id;
  final String name;
  final String username;
  final String email;
  final int xp;
  final int streak;
  final int quizzesTaken;
  final double avgAccuracy;
  final int studyHours;
  final int topicsStudied;
  final int topicsMastered;
  final int longestStreak;
  final double avgQuizScore;
  final DateTime memberSince;
  final int followersCount;
  final int followingCount;
  final List<dynamic> followers;
  final List<dynamic> following;

  UserStats({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.xp,
    required this.streak,
    required this.quizzesTaken,
    required this.avgAccuracy,
    required this.studyHours,
    required this.topicsStudied,
    required this.topicsMastered,
    required this.longestStreak,
    required this.avgQuizScore,
    required this.memberSince,
    required this.followersCount,
    required this.followingCount,
    required this.followers,
    required this.following,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    // The backend may wrap data inside a 'data' key
    final d = json['data'] ?? json;

    num _n(String key) {
      final v = d[key];
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
      return 0;
    }

    return UserStats(
      id: d['_id']?.toString() ?? d['id']?.toString() ?? '',
      name: d['name']?.toString() ?? '',
      username: d['username']?.toString() ?? '',
      email: d['email']?.toString() ?? '',
      xp: _n('xp').toInt(),
      streak: _n('streak').toInt(),
      quizzesTaken: _n('quizzesTaken').toInt(),
      avgAccuracy: _n('avgAccuracy').toDouble(),
      studyHours: _n('studyHours').toInt(),
      topicsStudied: _n('topicsStudied').toInt(),
      topicsMastered: _n('topicsMastered').toInt(),
      longestStreak: _n('longestStreak').toInt(),
      avgQuizScore: _n('avgQuizScore').toDouble(),
      memberSince: d['createdAt'] != null
          ? DateTime.tryParse(d['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      followersCount: (d['followers'] as List?)?.length ?? _n('followersCount').toInt(),
      followingCount: (d['following'] as List?)?.length ?? _n('followingCount').toInt(),
      followers: (d['followers'] as List?) ?? [],
      following: (d['following'] as List?) ?? [],
    );
  }
}
