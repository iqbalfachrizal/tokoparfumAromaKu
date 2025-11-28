import 'package:flutter/material.dart';
import 'package:arunika/screens/auth/login_screen.dart';
import 'package:arunika/screens/main/home_layout.dart';
import 'package:arunika/screens/splash_screen.dart';
import 'package:arunika/services/notification_service.dart';
import 'package:arunika/services/session_manager.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Notifikasi dan Timezone
  await NotificationService().init();
  tz.initializeTimeZones();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AromaLoca',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.purple, fontSize: 20, fontWeight: FontWeight.bold),
        )
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: SessionManager().isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          } else if (snapshot.hasData && snapshot.data == true) {
            return const HomeLayout();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}