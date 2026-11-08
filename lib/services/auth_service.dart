import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthResponse, AuthState, OtpType, Supabase, SupabaseClient, User, UserAttributes;

import '../core/l10n/strings.dart';

/// Supabase keeps the session on the device, so users stay logged in until they
/// explicitly sign out. Methods return an error message (null = success) and never throw.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<User?> get userChanges =>
      _client.auth.onAuthStateChange.map((AuthState s) => s.session?.user);

  /// The name saved at sign up, kept in the account's metadata.
  static String nameOf(User? user) {
    final Object? n = user?.userMetadata?['name'];
    return n is String ? n.trim() : '';
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{'name': name.trim()},
      );
      // No session means the project still asks for email confirmation.
      if (res.session == null) return S.t('e_confirm');
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email.trim(), password: password);
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  Future<bool> updateName(String name) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(data: <String, dynamic>{'name': name.trim()}),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Step 1 of a password reset: Supabase emails a 6 digit code.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  /// Step 2: the code proves the email, then the new password is saved.
  Future<String?> confirmReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: OtpType.recovery,
      );
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  String _friendly(Object e) {
    final String m = (e is AuthException ? e.message : e.toString()).toLowerCase();
    if (m.contains('already') && m.contains('registered')) return S.t('e_exists');
    if (m.contains('not confirmed')) return S.t('e_confirm');
    if (m.contains('invalid login') || m.contains('invalid credentials')) return S.t('e_wrong');
    if (m.contains('token') && (m.contains('expired') || m.contains('invalid'))) {
      return S.t('e_code');
    }
    if (m.contains('password') && (m.contains('at least') || m.contains('weak'))) {
      return S.t('e_weak');
    }
    if (m.contains('rate limit') || m.contains('too many') || m.contains('seconds')) {
      return S.t('e_many');
    }
    if (m.contains('socket') ||
        m.contains('host lookup') ||
        m.contains('network') ||
        m.contains('connection') ||
        m.contains('clientexception') ||
        m.contains('retryable')) {
      return S.t('e_network');
    }
    if (m.contains('email') && m.contains('invalid')) return S.t('e_email');
    return S.t('e_generic');
  }
}
