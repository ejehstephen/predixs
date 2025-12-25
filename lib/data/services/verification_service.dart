/// Interface for Identity Verification
abstract class VerificationService {
  /// Verifies a National Identity Number (NIN).
  /// Returns [true] if valid, [false] if invalid.
  /// Throws [Exception] if verification service is down or fails.
  Future<bool> verifyNin({
    required String nin,
    required String phoneNumber,
    String? firstName,
    String? lastName,
  });
}

/// Mock Service for Development/Testing
/// Simulates verification by checking basic format constraints.
class MockVerificationService implements VerificationService {
  @override
  Future<bool> verifyNin({
    required String nin,
    required String phoneNumber,
    String? firstName,
    String? lastName,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Basic Validation Rules (Nigeria NIN is 11 digits)
    if (nin.length != 11) return false;
    if (int.tryParse(nin) == null) return false;

    // Simulate success
    return true;
  }
}

/// Real Service Stub (e.g., for VerifyMe, SmileID, Dojah)
/// Replace with actual API integration when API Key is available.
class RealVerificationService implements VerificationService {
  final String apiKey;
  final String baseUrl;

  RealVerificationService({
    required this.apiKey,
    this.baseUrl = 'https://api.verifyme.ng/v1', // Example
  });

  @override
  Future<bool> verifyNin({
    required String nin,
    required String phoneNumber,
    String? firstName,
    String? lastName,
  }) async {
    // TODO: Implement actual HTTP call to Government/Provider API
    // final response = await http.post(...)

    throw UnimplementedError(
      'Real Verification API not yet configured. Use Mock for now.',
    );
  }
}
