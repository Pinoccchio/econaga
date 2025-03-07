import 'package:econaga_prj/admin/home_page/truck_monitoring_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../accounts_page/admin_account_page.dart';
import '../complaints_page/admin_complaints_page.dart';
import '../requests_page/admin_burial_service.dart';
import '../requests_page/admin_garbage_collection_request.dart';
import '../requests_page/admin_lipat_bahay_service.dart';
import 'admin_dashboard.dart';
import 'admin_sign_in_page.dart';
import 'driving_monitoring_page.dart';

class AdminHomePage extends StatefulWidget {
  final String userId;

  AdminHomePage({required this.userId});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String _currentPage = 'Dashboard';
  bool isDrawerOpen = true;
  int newGarbageRequests = 0;
  int newBurialRequests = 0;
  int newTransportRequests = 0;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  void _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    _listenForNewRequests();
  }

  void _listenForNewRequests() {
    _listenToCollection('GARBAGE_REQUESTS', (count) => setState(() => newGarbageRequests = count));
    _listenToCollection('BURIAL_REQUESTS', (count) => setState(() => newBurialRequests = count));
    _listenToCollection('TRANSPORTATION_REQUESTS', (count) => setState(() => newTransportRequests = count));
  }

  void _listenToCollection(String collectionName, Function(int) updateCount) {
    DateTime lastChecked = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('${collectionName}_last_checked') ?? 0
    );

    FirebaseFirestore.instance
        .collection(collectionName)
        .where('status', isEqualTo: 'pending')
        .where('created_at', isGreaterThan: lastChecked)
        .snapshots()
        .listen((snapshot) {
      updateCount(snapshot.docs.length);
    });
  }

  Future<void> _updateLastChecked(String collectionName) async {
    await prefs.setInt('${collectionName}_last_checked', DateTime.now().millisecondsSinceEpoch);
    // Reset the corresponding badge count
    switch (collectionName) {
      case 'GARBAGE_REQUESTS':
        setState(() => newGarbageRequests = 0);
        break;
      case 'BURIAL_REQUESTS':
        setState(() => newBurialRequests = 0);
        break;
      case 'TRANSPORTATION_REQUESTS':
        setState(() => newTransportRequests = 0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text('ECONAGA', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(isDrawerOpen ? Icons.menu_open : Icons.menu),
          onPressed: () {
            setState(() {
              isDrawerOpen = !isDrawerOpen;
            });
          },
        ),
        actions: [
          SizedBox(width: 10),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('ADMIN_ACCOUNTS').doc(widget.userId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {

              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Text('User not found', style: TextStyle(color: Colors.black));
              }
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              String email = userData['email'] ?? '';
              String fullName = userData['full_name'] ?? '';
              String? profilePictureUrl = userData['profile_picture_url'] as String?;
              String firstLetter = email.isNotEmpty ? email[0].toUpperCase() : 'U';

              return Row(
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentPage = 'Account';
                      });
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.green,
                      child: ClipOval(
                        child: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: profilePictureUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          errorWidget: (context, url, error) => _buildDefaultProfileImage(),
                        )
                            : _buildDefaultProfileImage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                ],
              );
            },
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Row(
        children: [
          if (isDrawerOpen)
            Container(
              width: 250,
              color: Colors.white,
              child: ListView(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: Colors.white),
                    child: Row(
                      children: [
                        Image.asset('lib/components/assets/images/official_logo.png', width: 50),
                        SizedBox(width: 10),
                        Text('ECONAGA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  _buildListTile('Dashboard', Icons.dashboard, 'Dashboard'),
                  ExpansionTile(
                    leading: Icon(Icons.request_page, color: Colors.green),
                    title: Text('Request'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRequestBadge(),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                    children: [
                      _buildListTile('Garbage Collection', null, 'GarbageCollection', badgeCount: newGarbageRequests),
                      _buildListTile('Burial Service', null, 'BurialService', badgeCount: newBurialRequests),
                      _buildListTile('Transportation', null, 'Transportation', badgeCount: newTransportRequests),
                    ],
                  ),
                  ExpansionTile(
                    leading: Icon(Icons.monitor, color: Colors.green),
                    title: Text('Monitoring'),
                    children: [
                      _buildListTile('Driver Monitoring', null, 'DriverMonitoring'),
                      _buildListTile('Truck Monitoring', null, 'TruckMonitoring'),
                    ],
                  ),
                  _buildListTile('Complaints', Icons.comment, 'Complaints'),
                  _buildListTile('Account', Icons.account_circle, 'Account'),
                  Divider(),
                  _buildListTile('Log out', Icons.logout, 'Logout', color: Colors.red),
                ],
              ),
            ),
          Expanded(
            child: _buildPageContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultProfileImage() {
    return Image.asset(
      'lib/components/assets/images/official_logo.png',
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );
  }

  Widget _buildPageContent() {
    switch (_currentPage) {
      case 'Dashboard':
        return DashboardContent();
      case 'GarbageCollection':
        _updateLastChecked('GARBAGE_REQUESTS');
        return AdminGarbageCollectionRequest();
      case 'BurialService':
        _updateLastChecked('BURIAL_REQUESTS');
        return AdminBurialServiceRequest();
      case 'Transportation':
        _updateLastChecked('TRANSPORTATION_REQUESTS');
        return AdminLipatBahayServiceRequest();
      case 'Complaints':
        return ComplaintsOverview();
      case 'DriverMonitoring':
        return DrivingMonitoringPage();
      case 'TruckMonitoring':
        return TruckMonitoringPage();
      case 'Account':
        return AdminAccountPage();
      default:
        return Center(child: Text('Content for $_currentPage'));
    }
  }

  Widget _buildListTile(String title, IconData? icon, String page, {Color color = Colors.green, int badgeCount = 0}) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: color) : null,
      title: Row(
        children: [
          Text(title),
          if (badgeCount > 0)
            Container(
              margin: EdgeInsets.only(left: 8),
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: Text(
                  badgeCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        if (page == 'Logout') {
          _handleLogout(context);
        } else {
          setState(() => _currentPage = page);
        }
      },
      splashColor: Colors.grey.withOpacity(0.3),
      hoverColor: Colors.grey.withOpacity(0.1),
    );
  }

  Widget _buildRequestBadge() {
    int totalNewRequests = newGarbageRequests + newBurialRequests + newTransportRequests;
    if (totalNewRequests > 0) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            totalNewRequests.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return SizedBox(width: 24, height: 24);
  }

  void _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminLoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: $e"), backgroundColor: Colors.red),
      );
    }
  }
}

