import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/datasources/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // TODO: Replace with your actual Supabase URL and Anon Key
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  final localStorage = LocalStorageService(prefs);

  runApp(
    ProviderScope(
      overrides: [localStorageServiceProvider.overrideWithValue(localStorage)],
      child: const PredixApp(),
    ),
  );
}

class PredixApp extends ConsumerStatefulWidget {
  const PredixApp({super.key});

  @override
  ConsumerState<PredixApp> createState() => _PredixAppState();
}

class _PredixAppState extends ConsumerState<PredixApp> {
  @override
  void initState() {
    super.initState();
    // Listen for Password Recovery Event
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      print("AUTH EVENT: $event"); // Debug Log
      if (event == AuthChangeEvent.passwordRecovery) {
        print("PASSWORD RECOVERY DETECTED - NAVIGATING");
        // Convert to async to allow small delay if needed for router init
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          ref.read(goRouterProvider).go('/update-password');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Predix',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
