import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../client/client_home_page/client_home_page_container.dart';
import '../collector/collector_home_screen/collector_container_screen.dart';
import '../login_as_screen/login_as_screen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late Future<void> _navigationFuture;

  @override
  void initState() {
    super.initState();
    _navigationFuture = Future.delayed(Duration(seconds: 3), _navigateToNextScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _navigateToNextScreen,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green.shade300, Colors.green.shade700],
            ),
          ),
          child: SafeArea(
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
          'lib/components/assets/images/official_logo.png',
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
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('USERS_ACCOUNTS')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

          if (!data.containsKey('first_name') || !data.containsKey('last_name') || !data.containsKey('role')) {
            _showErrorToast("User data is incomplete.");
            return;
          }

          String fullName = "${data['first_name']} ${data['last_name']}";
          String role = data['role'];

          if (role == 'client') {
            _navigateTo(ClientHomeScreenContainer(userId: user.uid));
          } else if (role == 'collector') {
            _navigateTo(CollectorContainer(userId: user.uid));
          } else {
            _showErrorToast("Unexpected role: $role");
            return;
          }

          _showWelcomeToast(fullName);
        } else {
          _showErrorToast("User document does not exist.");
        }
      } catch (e) {
        _showErrorToast("Error fetching user data: $e");
      }
    } else {
      _navigateTo(LoginAsScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showWelcomeToast(String fullName) {
    Fluttertoast.showToast(
      msg: "Welcome, $fullName!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}