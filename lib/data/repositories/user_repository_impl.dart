import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local_storage_service.dart';

class UserRepositoryImpl implements UserRepository {
  final SupabaseClient _client;
  final LocalStorageService _localStorage;

  UserRepositoryImpl(this._client, this._localStorage);

  @override
  Future<UserProfile?> fetchProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return _localStorage.getProfile();

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return _localStorage.getProfile();

      final profile = UserProfile.fromJson(response);
      await _localStorage.saveProfile(profile); // Cache it
      return profile;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching profile: $e');
      return _localStorage.getProfile(); // Fallback to cache
    }
  }

  @override
  Future<List<NotificationItem>> fetchNotifications() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return _localStorage.getNotifications();

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final notifications = (response as List)
          .map((e) => NotificationItem.fromJson(e))
          .toList();

      await _localStorage.saveNotifications(notifications);
      return notifications;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching notifications: $e');
      return _localStorage.getNotifications();
    }
  }

  @override
  Future<void> markNotificationRead(String id) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);

      // Update local cache optimistically or invalidate
      // Simpler for now: just stale cache until next fetch
    } catch (e) {
      // ignore: avoid_print
      print('Error marking notification read: $e');
    }
  }

  @override
  Future<void> uploadAvatar(File file) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final fileExt = file.path.split('.').last;
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final imageUrl = _client.storage.from('avatars').getPublicUrl(fileName);

      await _client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);

      // Update cache
      final currentProfile = _localStorage.getProfile();
      if (currentProfile != null) {
        final updatedProfile = UserProfile(
          id: currentProfile.id,
          email: currentProfile.email,
          fullName: currentProfile.fullName,
          phone: currentProfile.phone,
          kycLevel: currentProfile.kycLevel,
          avatarUrl: imageUrl,
        );
        await _localStorage.saveProfile(updatedProfile);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error uploading avatar: $e');
      rethrow;
    }
  }
}
