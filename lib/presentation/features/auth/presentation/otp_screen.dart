import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _pinController = TextEditingController();

  Future<void> _verifyOtp() async {
    if (_pinController.text.length != 4) return;

    await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(widget.email, _pinController.text);

    if (mounted) {
      if (ref.read(authControllerProvider).hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${ref.read(authControllerProvider).error}'),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        // Navigate to Home on success
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider state
    final authState = ref.watch(authControllerProvider);
    final _isLoading = authState.isLoading;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: GoogleFonts.outfit(
        fontSize: 24,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.textHint.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primary),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Gap(20),
            Icon(
              Icons.lock_person_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const Gap(24),
            Text(
              'Verification',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(8),
            Text(
              'Enter the 4-digit code sent to your email address.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const Gap(40),
            Pinput(
              controller: _pinController,
              length: 4,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              onCompleted: (pin) => _verifyOtp(),
              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
              showCursor: true,
            ),
            const Gap(40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Verify',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const Gap(24),
            TextButton(
              onPressed: () {
                // Resend UI logic
              },
              child: Text(
                'Resend Code',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
