import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/l10n/strings.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthService? auth, FirestoreService? db})
      : _auth = auth ?? AuthService.instance,
        _db = db ?? FirestoreService.instance;

  final AuthService _auth;
  final FirestoreService _db;

  bool isLoading = false;
  bool isSigningUp = false; // keeps the gate on the auth screen until the name is saved
  String? error;
  String? info;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userChanges => _auth.userChanges;

  Future<void> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return _fail(S.t('err_creds'));
    }
    _start();
    final String? err = await _auth.signIn(email: email, password: password);
    _finish(err);
  }

  Future<void> signUp(String name, String email, String password) async {
    if (name.trim().isEmpty) return _fail(S.t('err_name'));
    if (email.trim().isEmpty || password.isEmpty) {
      return _fail(S.t('err_creds'));
    }
    _start();
    isSigningUp = true;
    final String? err = await _auth.signUp(name: name, email: email, password: password);
    final User? user = _auth.currentUser;
    if (err == null && user != null) _db.saveProfile(user.uid, name);
    isSigningUp = false;
    _finish(err);
  }

  Future<void> resetPassword(String email) async {
    if (email.trim().isEmpty) {
      return _fail(S.t('err_reset_email'));
    }
    _start();
    final String? err = await _auth.sendPasswordReset(email);
    isLoading = false;
    error = err;
    info = err == null ? S.t('reset_sent') : null;
    notifyListeners();
  }

  /// For users who signed in but have no name yet.
  Future<void> saveName(String name) async {
    if (name.trim().isEmpty) return _fail(S.t('err_name'));
    _start();
    final bool ok = await _auth.updateName(name);
    final User? user = _auth.currentUser;
    if (ok && user != null) _db.saveProfile(user.uid, name);
    _finish(ok ? null : S.t('err_save_name'));
  }

  void _start() {
    isLoading = true;
    error = null;
    info = null;
    notifyListeners();
  }

  void _finish(String? err) {
    isLoading = false;
    error = err;
    notifyListeners();
  }

  void _fail(String message) {
    error = message;
    info = null;
    notifyListeners();
  }
}
