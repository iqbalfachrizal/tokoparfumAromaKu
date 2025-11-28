import 'package:flutter/material.dart';
import 'package:arunika/db/database_helper.dart';
import 'package:arunika/models/user.dart';
import 'package:arunika/screens/auth/register_screen.dart';
import 'package:arunika/screens/main/home_layout.dart';
import 'package:arunika/services/session_manager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _fingerprintEnabled = false; 
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Panggil kedua operasi untuk mengisi _canCheckBiometrics dan _fingerprintEnabled
    _checkBiometrics(); 
    _loadFingerprintStatus(); 
  }

  // FUNGSI GABUNGAN: Menggabungkan status dan memicu rebuild UI
  void _updateStatus() {
    if (!mounted) return;
    
    // Debugging logs:
    print("DEBUG 1 - BIOMETRIK SUPPORT: $_canCheckBiometrics");
    print("DEBUG 2 - FINGERPRINT DIIZINKAN: $_fingerprintEnabled");
    bool finalResult = _canCheckBiometrics && _fingerprintEnabled;
    print("DEBUG 3 - TOMBOL TAMPIL JIKA: $finalResult");
    
    // Perbarui UI dengan status akhir
    setState(() {});
  }

  // CEK BIOMETRIK
  Future<void> _checkBiometrics() async {
    bool canCheck = false;
    try {
      canCheck = await auth.canCheckBiometrics;
    } catch (e) {
      debugPrint("Biometric error: $e");
    }

    if (!mounted) return;
    _canCheckBiometrics = canCheck; 
    _updateStatus(); 
  }

  // CEK APAKAH FINGERPRINT SUDAH DIAKTIFKAN
  Future<void> _loadFingerprintStatus() async { 
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // isFingerprintEnabled() mengambil kunci _fingerprintEnabledKey
    bool enabled = prefs.getBool('fingerprint_enabled') ?? false; 

    if (!mounted) return;
    _fingerprintEnabled = enabled; 
    _updateStatus(); 
  }

  // LOGIN BIOMETRIK
  Future<void> _authenticate() async {
    if (!_canCheckBiometrics || !_fingerprintEnabled) return;

    setState(() => _isAuthenticating = true);

    try {
      // 1. Otentikasi Sidik Jari/Biometrik
      final authenticated = await auth.authenticate(
        localizedReason: 'Gunakan sidik jari / wajah untuk login cepat',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      setState(() => _isAuthenticating = false);

      if (!authenticated) return; // Jika otentikasi OS gagal

      // 2. Ambil email + password yang DISIMPAN
      String? email = await SessionManager().getEmail();
      String? password = await SessionManager().getPassword();

      if (email == null || password == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login manual dulu!')),
        );
        return; // Ini tidak akan terjadi jika logout() tidak menghapus email/pass
      }

      // 3. Login ulang ke database menggunakan data yang disimpan
      User? user = await DatabaseHelper().loginUser(email, password);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun tidak ditemukan atau kredensial salah!')),
        );
        return;
      }

      // 4. RE-ESTABLISH SESSION DATA (Perbaikan Utama)
      // Panggil fungsi saveLoginData untuk mengatur isLoggedIn = true dan menyimpan userId
      await SessionManager().saveLoginData(
        user.id!, // Menggunakan ID yang didapat dari database
        email,
        password,
      );

      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeLayout()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Biometrik Berhasil!')),
      );

    } catch (e) {
      setState(() => _isAuthenticating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error biometrik: $e')),
      );
    }
  }

  // LOGIN MANUAL
  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    User? user = await DatabaseHelper().loginUser(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (user != null) {
      // 1. Simpan login, ID, dan aktifkan fingerprint
      await SessionManager().saveLoginData(
        user.id!,
        _emailController.text,
        _passwordController.text,
      );
      
      // 2. Muat ulang status
      _loadFingerprintStatus(); 

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeLayout()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email atau password salah!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (widget build() sama seperti sebelumnya) ...
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 80, color: Colors.purple),
                const SizedBox(height: 20),

                const Text(
                  'Selamat Datang di Arunika',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                // TOMBOL FINGERPRINT
                if (_canCheckBiometrics && _fingerprintEnabled) 
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: Column(
                      children: [
                        _isAuthenticating
                          ? const CircularProgressIndicator() 
                          : IconButton(
                              iconSize: 60,
                              icon: Icon(Icons.fingerprint,
                                  color: Colors.purple.shade700),
                              onPressed: _authenticate,
                            ),
                        const Text("Login dengan Fingerprint"),
                        const SizedBox(height: 20),
                        const Divider(height: 1, thickness: 1), 
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                
                if (!_canCheckBiometrics || !_fingerprintEnabled)
                  const SizedBox(height: 20),


                // EMAIL
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 15),

                // PASSWORD
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                // BUTTON LOGIN
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Login'),
                      ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Belum punya akun? Daftar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}