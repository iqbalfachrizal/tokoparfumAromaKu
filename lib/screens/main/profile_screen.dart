import 'package:flutter/material.dart';
import 'package:aromaku/db/database_helper.dart';
import 'package:aromaku/models/user.dart';
import 'package:aromaku/screens/auth/login_screen.dart';
import 'package:aromaku/services/session_manager.dart';
import 'package:aromaku/services/notification_service.dart'; 

class ProfileScreen extends StatefulWidget {
    const ProfileScreen({super.key});

    @override
    _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
    User? _currentUser;
    bool _isLoading = true;
    final NotificationService _notificationService = NotificationService(); // Deklarasi Service

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

    void _logout() async {
        // 1. JADWALKAN NOTIFIKASI "TERIMA KASIH" 10 DETIK KEMUDIAN (Menggunakan Awesome Notif)
        await _notificationService.scheduleFinalNotification(
            'Sampai Jumpa!',
            'Terima kasih telah menggunakan AromaKu. Kami tunggu kunjungan Anda kembali!',
            10, // Notifikasi akan muncul 10 detik kemudian
        );
        
        // 2. Hapus sesi dan pindah halaman
        await SessionManager().logout();
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('Profil Saya')),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentUser == null
                    ? const Center(child: Text('Gagal memuat data user.'))
                    : ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                            Center(
                                child: CircleAvatar(
                                    radius: 50,
                                    // Placeholder image
                                    backgroundImage: const NetworkImage('https://cdn.pixabay.com/photo/2018/05/02/00/49/man-3367459_1280.png'),
                                    backgroundColor: Colors.grey[200],
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
                                onPressed: _logout, // <-- Memanggil fungsi _logout()
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    textStyle: const TextStyle(fontSize: 18)
                                ),
                            )
                        ],
                    ),
        );
    }
}
