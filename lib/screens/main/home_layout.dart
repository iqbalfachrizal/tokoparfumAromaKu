import 'package:flutter/material.dart';
import 'package:arunika/screens/main/cart_screen.dart';
import 'package:arunika/screens/main/feedback_screen.dart';
import 'package:arunika/screens/main/profile_screen.dart';
import 'package:arunika/screens/main/product_list_screen.dart'; 

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  _HomeLayoutState createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _selectedIndex = 0;

  // --- DAFTAR HALAMAN ---
  static const List<Widget> _widgetOptions = <Widget>[
    ProductListScreen(), 
    CartScreen(),
    FeedbackScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      // ------------------------------------
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Keranjang'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Kesan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}