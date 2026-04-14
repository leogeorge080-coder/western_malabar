import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this.supabase);

  final SupabaseClient supabase;

  static const String _googleWebServerClientId =
      '775835171020-fhg8q6jgf24m6ddchgqamqc53jbmqlmf.apps.googleusercontent.com';

  bool get isSignedIn {
    final user = supabase.auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  bool get isGuestUser {
    final user = supabase.auth.currentUser;
    return user == null || user.isAnonymous;
  }

  User? get currentUser => supabase.auth.currentUser;

  GoogleSignIn _buildGoogleSignIn() {
    return GoogleSignIn(
      scopes: const ['email'],
      serverClientId: _googleWebServerClientId,
    );
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = _buildGoogleSignIn();

      // Force the account picker so the user can choose the correct account
      // instead of silently reusing a cached session.
      await googleSignIn.signOut();
      await googleSignIn.disconnect().catchError((_) {});

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      debugPrint('Google sign-in idToken null? ${idToken == null}');
      debugPrint('Google sign-in accessToken null? ${accessToken == null}');

      if (idToken == null || accessToken == null) {
        throw Exception('Missing Google auth tokens');
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final currentUser = supabase.auth.currentUser;
      debugPrint('SUPABASE ACTIVE USER ID: ${currentUser?.id}');
      debugPrint('SUPABASE ACTIVE USER EMAIL: ${currentUser?.email}');

      await ensureProfileExists();
    } catch (e, st) {
      debugPrint('Google sign-in failed: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse result = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) {
        throw Exception('Unable to sign in');
      }

      await ensureProfileExists();
    } catch (e, st) {
      debugPrint('Email sign-in failed: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse result = await supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) {
        throw Exception('Unable to create account');
      }

      await ensureProfileExists();
    } catch (e, st) {
      debugPrint('Email sign-up failed: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> sendPasswordReset({
    required String email,
  }) async {
    try {
      await supabase.auth.resetPasswordForEmail(email.trim());
    } catch (e, st) {
      debugPrint('Password reset failed: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> ensureProfileExists() async {
    final User? user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    final Map<String, dynamic>? existing = await supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    final String fullName = (user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            user.email?.split('@').first ??
            'User')
        .toString();

    final String email = user.email ?? '';
    final String phone = (user.phone ?? '').trim();

    if (existing == null) {
      await supabase.from('profiles').insert({
        'id': user.id,
        'full_name': fullName,
        'email': email,
        'phone': phone.isEmpty ? null : phone,
        'reward_points': 0,
        'next_reward_at': 200,
        'total_orders': 0,
        'saved_addresses': 0,
        'is_premium': false,
        'role': 'customer',
      });
    } else {
      await supabase.from('profiles').update({
        'full_name': fullName,
        'email': email,
        if (phone.isNotEmpty) 'phone': phone,
      }).eq('id', user.id);
    }
  }

  Future<void> signOut() async {
    final googleSignIn = _buildGoogleSignIn();

    try {
      await googleSignIn.signOut();
    } catch (_) {}

    await supabase.auth.signOut(scope: SignOutScope.global);
  }
}
