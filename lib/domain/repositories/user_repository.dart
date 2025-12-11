import 'dart:io';
import '../entities/notification.dart';
import '../entities/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> fetchProfile();
  Future<List<NotificationItem>> fetchNotifications();
  Future<void> markNotificationRead(String id);
  Future<void> uploadAvatar(File file);
}
