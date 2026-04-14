import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_stats_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _service = UserService();

  UserStats? _myProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Local XP tracking (persisted via SharedPreferences)
  int _localXp = 0;
  int _localQuizzesTaken = 0;
  static const String _xpKey = 'studyflow_local_xp';
  static const String _quizzesKey = 'studyflow_local_quizzes';

  // Compare
  Map<String, dynamic>? _compareResult;
  bool _isComparing = false;

  // Search
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  // Leaderboard
  List<dynamic> _leaderboard = [];

  UserStats? get myProfile {
    if (_myProfile == null) return null;
    // Merge local XP + quiz count on top of backend values
    return UserStats(
      id: _myProfile!.id,
      name: _myProfile!.name,
      username: _myProfile!.username,
      email: _myProfile!.email,
      xp: _myProfile!.xp + _localXp,
      streak: _myProfile!.streak,
      quizzesTaken: _myProfile!.quizzesTaken + _localQuizzesTaken,
      avgAccuracy: _myProfile!.avgAccuracy,
      studyHours: _myProfile!.studyHours,
      topicsStudied: _myProfile!.topicsStudied,
      topicsMastered: _myProfile!.topicsMastered,
      longestStreak: _myProfile!.longestStreak,
      avgQuizScore: _myProfile!.avgQuizScore,
      memberSince: _myProfile!.memberSince,
      followersCount: _myProfile!.followersCount,
      followingCount: _myProfile!.followingCount,
      followers: _myProfile!.followers,
      following: _myProfile!.following,
    );
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get compareResult => _compareResult;
  bool get isComparing => _isComparing;
  List<dynamic> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  List<dynamic> get leaderboard => _leaderboard;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? v) { _errorMessage = v; notifyListeners(); }

  UserProvider() {
    _loadLocalStats();
  }

  // ── Local XP persistence ───────────────────────────────────────────────────

  Future<void> _loadLocalStats() async {
    final prefs = await SharedPreferences.getInstance();
    _localXp = prefs.getInt(_xpKey) ?? 0;
    _localQuizzesTaken = prefs.getInt(_quizzesKey) ?? 0;
    notifyListeners();
  }

  /// Award XP locally (+5 for upload, quiz, flashcard)
  Future<void> addXp(int amount) async {
    _localXp += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, _localXp);
    notifyListeners();
  }

  /// Track a quiz completion locally
  Future<void> incrementQuizzesTaken() async {
    _localQuizzesTaken += 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quizzesKey, _localQuizzesTaken);
    notifyListeners();
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  Future<void> loadMyProfile() async {
    _setLoading(true);
    _setError(null);
    try {
      final raw = await _service.getMyProfile();
      _myProfile = UserStats.fromJson(raw);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadLeaderboard() async {
    try {
      _leaderboard = await _service.getLeaderboard();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> compare(String username) async {
    _isComparing = true;
    _compareResult = null;
    notifyListeners();
    try {
      final raw = await _service.compareWithUser(username);
      _compareResult = raw['data'] ?? raw;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isComparing = false;
      notifyListeners();
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    try {
      _searchResults = await _service.searchUsers(query);
    } catch (_) {
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> follow(String userId) async {
    try {
      await _service.followUser(userId);
      await loadMyProfile();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> unfollow(String userId) async {
    try {
      await _service.unfollowUser(userId);
      await loadMyProfile();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
