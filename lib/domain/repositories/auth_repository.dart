import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  );
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  });
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  });
  Future<void> signOut();
  User? get currentUser;
  Stream<AuthState> get authStateChanges;
  Future<void> sendPasswordResetEmail(String email);
  Future<void> deleteAccount();
}
