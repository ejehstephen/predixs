import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

extension ExceptionExtension on Object {
  /// Returns a user-friendly error message from any exception.
  String get toUserFriendlyMessage {
    final error = this;

    // 1. Supabase Auth Errors
    if (error is AuthException) {
      if (error.message.contains('Invalid login credentials')) {
        return 'Incorrect email or password.';
      }
      if (error.message.contains('User already registered')) {
        return 'This email is already in use. Please sign in.';
      }
      // Return the clean message from Supabase (usually readable)
      return error.message;
    }

    // 2. Supabase Database Errors
    if (error is PostgrestException) {
      // Handle known PL/pgSQL errors we wrote
      if (error.message.contains('Insufficient funds')) {
        return 'You do not have enough funds in your wallet.';
      }
      if (error.message.contains('Market already resolved')) {
        return 'This market has ended and cannot be traded.';
      }
      if (error.message.contains('Math Overlap')) {
        return 'Liquidity constraint. Try a smaller amount.';
      }
      // Default DB error
      return 'Database Error: ${error.message}';
    }

    // 3. Network Errors
    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    }

    // 4. Generic Exceptions
    if (error is Exception) {
      // Strip "Exception: " prefix if present
      final msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        return msg.substring(11);
      }
      return msg;
    }

    // 5. Fallback
    return 'Something went wrong. Please try again.';
  }
}
