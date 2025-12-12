import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
              Color(0xFF3730A3), // Deep Indigo
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Background Circle (Subtle)
              Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.show_chart,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.05, 1.05),
                    duration: 2000.ms,
                    curve: Curves.easeInOut,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),

              const Gap(32),

              // App Name
              Column(
                children: [
                  Text(
                        'PREDIXS',
                        style: GoogleFonts.outfit(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .moveY(
                        begin: 20,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      ),

                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ).animate().scaleX(
                    begin: 0,
                    end: 1,
                    delay: 600.ms,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),

                  Text(
                    'The Future of Prediction',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
