import 'package:flutter/material.dart';
import 'AccountPage.dart';
import 'NotificationPage.dart';
import 'RequestPage.dart';
import 'client_home_page.dart';
import 'complaints_page/ComplaintsPage.dart';

class ClientHomeScreenContainer extends StatefulWidget {
  final String userId; // Add a userId parameter

  ClientHomeScreenContainer({required this.userId}); // Constructor

  @override
  _ClientHomeScreenContainerState createState() => _ClientHomeScreenContainerState();
}

class _ClientHomeScreenContainerState extends State<ClientHomeScreenContainer> {
  int _selectedIndex = 2; // Default to the Home tab (index 2)

  // List of pages for each BottomNavigationBar item
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      RequestPage(userId: widget.userId), // Pass userId to RequestPage
      NotificationPage(),
      ClientHomePage(onRequestNow: _navigateToRequestPage, userId: widget.userId),
      ComplaintsPage(),
      AccountPage(userId: widget.userId), // Pass userId to AccountPage
    ]);
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToRequestPage() {
    setState(() {
      _selectedIndex = 0; // Navigate to Request tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages, // Keep state of all pages
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 0 ? Icons.request_page : Icons.request_page_outlined),
            label: 'Request',
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 1 ? Icons.notifications : Icons.notifications_outlined),
            label: 'Notification',
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 2 ? Icons.home : Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 3 ? Icons.chat_bubble : Icons.chat_bubble_outline),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 4 ? Icons.person : Icons.person_outline),
            label: 'Account',
          ),
        ],
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8.0,
        iconSize: 24,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        enableFeedback: true,
      ),
    );
  }
}
