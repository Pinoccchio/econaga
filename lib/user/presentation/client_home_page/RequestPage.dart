import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RequestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background for the lower section
      appBar: AppBar(
        backgroundColor: Color(0xFFAEF989), // Set AppBar color
        elevation: 0,
        title: Text(
          'CHOOSE SERVICES',
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true, // Center the title
      ),
      body: Column(
        children: [
          // Top green gradient background
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFAEF989), // Light green
                  Color(0xFF68D88B), // Darker green
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(100),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The logo image with a circular white background
                Container(
                  width: 150, // Adjust size as needed
                  height: 150, // Adjust size as needed
                  decoration: BoxDecoration(
                    color: Colors.white, // White background
                    shape: BoxShape.circle, // Circular shape
                  ),
                  alignment: Alignment.center,
                  child: ClipOval(
                    child: Image.asset(
                      'lib/components/assets/images/official_logo.png', // Replace with the actual logo path
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover, // Ensure the image fits well
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50),
          // Buttons for services
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              children: [
                // Transportation Services button
                ElevatedButton(
                  onPressed: () {
                    // Handle Transportation Services action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: BorderSide(color: Colors.black12), // Optional border
                    padding: EdgeInsets.symmetric(vertical: 16),
                    elevation: 4, // Add shadow effect
                  ),
                  child: Center(
                    child: Text(
                      'Transportation Services',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Garbage Collection button
                ElevatedButton(
                  onPressed: () {
                    // Handle Garbage Collection action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: BorderSide(color: Colors.black12), // Optional border
                    padding: EdgeInsets.symmetric(vertical: 16),
                    elevation: 4, // Add shadow effect
                  ),
                  child: Center(
                    child: Text(
                      'Garbage Collection',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
