import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  static const _kAccessToken = 'qcart_access_token';
  static const _kUser       = 'qcart_current_user';

  static Map<String, dynamic>? _currentUser;

  static Map<String, dynamic>? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null && ApiClient.hasToken;
  static String? get userId => _currentUser?['id']?.toString();
  static String? get userRole => _currentUser?['role']?.toString();

  /// Call once at app start (e.g. in main() before runApp).
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token    = prefs.getString(_kAccessToken);
    final userJson = prefs.getString(_kUser);
    if (token != null && userJson != null) {
      try {
        _currentUser = json.decode(userJson) as Map<String, dynamic>;
        ApiClient.setToken(token);
      } catch (_) {
        await _clearStorage();
      }
    }
  }

  /// POST /v1/auth/login — returns the user object on success.
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiClient.post('/auth/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    final data        = response['data'] as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final user        = data['user'] as Map<String, dynamic>;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, accessToken);
    await prefs.setString(_kUser, json.encode(user));

    ApiClient.setToken(accessToken);
    _currentUser = user;
    return user;
  }

  /// POST /v1/auth/logout — clears token locally regardless of server response.
  static Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout', {});
    } catch (_) {}
    await _clearStorage();
  }

  static Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kUser);
    ApiClient.clearToken();
    _currentUser = null;
  }
}
