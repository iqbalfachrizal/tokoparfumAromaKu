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

  void _openEditProfileDialog() {
    final _editFormKey = GlobalKey<FormState>();
    TextEditingController nameC = TextEditingController(text: _currentUser!.name);
    TextEditingController emailC = TextEditingController(text: _currentUser!.email);
    TextEditingController passC = TextEditingController();
    
    bool _isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text("Edit Profil"),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _editFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameC,
                        decoration: InputDecoration(
                          labelText: "Nama",
                          prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: emailC,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email, color: Colors.deepPurple),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                          ),
                        ),
                        validator: (v) => 
                          (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: passC,
                        obscureText: !_isPasswordVisible, 
                        decoration: InputDecoration(
                          labelText: "Password Baru (opsional)",
                          prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Password Baru wajib diisi' : null, 
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!_editFormKey.currentState!.validate()) {
                        return; 
                      }
                      
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text("Simpan", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentUser == null
                ? const Center(child: Text('Gagal memuat data user.'))
                : Column(
                    children: [
                      // Header dengan Gradien
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.purple.shade400,
                              Colors.deepPurple.shade600,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.shade200,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Profil Saya',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white),
                                      onPressed: _openEditProfileDialog,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                
                                // Avatar
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 60,
                                        backgroundImage: _currentUser!.photo == null
                                            ? const NetworkImage(
                                                  'https://cdn.pixabay.com/photo/2018/05/02/00/49/man-3367459_1280.png')
                                            : FileImage(File(_currentUser!.photo!)) as ImageProvider,
                                        backgroundColor: Colors.grey[200],
                                      ),
                                    ),

                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(20),
                                                topRight: Radius.circular(20),
                                              ),
                                            ),
                                            builder: (_) => Container(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ListTile(
                                                    leading: Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                                                        ),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: const Icon(Icons.camera_alt, color: Colors.white),
                                                    ),
                                                    title: const Text("Ambil dari Kamera"),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _pickImage(true);
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                                                        ),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: const Icon(Icons.photo, color: Colors.white),
                                                    ),
                                                    title: const Text("Pilih dari Galeri"),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _pickImage(false);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _currentUser!.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentUser!.email,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.purple.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.shade100,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                title: const Text(
                                  'Nama',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _currentUser!.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.purple.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.shade100,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.email, color: Colors.white),
                                ),
                                title: const Text(
                                  'Email',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _currentUser!.email,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            Container(
                              height: 55,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red.shade400, Colors.red.shade600],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.shade200,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout, size: 24),
                                label: const Text(
                                  'Logout',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
