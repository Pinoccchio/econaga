import 'package:econaga_prj/user/collector/collector_home_screen/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'approve_service_screen/approve_service_screen.dart';
import 'collector_home_page_screen.dart';

class CollectorContainer extends StatefulWidget {
  final String userId; // Add this line

  CollectorContainer({required this.userId}); // Update constructor

  @override
  _CollectorContainerState createState() => _CollectorContainerState();
}

class _CollectorContainerState extends State<CollectorContainer> {
  int _currentIndex = 1;

  late List<Widget> _screens; // Declare screens

  @override
  void initState() {
    super.initState();
    // Initialize screens in initState
    _screens = [
      ApproveServicesScreen(),
      CollectorHomePage(userId: widget.userId),
      ProfileScreen(userId: widget.userId), // Access widget.userId
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Approved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
