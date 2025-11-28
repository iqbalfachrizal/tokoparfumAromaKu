import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arunika/db/database_helper.dart';
import 'package:arunika/models/user.dart';
import 'package:arunika/screens/auth/login_screen.dart';
import 'package:arunika/services/session_manager.dart';
import 'package:arunika/services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    int? userId = await SessionManager().getUserId();
    if (userId != null) {
      User? user = await DatabaseHelper().getUserById(userId);
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    final XFile? file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (file != null && _currentUser != null) {
      await DatabaseHelper().updateUserPhoto(_currentUser!.id!, file.path);
      _loadUserData(); 
    }
  }

  // POPUP UNTUK EDIT NAMA/EMAIL/PASSWORD (DENGAN IKON MATA)
  void _openEditProfileDialog() {
    final _editFormKey = GlobalKey<FormState>();
    TextEditingController nameC = TextEditingController(text: _currentUser!.name);
    TextEditingController emailC = TextEditingController(text: _currentUser!.email);
    TextEditingController passC = TextEditingController();
    
    // Variabel untuk mengontrol visibilitas password
    bool _isPasswordVisible = false;

    showDialog(
      context: context,
      // Menggunakan StatefulBuilder untuk mengelola state visibility di dalam AlertDialog
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Profil"),
              content: SingleChildScrollView(
                child: Form(
                  key: _editFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // NAMA
                      TextFormField(
                        controller: nameC,
                        decoration: const InputDecoration(labelText: "Nama"),
                        validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                      ),
                      
                      // EMAIL
                      TextFormField(
                        controller: emailC,
                        decoration: const InputDecoration(labelText: "Email"),
                        validator: (v) => 
                          (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                      ),
                      
                      // PASSWORD BARU (DENGAN ICON MATA)
                      TextFormField(
                        controller: passC,
                        // Menentukan apakah teks harus disembunyikan
                        obscureText: !_isPasswordVisible, 
                        decoration: InputDecoration(
                          labelText: "Password Baru (opsional)",
                          // Menambahkan IconButton di akhir field
                          suffixIcon: IconButton(
                            icon: Icon(
                              // Mengganti ikon berdasarkan state
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              // Mengubah state visibility saat tombol ditekan
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        // Validasi wajib diisi (seperti permintaan sebelumnya)
                        validator: (v) => (v == null || v.isEmpty) ? 'Password Baru wajib diisi' : null, 
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_editFormKey.currentState!.validate()) {
                      return; 
                    }
                    
                    // Proses password (mengubah string kosong menjadi null)
                    String? newPassword = passC.text.trim().isEmpty ? null : passC.text.trim();
                    
                    await DatabaseHelper().updateUserProfile(
                      _currentUser!.id!,
                      nameC.text,
                      emailC.text,
                      newPassword,
                    );

                    Navigator.pop(dialogContext);
                    _loadUserData();
                  },
                  child: const Text("Simpan"),
                )
              ],
            );
          },
        );
      },
    );
  }

  // ... (Fungsi _logout dan Widget build() lainnya tetap sama) ...
  Future<void> _logout() async {
    await _notificationService.scheduleFinalNotification(
      'Sampai Jumpa!',
      'Terima kasih telah menggunakan arunika. Kami tunggu kembali!',
      10,
    );

    await SessionManager().logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _currentUser != null ? _openEditProfileDialog : null, 
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('Gagal memuat data user.'))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _currentUser!.photo == null
                                ? const NetworkImage(
                                      'https://cdn.pixabay.com/photo/2018/05/02/00/49/man-3367459_1280.png')
                                : FileImage(File(_currentUser!.photo!)) as ImageProvider,
                            backgroundColor: Colors.grey[200],
                          ),

                          // BUTTON EDIT FOTO
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt),
                                        title: const Text("Ambil dari Kamera"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage(true);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo),
                                        title: const Text("Pilih dari Galeri"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage(false);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.purple,
                                child: Icon(Icons.camera_alt, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Card(
                      elevation: 2.0,
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.purple),
                        title: const Text('Nama', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(_currentUser!.name, style: const TextStyle(fontSize: 16)),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Card(
                      elevation: 2.0,
                      child: ListTile(
                        leading: const Icon(Icons.email, color: Colors.purple),
                        title: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(_currentUser!.email, style: const TextStyle(fontSize: 16)),
                      ),
                    ),

                    const SizedBox(height: 40),

                    ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
    );
  }
}