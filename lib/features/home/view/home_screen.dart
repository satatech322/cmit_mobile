import 'package:flutter/material.dart';
import 'package:cmit/features/home/widgets/home_top_section.dart';
import 'package:cmit/features/home/view/custom_drawer.dart';
import 'package:cmit/features/home/view/notification_screen.dart';
import 'package:cmit/features/inquiries/view/inquiries_screen.dart';
import 'package:cmit/features/home/view/profile_screen.dart';
import 'package:cmit/features/home/widgets/custom_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeTopSection(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            ],
          ),
        );
      case 1:
        return const InquiriesScreen();
      case 2:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      // Conditionally show AppBar only when _currentIndex is 0 (Home tab)
      appBar: _currentIndex == 0
          ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          "Home",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      )
          : null, // No AppBar for other tabs
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: _getPage(_currentIndex),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}