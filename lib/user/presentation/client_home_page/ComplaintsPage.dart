import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ComplaintsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF86CF64), // Set body background color
      appBar: AppBar(
        backgroundColor: Color(0xFF9CE47C), // Light green color
        elevation: 0,
        title: Text(
          'COMPLAINTS FORM',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onSelected: (String value) {
              if (value == 'refresh') {
                // Handle refresh action
                print('Refresh clicked');
              } else if (value == 'submitted') {
                // Show submitted complaints
                _showSubmittedComplaints(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Text(
                    'Refresh',
                    style: TextStyle(color: Colors.white), // White text color
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'submitted',
                  child: Text(
                    'Submitted Complaints',
                    style: TextStyle(color: Colors.white), // White text color
                  ),
                ),
              ];
            },
            color: Color(0xFF4D4D4D), // Set PopupMenu background color to dark gray
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              // Name field
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person),
                  hintText: 'John Oliver Rivero',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              // Email field
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  hintText: 'JohnoliverRivero@gmail.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              // Phone field
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone),
                  hintText: '095678472827',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              // Complaints text field
              TextField(
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your Complaints',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 30),
              // Submit button
              ElevatedButton(
                onPressed: () {
                  // Handle submit action
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: Text(
                  'SUBMIT',
                  style: GoogleFonts.lato(
                    fontSize: 16, // Smaller font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmittedComplaints(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            'Submitted Complaints',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Here you can show the list of submitted complaints.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
