import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      body: Center(
        child: Image.asset(
          'lib/components/assets/images/official_logo.png', // Path to your logo image in the assets folder
          width: 300, // Adjust the size for a bigger screen
          height: 300,
        ),
      ),
    );
  }
}
