import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  final String _isLoggedInKey = 'isLoggedIn';
  final String _userIdKey = 'userId';

  Future<void> createSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(_userIdKey, userId);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
  
  Future<int?> getUserId() async {
     final prefs = await SharedPreferences.getInstance();
     return prefs.getInt(_userIdKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userIdKey);
  }
}