import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current user email
  String? get currentUserEmail => currentUser?.email;

  // Get current user metadata
  Map<String, dynamic>? get currentUserMetadata => currentUser?.userMetadata;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔵 AuthService: Attempting signup for $email');
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: metadata,
      );
      print('🟢 AuthService: Signup successful');
      return response;
    } catch (e) {
      print('🔴 AuthService: Signup error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      rethrow;
    }
  }

  // Update user metadata
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> metadata) async {
    try {
      return await _supabase.auth.updateUser(UserAttributes(data: metadata));
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is signed in
  bool isSignedIn() {
    return currentUser != null;
  }

  // Listen to auth state changes
  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }
}
