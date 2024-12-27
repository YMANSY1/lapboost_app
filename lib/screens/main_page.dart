import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lapboost_app/screens/cart_page.dart';
import 'package:lapboost_app/screens/home_page.dart';
import 'package:lapboost_app/screens/marketplace_page.dart';
import 'package:lapboost_app/screens/settings_page.dart';
import 'package:lapboost_app/screens/user_orders_display_page.dart';
import 'package:mysql1/mysql1.dart';

class MainPage extends StatefulWidget {
  final ResultRow user;

  const MainPage({super.key, required this.user});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Manage the selected index
  int _selectedIndex = 0;

  // Use an observable for dynamic app bar title
  final titleText = 'Welcome to Lapboost!'.obs;

  @override
  Widget build(BuildContext context) {
    // Define the pages based on the selected index
    final List<Widget> _pages = <Widget>[
      HomePage(user: widget.user), // Pass user data to HomePage
      UserOrdersDisplayPage(user: widget.user), // Pass user data to OrdersPage
      MarketplacePage(user: widget.user),
      SettingsPage(user: widget.user), // Pass user data to SettingsPage
    ];

    // Handle bottom navigation item taps
    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
        switch (index) {
          case 0:
            titleText.value = 'Welcome to Lapboost!';
            break;
          case 1:
            titleText.value = 'Your Orders';
            break;
          case 2:
            titleText.value = 'Marketplace';
            break;
          case 3:
            titleText.value = 'Settings';
            break;
          default:
            titleText.value = 'Welcome to Lapboost!';
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Obx(() => Text(titleText.value)), // Dynamic app bar title
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CartPage(
                          user: widget.user,
                        )));
              },
              icon: const Icon(Icons.shopping_cart))
        ],
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue, // Customize color
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped, // Switch pages
      ),
    );
  }
}
