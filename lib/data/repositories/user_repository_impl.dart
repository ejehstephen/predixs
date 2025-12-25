import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local_storage_service.dart';
import '../services/verification_service.dart';

class UserRepositoryImpl implements UserRepository {
  final SupabaseClient _client;
  final LocalStorageService _localStorage;
  final VerificationService _verificationService;

  UserRepositoryImpl(
    this._client,
    this._localStorage,
    this._verificationService,
  );

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

      // Check if Admin
      bool isAdmin = false;
      try {
        final adminResponse = await _client
            .from('admins')
            .select()
            .eq('profile_id', userId)
            .maybeSingle();
        if (adminResponse != null) {
          isAdmin = true;
        }
      } catch (_) {
        // Ignore RLS errors or missing table
      }

      // Merge Admin Status into Profile
      final profileData = Map<String, dynamic>.from(response);
      profileData['is_admin'] = isAdmin;

      final profile = UserProfile.fromJson(profileData);
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
          isAdmin: currentProfile.isAdmin,
        );
        await _localStorage.saveProfile(updatedProfile);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error uploading avatar: $e');
      rethrow;
    }
  }

  @override
  Future<void> verifyKyc({required String phone, required String nin}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // 1. Verify NIN (Mock or Real)
      final isValid = await _verificationService.verifyNin(
        nin: nin,
        phoneNumber: phone,
      );

      if (!isValid) {
        throw Exception('Identity verification failed. Please check your NIN.');
      }

      // 2. Update Supabase Profile
      await _client
          .from('profiles')
          .update({
            'phone': phone,
            'nin': nin,
            'nin_verified': true,
            'kyc_level': 1, // Verified Level 1
          })
          .eq('id', userId);

      // 3. Update Local Cache
      final currentProfile = _localStorage.getProfile();
      if (currentProfile != null) {
        final updatedProfile = UserProfile(
          id: currentProfile.id,
          email: currentProfile.email,
          fullName: currentProfile.fullName,
          phone: phone,
          kycLevel: 1,
          avatarUrl: currentProfile.avatarUrl,
          isAdmin: currentProfile.isAdmin,
        );
        // Note: Profile entity doesn't have NIN field yet, but that's fine for now (security).
        await _localStorage.saveProfile(updatedProfile);
      }
    } catch (e) {
      print('Error completing KYC: $e');
      rethrow;
    }
  }
}
