import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/repositories/user_repository_impl.dart';
import '../../../../domain/entities/notification.dart';
import '../../../../domain/repositories/user_repository.dart';

import '../../../../data/datasources/local_storage_service.dart';

import '../../../../data/services/verification_service.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return UserRepositoryImpl(
    Supabase.instance.client,
    localStorage,
    MockVerificationService(),
  );
});

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationItem>>((ref) async {
      final repo = ref.watch(userRepositoryProvider);
      return await repo.fetchNotifications();
    });

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
