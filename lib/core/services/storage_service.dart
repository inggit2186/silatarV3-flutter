import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

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

  // User data management
  Future<void> setUser(Map<String, dynamic> user) async {
    await _prefs.setString(_userKey, user.toString());
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userStr = _prefs.getString(_userKey);
    if (userStr != null) {
      try {
        return _parseUser(userStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic>? _parseUser(String userStr) {
    // Simple parsing - in real app use jsonEncode/jsonDecode
    return null;
  }

  Future<void> removeUser() async {
    await _prefs.remove(_userKey);
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
