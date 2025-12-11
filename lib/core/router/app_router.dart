import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/features/auth/presentation/login_screen.dart';
import '../../presentation/features/auth/presentation/signup_screen.dart';
import '../../presentation/features/auth/presentation/otp_screen.dart';
import '../../presentation/features/auth/providers/auth_providers.dart';
import '../../presentation/features/home/presentation/home_screen.dart';
import '../../presentation/features/market/presentation/market_detail_screen.dart';
import '../../presentation/features/market/presentation/markets_screen.dart';
import '../../presentation/features/portfolio/presentation/portfolio_screen.dart';
import '../../presentation/features/splash/presentation/splash_screen.dart';
import '../../presentation/features/account/presentation/account_screen.dart';
import '../../presentation/features/notifications/presentation/notifications_screen.dart';
import '../../presentation/features/onboarding/presentation/onboarding_screen.dart';
import '../../presentation/features/wallet/presentation/deposit_screen.dart';
import '../../presentation/features/wallet/presentation/wallet_screen.dart';
import '../../presentation/features/wallet/presentation/withdraw_screen.dart';
import '../../data/datasources/local_storage_service.dart';

// Placeholder screens for navigation setup
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Markets'),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  // Listen to auth state changes to refresh router
  final authState = ref.watch(authStateProvider);
  final localStorage = ref.watch(localStorageServiceProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final path = state.uri.path;

      // Always allow Splash
      if (path == '/splash') return null;

      // Check onboarding status
      final hasSeenOnboarding = localStorage.hasSeenOnboarding;

      // If onboarding not seen and we are not on splash or onboarding, go to splash
      // (Splash will handle the animation and then go to onboarding)
      if (!hasSeenOnboarding && path != '/onboarding') {
        return '/splash';
      }

      final isLoggingIn = path == '/login' || path == '/signup';
      final isOnboarding = path == '/onboarding';

      // If logged in, prevent access to auth pages and onboarding
      if (isLoggedIn && (isLoggingIn || isOnboarding)) {
        return '/';
      }

      // If not logged in...
      if (!isLoggedIn) {
        // Allow onboarding if we are there
        if (isOnboarding) return null;

        // Allow login/signup
        if (isLoggingIn) return null;

        // Block everything else
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'markets/:id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MarketDetailScreen(marketId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/markets',
                builder: (context, state) => const MarketsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/portfolio',
                builder: (context, state) => const PortfolioScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final email = state.extra as String;
          return OtpScreen(email: email);
        },
      ),
      GoRoute(
        path: '/wallet',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/deposit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DepositScreen(),
      ),
      GoRoute(
        path: '/withdraw',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WithdrawScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
