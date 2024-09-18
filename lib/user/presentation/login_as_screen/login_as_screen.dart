import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../client_sign_in_screen/client_sign_in_screen.dart';

class LoginAsScreen extends StatefulWidget {
  @override
  _LoginAsScreenState createState() => _LoginAsScreenState();
}

class _LoginAsScreenState extends State<LoginAsScreen> {
  int _selectedRole = 0; // Track the selected role

  void _signIn() {
    if (_selectedRole == 0) {
      // Navigate to the ClientSignInScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ClientSignInScreen()),
      );
    } else {
      // Display toast for employee sign-in
      Fluttertoast.showToast(
        msg: "Signed In",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      // Placeholder: Add employee login screen navigation here
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Green background with rounded bottom corners
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
              child: Center(
                child: Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // White container with content
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40.0), // Spacing from the top
                    Container(
                      padding: EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10.0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 16.0),
                          Text(
                            "EcoNaga aims to enhance garbage collection services in Naga City.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 40.0),
                          Text(
                            "Log in as",
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<int>(
                                value: 0,
                                groupValue: _selectedRole,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                              ),
                              Text("Client"),
                              SizedBox(width: 20.0),
                              Radio<int>(
                                value: 1,
                                groupValue: _selectedRole,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                              ),
                              Text("Employee"),
                            ],
                          ),
                          SizedBox(height: 40.0),
                          ElevatedButton(
                            onPressed: _signIn, // Trigger the sign-in logic
                            child: Text(
                              "SIGN IN",
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              backgroundColor: Colors.green, // Background color
                              foregroundColor: Colors.white,  // Text color
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 40.0), // Spacing at the bottom
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
