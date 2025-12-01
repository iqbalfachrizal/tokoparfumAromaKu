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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              Colors.white,
              Colors.purple.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 0
                      ? LinearGradient(
                          colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home,
                  color: _selectedIndex == 0 ? Colors.white : Colors.grey,
                ),
              ),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 1
                      ? LinearGradient(
                          colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shopping_cart,
                  color: _selectedIndex == 1 ? Colors.white : Colors.grey,
                ),
              ),
              label: 'Keranjang',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 2
                      ? LinearGradient(
                          colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.feedback,
                  color: _selectedIndex == 2 ? Colors.white : Colors.grey,
                ),
              ),
              label: 'Kesan',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _selectedIndex == 3
                      ? LinearGradient(
                          colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: _selectedIndex == 3 ? Colors.white : Colors.grey,
                ),
              ),
              label: 'Profil',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
