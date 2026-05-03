import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _fb = FirebaseService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Legacy compat
  Map<String, dynamic>? get user => _userModel != null
      ? {'name': _userModel!.username, 'username': _userModel!.username}
      : null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      _userModel = await _fb.fetchUser(user.uid);
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? v) { _errorMessage = v; notifyListeners(); }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_authMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = UserModel(
        uid: cred.user!.uid,
        username: username,
        email: email,
        lastActiveDate: DateTime.now(),
        streak: 1,
      );
      await _fb.createUser(user);
      _userModel = user;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_authMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  // Auth status check (for backward compat)
  Future<void> checkAuthStatus() async {}

  String _authMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'Email is already registered.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      case 'operation-not-allowed': return 'Email/Password auth is not enabled in Firebase Console.';
      default: return 'Authentication failed ($code). Please try again.';
    }
  }
}
