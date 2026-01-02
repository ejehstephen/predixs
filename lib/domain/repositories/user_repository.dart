import 'dart:io';
import '../entities/notification.dart';
import '../entities/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> fetchProfile();
  Future<List<NotificationItem>> fetchNotifications();
  Future<void> markNotificationRead(String id);
  Future<void> markAllNotificationsRead();
  Future<void> uploadAvatar(File file);
  Future<void> verifyKyc({required String phone, required String nin});

  // Admin Methods
  Future<List<UserProfile>> getAllUsers();
  Future<void> updateUserStatus(String userId, {bool? isBanned});
}
