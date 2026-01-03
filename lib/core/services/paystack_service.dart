import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../presentation/features/wallet/presentation/paystack_webview_screen.dart';

class PaystackService {
  static final PaystackService _instance = PaystackService._internal();
  factory PaystackService() => _instance;
  PaystackService._internal();

  final PaystackPlugin _paystack = PaystackPlugin();
  bool _isInitialized = false;

  // TODO: Replace with your actual Public Key from Paystack Dashboard
  // Ideally, fetch this from a remote config or .env file in production.
  static const String _publicKey =
      'pk_test_e78103c7372383de2f1e07adbdad1fd1103d40af';

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _paystack.initialize(publicKey: _publicKey);
      _isInitialized = true;
      debugPrint("Paystack Initialized");
    } catch (e) {
      debugPrint("Paystack Initialization Failed: $e");
    }
  }

  /// Trigger the Paystack Checkout Popup
  /// [context] - BuildContext
  /// [amount] - Amount in Naira (Will be converted to Kobo)
  /// [email] - User's email
  /// [reference] - Unique transaction reference
  Future<CheckoutResponse?> chargeCard({
    required BuildContext context,
    required double amount,
    required String email,
    required String reference,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 1. Get current session token explicitly
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null || session.accessToken.isEmpty) {
        throw Exception("No active session found. Please login again.");
      }

      // 2. Call Backend with explicit Authorization header
      final res = await Supabase.instance.client.functions.invoke(
        'paystack',
        body: {'email': email, 'amount': amount, 'reference': reference},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      final data = res.data;
      if (data == null || data['access_code'] == null) {
        throw Exception(
          "Failed to get access code from backend: ${data?['message'] ?? 'Unknown Error'}",
        );
      }

      final String authUrl = data['authorization_url'];
      // final String accessCode = data['access_code']; // Not needed for webview

      // 2. Launch Web Checkout
      // We import the new screen at top (will add import in next step or use qualified)
      final bool? success = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              PaystackWebView(authUrl: authUrl, reference: reference),
        ),
      );

      if (success == true) {
        // Construct a success response
        final response = CheckoutResponse.defaults();
        response.reference = reference;
        response.message = 'Success';
        response.status = true;
        response.method = CheckoutMethod.selectable;
        return response;
      } else {
        // User cancelled or failed
        throw Exception("Transaction cancelled or failed");
      }
    } catch (e) {
      debugPrint("Paystack Backend Checkout Error: $e");
      rethrow;
    }
  }

  // --- WITHDRAWAL / TRANSFERS ---

  Future<List<dynamic>> getBanks() async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'paystack',
        body: {'action': 'get_banks'},
      );

      final data = response.data;
      if (data['status'] == true) {
        return data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint("Get Banks Error: $e");
      rethrow;
    }
  }

  Future<String?> resolveAccount(String accountNumber, String bankCode) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'paystack',
        body: {
          'action': 'resolve_account',
          'account_number': accountNumber,
          'bank_code': bankCode,
        },
      );

      final data = response.data;
      if (data['status'] == true) {
        return data['data']['account_name'] as String;
      } else {
        throw Exception(data['message'] ?? "Account resolution failed");
      }
    } catch (e) {
      debugPrint("Resolve Account Error: $e");
      rethrow;
    }
  }

  Future<void> withdrawFunds({
    required double amount,
    required String bankCode,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      // REFACTOR: Use the Database RPC directly (Manual Flow)
      // This ensures we save the Transaction ID and link it properly for Admin approval.
      // We skip the 'paystack' Edge Function for now because we are doing Manual Payouts.
      
      await Supabase.instance.client.rpc(
        'withdraw_funds',
        params: {
          'p_amount': amount,
          'p_bank_name': bankName,
          'p_account_number': accountNumber,
          'p_account_name': accountName,
        },
      );
      
      // If RPC succeeds (void), we are good.
      // (If it fails, it throws, caught below)

    } catch (e) {
      debugPrint("Withdraw Error: $e");
      rethrow;
    }
  }
}
