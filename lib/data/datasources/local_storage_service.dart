import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/user_profile.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static const _keyProfile = 'user_profile';
  static const _keyNotifications = 'user_notifications';
  static const _keyHasSeenOnboarding = 'has_seen_onboarding';

  // Onboarding
  bool get hasSeenOnboarding => _prefs.getBool(_keyHasSeenOnboarding) ?? false;

  Future<void> setHasSeenOnboarding() async {
    await _prefs.setBool(_keyHasSeenOnboarding, true);
  }

  // Profile

  Future<void> saveProfile(UserProfile profile) async {
    final jsonString = jsonEncode(profile.toJson());
    await _prefs.setString(_keyProfile, jsonString);
  }

  UserProfile? getProfile() {
    final jsonString = _prefs.getString(_keyProfile);
    if (jsonString == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  Future<void> saveNotifications(List<NotificationItem> notifications) async {
    final jsonList = notifications.map((n) => n.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_keyNotifications, jsonString);
  }

  List<NotificationItem> getNotifications() {
    final jsonString = _prefs.getString(_keyNotifications);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => NotificationItem.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_keyProfile);
    await _prefs.remove(_keyNotifications);
  }
}
