import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class Auth {
  static const String currentUserKey = 'currentUser';
  static const String fullNameKey = 'fullName';
  static const String premiumKey = 'isPremium';

  static Future<void> signup(String fullName, String username, String password) async {
    final user = await ApiService.signup(
      fullName: fullName,
      username: username,
      password: password,
    );
    await _saveSession(user);
  }

  static Future<bool> login(String username, String password) async {
    try {
      final user = await ApiService.login(username: username, password: password);
      await _saveSession(user);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(currentUserKey);
    if (username == null) return null;

    try {
      final user = await ApiService.getUser(username);
      await _saveSession(user);
      return user;
    } catch (_) {
      return {
        'username': username,
        'full_name': prefs.getString(fullNameKey) ?? '',
        'is_premium': prefs.getBool(premiumKey) ?? false,
      };
    }
  }

  static Future<void> updateCurrentUser(String fullName, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(currentUserKey);
    if (username == null) return;

    final user = await ApiService.updateUser(
      username: username,
      fullName: fullName,
      password: password.isEmpty ? null : password,
    );
    await _saveSession(user);
  }

  static Future<void> refreshCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(currentUserKey);
    if (username == null) return;
    final user = await ApiService.getUser(username);
    await _saveSession(user);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(currentUserKey);
    await prefs.remove(fullNameKey);
    await prefs.remove(premiumKey);
    await prefs.setBool('isLoggedIn', false);
  }

  static Future<void> _saveSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(currentUserKey, user['username']?.toString() ?? '');
    await prefs.setString(fullNameKey, user['full_name']?.toString() ?? '');
    await prefs.setBool(premiumKey, user['is_premium'] == true);
    await prefs.setBool('isLoggedIn', true);
  }
}
