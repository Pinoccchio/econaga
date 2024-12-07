import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AccountPage.dart';
import 'notifications_page.dart';
import 'RequestPage.dart';
import 'client_home_page.dart';
import 'complaints_page/ComplaintsPage.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
