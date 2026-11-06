import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sèvis otantifikasyon + verifikasyon admin.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp(
    String email,
    String password, {
    String? fullName,
  }) => _client.auth.signUp(
    email: email,
    password: password,
    emailRedirectTo: redirectUrl,
    data: {if (fullName != null && fullName.isNotEmpty) 'full_name': fullName},
  );

  String get redirectUrl => kIsWeb
      ? Uri.base.replace(fragment: '', query: '').toString()
      : 'redlight://auth/callback';

  Future<bool> signInWithGoogle() => _client.auth.signInWithOAuth(
    OAuthProvider.google, redirectTo: redirectUrl,
  );

  Future<void> resetPassword(String email) => _client.auth.resetPasswordForEmail(
    email.trim(), redirectTo: redirectUrl,
  );

  Future<void> updateProfile({required String name, required String phone, required String address}) async {
    await _client.auth.updateUser(UserAttributes(data: {'full_name': name.trim(), 'phone': phone.trim(), 'address': address.trim()}));
  }

  Future<void> changePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut().timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  static bool isKnownAdminEmail(String? email) {
    if (email == null) return false;
    final clean = email.toLowerCase().trim();
    return clean == 'laurorejeanclarens0@gmail.com' ||
        clean == 'redlightautomotive945@gmail.com' ||
        clean == 'admin@redlight.ht';
  }

  /// Verifye si itilizatè konekte a se yon admin (fonksyon SQL redlight_is_admin() + verifikasyon imel).
  Future<bool> isAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final email = user.email?.toLowerCase().trim();
    if (email != null && isKnownAdminEmail(email)) {
      return true;
    }

    if (user.appMetadata['role'] == 'admin' || user.appMetadata['is_admin'] == true) {
      return true;
    }

    try {
      final result = await _client.rpc('redlight_is_admin').timeout(const Duration(seconds: 4));
      if (result == true) return true;
    } catch (_) {
      try {
        final result = await _client.rpc('is_admin').timeout(const Duration(seconds: 4));
        if (result == true) return true;
      } catch (_) {}
    }

    if (email != null) {
      try {
        final res = await _client
            .from('redlight_admin_users')
            .select('email')
            .ilike('email', email)
            .maybeSingle()
            .timeout(const Duration(seconds: 4));
        if (res != null) return true;
      } catch (_) {
        try {
          final res = await _client
              .from('admin_users')
              .select('email')
              .ilike('email', email)
              .maybeSingle()
              .timeout(const Duration(seconds: 4));
          if (res != null) return true;
        } catch (_) {}
      }
    }

    return false;
  }
}
