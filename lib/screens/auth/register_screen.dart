import 'package:flutter/material.dart';
import 'package:arunika/db/database_helper.dart';
import 'package:arunika/models/user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _register() async {
    // 1. Validasi form terlebih dahulu
    if (!_formKey.currentState!.validate()) {
      return; // Jika form tidak valid, jangan lanjutkan
    }

    // 2. Set loading jadi true
    setState(() => _isLoading = true);

    try {
      // 3. Buat objek user
      User newUser = User(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      // 4. Panggil database
      int result = await DatabaseHelper().registerUser(newUser);

      // 5. Cek apakah halaman masih ada sebelum panggil Navigator/Scaffold
      if (!mounted) return;

      if (result != -1) {
        // SUKSES
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registrasi berhasil! Silakan login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke halaman login
      } else {
        // GAGAL KARENA EMAIL DUPLIKAT
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email sudah terdaftar! Gunakan email lain.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // GAGAL KARENA ERROR LAIN (misal: database error)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 6. INI KUNCINYA:
      // Apapun yang terjadi (sukses, gagal, atau error),
      // spinner PASTI akan dihentikan.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun Baru')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // Rata tengah
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => (value == null ||
                          value.isEmpty ||
                          !value.contains('@'))
                      ? 'Email tidak valid (harus ada @)'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Password tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white),
                          child:
                              const Text('Daftar', style: TextStyle(fontSize: 18)),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}