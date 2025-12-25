import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/repositories/user_repository_impl.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../../domain/repositories/user_repository.dart';
import '../../auth/providers/auth_providers.dart';

import '../../../../data/datasources/local_storage_service.dart';

// Reuse the repository provider if we move it here or import it
import '../../../../data/services/verification_service.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return UserRepositoryImpl(
    Supabase.instance.client,
    localStorage,
    MockVerificationService(),
  );
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // refresh when auth state changes
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return null;

  final repo = ref.watch(userRepositoryProvider);
  return await repo.fetchProfile();
});
