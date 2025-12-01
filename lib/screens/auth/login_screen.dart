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
  bool _obscurePassword = true;

  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _fingerprintEnabled = false; 
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics(); 
    _loadFingerprintStatus(); 
  }

  void _updateStatus() {
    if (!mounted) return;
    setState(() {});
  }

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

  Future<void> _loadFingerprintStatus() async { 
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool enabled = prefs.getBool('fingerprint_enabled') ?? false; 

    if (!mounted) return;
    _fingerprintEnabled = enabled; 
    _updateStatus(); 
  }

  Future<void> _authenticate() async {
    if (!_canCheckBiometrics || !_fingerprintEnabled) return;

    setState(() => _isAuthenticating = true);

    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Gunakan sidik jari / wajah untuk login cepat',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      setState(() => _isAuthenticating = false);

      if (!authenticated) return;

      String? email = await SessionManager().getEmail();
      String? password = await SessionManager().getPassword();

      if (email == null || password == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login manual dulu!')),
        );
        return;
      }

      User? user = await DatabaseHelper().loginUser(email, password);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun tidak ditemukan atau kredensial salah!')),
        );
        return;
      }

      await SessionManager().saveLoginData(
        user.id!,
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

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    User? user = await DatabaseHelper().loginUser(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (user != null) {
      await SessionManager().saveLoginData(
        user.id!,
        _emailController.text,
        _passwordController.text,
      );
      
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade400,
              Colors.deepPurple.shade600,
              Colors.indigo.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, size: 60, color: Colors.white),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Selamat Datang',
                          style: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Login ke Arunika',
                          style: TextStyle(
                            fontSize: 16, 
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 30),

                        if (_canCheckBiometrics && _fingerprintEnabled) 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                _isAuthenticating
                                  ? const CircularProgressIndicator() 
                                  : InkWell(
                                      onTap: _authenticate,
                                      borderRadius: BorderRadius.circular(50),
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.purple.shade200,
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.fingerprint,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Login dengan Fingerprint",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'ATAU',
                                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),

                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.deepPurple),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (v) =>
                              (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.deepPurple),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                        ),
                        const SizedBox(height: 25),

                        _isLoading
                            ? const CircularProgressIndicator()
                            : Container(
                                width: double.infinity,
                                height: 55,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.shade200,
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.grey.shade700),
                              children: const [
                                TextSpan(text: 'Belum punya akun? '),
                                TextSpan(
                                  text: 'Daftar',
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
