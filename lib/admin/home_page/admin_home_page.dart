import 'package:econaga_prj/admin/home_page/truck_monitoring_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                return Text('Loading...', style: TextStyle(color: Colors.black));
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
              String firstLetter = email.isNotEmpty ? email[0].toUpperCase() : 'U'; // Default to 'U' if email is empty

              return Row(
                children: [
                  Text(
                    fullName, // Display the full name
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
                        _currentPage = 'Account'; // Update the page to 'Account'
                      });
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.green, // Set the background color to green
                      child: Text(
                        firstLetter, // Display the first letter of the email
                        style: TextStyle(
                          color: Colors.white, // Set the text color to white
                          fontSize: 24, // Adjust the font size for better visibility
                          fontWeight: FontWeight.bold, // Make the letter bold
                        ),
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
                    children: [
                      _buildListTile('Garbage Collection', null, 'GarbageCollection'),
                      _buildListTile('Burial Service', null, 'BurialService'),
                      _buildListTile('Lipat Bahay', null, 'LipatBahay'),
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
            child: _currentPage == 'Dashboard'
                ? DashboardContent()
                : _currentPage == 'GarbageCollection'
                ? AdminGarbageCollectionRequest()
                : _currentPage == 'BurialService'
                ? AdminBurialServiceRequest()
                : _currentPage == 'LipatBahay'
                ? AdminLipatBahayServiceRequest()
                : _currentPage == 'Complaints'
                ? ComplaintsOverview()
                : _currentPage == 'DriverMonitoring'
                ? DrivingMonitoringPage()
                : _currentPage == 'TruckMonitoring'
                ? TruckMonitoringPage()
                : _currentPage == 'Account'
                ? AdminAccountPage()
                : Center(child: Text('Content for $_currentPage')),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData? icon, String page, {Color color = Colors.green}) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: color) : null,
      title: Text(title),
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
