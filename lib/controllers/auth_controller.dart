import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../core/l10n/strings.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthService? auth}) : _auth = auth ?? AuthService.instance;

  final AuthService _auth;

  bool isLoading = false;
  bool isSigningUp = false; // keeps the gate on the auth screen until sign up finishes
  String? error;
  String? info;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userChanges => _auth.userChanges;

  Future<void> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) return _fail(S.t('err_creds'));
    _start();
    final String? err = await _auth.signIn(email: email, password: password);
    _finish(err);
  }

  Future<void> signUp(String name, String email, String password) async {
    if (name.trim().isEmpty) return _fail(S.t('err_name'));
    if (email.trim().isEmpty || password.isEmpty) return _fail(S.t('err_creds'));
    _start();
    isSigningUp = true;
    final String? err = await _auth.signUp(name: name, email: email, password: password);
    isSigningUp = false;
    _finish(err);
  }

  /// For signed in users who have no name yet.
  Future<void> saveName(String name) async {
    if (name.trim().isEmpty) return _fail(S.t('err_name'));
    _start();
    final bool ok = await _auth.updateName(name);
    _finish(ok ? null : S.t('err_save_name'));
  }

  /// Sends the reset code. Returns true when the code screen should open.
  Future<bool> sendResetCode(String email) async {
    if (email.trim().isEmpty) {
      _fail(S.t('err_reset_email'));
      return false;
    }
    _start();
    final String? err = await _auth.sendPasswordReset(email);
    isLoading = false;
    error = err;
    info = err == null ? S.t('reset_sent') : null;
    notifyListeners();
    return err == null;
  }

  /// Returns an error message, or null when the password was changed and the user is in.
  Future<String?> confirmReset(String email, String code, String password) async {
    if (code.trim().isEmpty) return S.t('e_code');
    if (password.length < 6) return S.t('e_weak');
    return _auth.confirmReset(email: email, code: code, newPassword: password);
  }

  void clearMessages() {
    error = null;
    info = null;
    notifyListeners();
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
