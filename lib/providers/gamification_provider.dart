import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class GamificationProvider with ChangeNotifier {
  final FirebaseService _fb = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _user;
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = false;
  bool _isLoadingLeaderboard = false;
  String? _errorMessage;
  Map<String, dynamic>? _compareResult;
  bool _isComparing = false;

  UserModel? get user => _user;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get compareResult => _compareResult;
  bool get isComparing => _isComparing;

  // Legacy compat
  UserModel? get myProfile => _user;
  bool get isSearching => false;
  List<dynamic> get searchResults => [];

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }

  // ── Load user ──────────────────────────────────────────────────────────────

  Future<void> loadMyProfile() async {
    _setLoading(true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      _user = await _fb.fetchUser(uid);
      if (_user != null) {
        await _fb.touchActivity(_user!);
        // Refresh after touching
        _user = await _fb.fetchUser(uid);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      _user = await _fb.fetchUser(uid);
      notifyListeners();
    } catch (_) {}
  }

  // ── Leaderboard ────────────────────────────────────────────────────────────

  Future<void> loadLeaderboard() async {
    _isLoadingLeaderboard = true;
    notifyListeners();
    try {
      _leaderboard = await _fb.fetchLeaderboard(limit: 20);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  // ── Compare ────────────────────────────────────────────────────────────────

  Future<void> compareByUsername(String username) async {
    _isComparing = true;
    _compareResult = null;
    notifyListeners();
    try {
      final them = await _fb.fetchScoreByUsername(username);
      _compareResult = {
        'currentUser': _user?.toFirestore() ?? {},
        'comparedUser': them,
      };
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isComparing = false;
      notifyListeners();
    }
  }

  // ── Legacy compat wrappers used by existing screens ────────────────────────

  Future<void> addXp(int amount) => _fb.addXp(amount);
  Future<void> incrementQuizzesTaken() async {} // handled by recordQuizResult
  Future<void> compare(String username) => compareByUsername(username);
  Future<void> searchUsers(String q) async {}
}

/// Backward-compat typedef so old UserProvider references still compile.
typedef UserProvider = GamificationProvider;
