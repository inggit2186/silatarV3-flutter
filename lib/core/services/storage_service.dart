import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _rememberMeKey = 'remember_me';

  late final SharedPreferences _prefs;

  StorageService._();

  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token management
  Future<void> setToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  Future<void> removeToken() async {
    await _prefs.remove(_tokenKey);
  }

  // Remember me management
  Future<void> setRememberMe(bool value) async {
    await _prefs.setBool(_rememberMeKey, value);
  }

  Future<bool> getRememberMe() async {
    return _prefs.getBool(_rememberMeKey) ?? false;
  }

  // User data management
  Future<void> setUser(Map<String, dynamic> user) async {
    await _prefs.setString(_userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userStr = _prefs.getString(_userKey);
    if (userStr != null) {
      try {
        return jsonDecode(userStr) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> removeUser() async {
    await _prefs.remove(_userKey);
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    // Keep remember me if user wants to stay logged in
  }

  // Full logout (clear everything including remember me)
  Future<void> fullLogout() async {
    await _prefs.clear();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final rememberMe = await getRememberMe();
    if (!rememberMe) return false;

    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
