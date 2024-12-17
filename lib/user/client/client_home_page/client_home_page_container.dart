import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AccountPage.dart';
import 'notifications_page.dart';
import 'RequestPage.dart';
import 'client_home_page.dart';
import 'complaints_page/ComplaintsPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ClientHomeScreenContainer extends StatefulWidget {
  final String userId;

  ClientHomeScreenContainer({required this.userId});

  @override
  _ClientHomeScreenContainerState createState() =>
      _ClientHomeScreenContainerState();
}

class _ClientHomeScreenContainerState
    extends State<ClientHomeScreenContainer> {
  int _selectedIndex = 2;
  int _notificationCount = 0;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      RequestPage(userId: widget.userId),
      NotificationPage(userId: widget.userId),
      ClientHomePage(onRequestNow: _navigateToRequestPage, userId: widget.userId),
      ComplaintsPage(userId: widget.userId),
      AccountPage(userId: widget.userId),
    ]);
    _listenToNotifications();
  }

  void _listenToNotifications() {
    // Fetch and calculate total pending notifications across collections
    FirebaseFirestore.instance
        .collectionGroup('GARBAGE_REQUESTS')
        .where('user_id', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      _updateNotificationCount();
    });

    FirebaseFirestore.instance
        .collectionGroup('BURIAL_REQUESTS')
        .where('user_id', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      _updateNotificationCount();
    });

    FirebaseFirestore.instance
        .collectionGroup('TRANSPORTATION_REQUESTS')
        .where('user_id', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      _updateNotificationCount();
    });
  }

  Future<void> _updateNotificationCount() async {
    try {
      final garbageRequests = await FirebaseFirestore.instance
          .collectionGroup('GARBAGE_REQUESTS')
          .where('user_id', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final burialRequests = await FirebaseFirestore.instance
          .collectionGroup('BURIAL_REQUESTS')
          .where('user_id', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final transportationRequests = await FirebaseFirestore.instance
          .collectionGroup('TRANSPORTATION_REQUESTS')
          .where('user_id', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        _notificationCount = garbageRequests.docs.length +
            burialRequests.docs.length +
            transportationRequests.docs.length;
      });
    } catch (e) {
      print('Error updating notification count: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        _notificationCount = 0; // Clear notification count when visiting Notifications page
      }
    });
  }

  void _navigateToRequestPage() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 300,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.exit_to_app,
                  size: 48,
                  color: Color(0xFF4CAF50),
                ).animate().scale(duration: 300.ms, curve: Curves.easeInOut),
                SizedBox(height: 20),
                Text(
                  'Exit App?',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Are you sure you want to exit the app?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        exit(0); // This will exit the app
                      },
                      child: Text('Exit'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 0
                  ? Icons.request_page
                  : Icons.request_page_outlined),
              label: 'Request',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(_selectedIndex == 1
                      ? Icons.notifications
                      : Icons.notifications_outlined),
                  if (_notificationCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '$_notificationCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Notification',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 2 ? Icons.home : Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 3
                  ? Icons.chat_bubble
                  : Icons.chat_bubble_outline),
              label: 'Complaints',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 4
                  ? Icons.person
                  : Icons.person_outline),
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
      ),
    );
  }
}

