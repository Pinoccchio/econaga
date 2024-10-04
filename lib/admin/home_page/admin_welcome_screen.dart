import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'admin_sign_in_page.dart'; // Ensure this is the correct import for your admin login page
import 'admin_home_page.dart'; // Ensure this is the correct import for your admin home page

class AdminWelcomeScreen extends StatefulWidget {
  @override
  _AdminWelcomeScreenState createState() => _AdminWelcomeScreenState();
}

class _AdminWelcomeScreenState extends State<AdminWelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the next screen after a delay
    Future.delayed(Duration(seconds: 3), _navigateToNextScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _navigateToNextScreen,
        child: Container(
          width: double.infinity, // Make the container full width
          height: double.infinity, // Make the container full height
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green.shade300, Colors.green.shade700],
            ),
          ),
          child: SafeArea(
            child: Center( // Use Center widget for centering
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  SizedBox(height: 40),
                  _buildWelcomeText(),
                  SizedBox(height: 20),
                  _buildDescription(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'lib/components/assets/images/official_logo.png', // Update the path to the logo image as needed
          fit: BoxFit.cover,
        ),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          "Welcome to",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          "EcoNaga",
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildDescription() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        "Schedule your garbage collection with just a tap and help us make a positive impact on the environment, one pickup at a time!",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is already logged in
      print("User is already logged in: ${user.uid}");
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('ADMIN_ACCOUNTS') // Ensure this is the correct collection for admin accounts
            .doc(user.uid)
            .get();

        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

          // Check for necessary fields
          if (!data.containsKey('full_name') || !data.containsKey('role')) {
            _showErrorSnackBar("User data is incomplete.");
            print("Incomplete user data for user: ${user.uid}");
            return;
          }

          String fullName = data['full_name']; // Get full name
          String role = data['role']; // Get role

          print("User data: Full Name: $fullName, Role: $role");

          // Navigate to admin home page
          if (role == 'admin') {
            _navigateTo(AdminHomePage(userId: user.uid)); // Change to your admin home screen
            _showWelcomeSnackBar(fullName);
          } else {
            _showErrorSnackBar("Unexpected role: $role");
            print("Unexpected role for user: ${user.uid}, Role: $role");
            return;
          }
        } else {
          _showErrorSnackBar("User document does not exist.");
          print("User document does not exist for user: ${user.uid}");
        }
      } catch (e) {
        _showErrorSnackBar("Error fetching user data: $e");
        print("Error fetching user data for user: ${user.uid}, Error: $e");
      }
    } else {
      // User is not logged in, navigate to the admin sign-in page
      print("User is not logged in. Navigating to admin login page.");
      _navigateTo(AdminLoginPage());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showWelcomeSnackBar(String fullName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Welcome, $fullName!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
