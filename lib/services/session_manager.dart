import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  final String _isLoggedInKey = 'isLoggedIn';
  final String _userIdKey = 'userId';
  final String _emailKey = 'email';
  final String _passwordKey = 'password';
  final String _fingerprintEnabledKey = 'fingerprint_enabled';

  // Menyimpan data login dan mengaktifkan fingerprint
  Future<void> saveLoginData(int userId, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_passwordKey, password);
    // Mengaktifkan fitur fingerprint
    await prefs.setBool(_fingerprintEnabledKey, true); 
  }

  // Mengambil status aktivasi fingerprint
  Future<bool> isFingerprintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fingerprintEnabledKey) ?? false;
  }

  // Mengambil data email
  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // Mengambil data password
  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }

  // Cek status login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // --- FUNGSI LOGOUT YANG HANYA MENGHAPUS STATUS SESI ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Hapus HANYA status sesi aktif dan ID pengguna
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userIdKey);

    // Kredensial (_emailKey dan _passwordKey) TIDAK DIHAPUS.
    // Status Fingerprint (_fingerprintEnabledKey) juga TIDAK DIHAPUS.
    // Ini adalah solusi agar login biometrik tetap berfungsi setelah logout.
  }
}