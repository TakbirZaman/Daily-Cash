import 'package:firebase_auth/firebase_auth.dart';

import '../core/l10n/strings.dart';

/// Firebase Auth keeps the session on-device, so users stay logged in
/// until they explicitly sign out. All methods return an error message
/// (null = success) and never throw.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userChanges => _auth.userChanges();

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e.code);
    } catch (_) {
      return S.t('e_generic');
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e.code);
    } catch (_) {
      return S.t('e_generic');
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e.code);
    } catch (_) {
      return S.t('e_generic');
    }
  }

  Future<bool> updateName(String name) async {
    try {
      await _auth.currentUser?.updateDisplayName(name.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  String _friendly(String code) {
    switch (code) {
      case 'email-already-in-use':
        return S.t('e_exists');
      case 'invalid-email':
        return S.t('e_email');
      case 'weak-password':
        return S.t('e_weak');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return S.t('e_wrong');
      case 'network-request-failed':
        return S.t('e_network');
      case 'too-many-requests':
        return S.t('e_many');
      default:
        return S.t('e_generic');
    }
  }
}
