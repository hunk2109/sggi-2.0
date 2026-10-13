import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _tokenKey = 'sggi_auth_token';
  static const String _userKey = 'sggi_auth_user';
  static const String _themeModeKey = 'sggi_theme_mode';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> removeToken() async {
    await _prefs.remove(_tokenKey);
  }

  // User
  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  UserModel? getUser() {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> removeUser() async {
    await _prefs.remove(_userKey);
  }

  // Clear All Session
  Future<void> clearSession() async {
    await removeToken();
    await removeUser();
  }

  // Theme
  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }

  String getThemeMode() {
    return _prefs.getString(_themeModeKey) ?? 'dark';
  }
}
