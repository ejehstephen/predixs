import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/datasources/local_storage_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Wait for animation and minimum splash time
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final hasSeenOnboarding = ref
        .read(localStorageServiceProvider)
        .hasSeenOnboarding;

    // We check auth state synchronously here because Riverpod provider is already initialized
    // However, for correct auth redirection it's better to let the Router or a listener handle it,
    // but here we just need to know where to go NEXT from splash.
    // The router redirect might intercept, so we should go to a path.

    if (!hasSeenOnboarding) {
      if (mounted) context.go('/onboarding');
    } else {
      // If we go to home, the router redirect will check auth and redirect to login if needed.
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Using primary color for branding
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Icon (Placeholder or Icon)
            Icon(Icons.show_chart, size: 80, color: AppColors.accent)
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .fade(),

            const SizedBox(height: 16),

            // App Name
            Text(
              'Predix',
              style: GoogleFonts.outfit(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),

            const SizedBox(height: 8),

            Text(
              'Predict. Invest. Win.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
