import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../designs/app_colors.dart';
import 'SubmittedComplainsPage.dart';

class ComplaintsPage extends StatefulWidget {
  final String userId; // Variable to hold the userId

  ComplaintsPage({Key? key, required this.userId}) : super(key: key); // Constructor

  @override
  _ComplaintsPageState createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  late String _firstName;
  late String _lastName;
  late String _email;
  late String _contactNumber;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _complaintController = TextEditingController(); // Added controller for complaint

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data on initialization
  }

  Future<void> _fetchUserData() async {
    try {
      print('Fetching user data for userId: ${widget.userId}');
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(widget.userId) // Access document by userId
          .get();

      if (doc.exists) {
        setState(() {
          _firstName = doc['first_name'] ?? '';
          _lastName = doc['last_name'] ?? '';
          _email = doc['email'] ?? '';
          _contactNumber = doc['phone_number'] ?? '';

          // Update controllers with fetched data
          _firstNameController.text = _firstName;
          _lastNameController.text = _lastName;
          _emailController.text = _email;
          _contactNumberController.text = _contactNumber;
        });
        print('User data fetched successfully:');
        print('First Name: $_firstName');
        print('Last Name: $_lastName');
        print('Email: $_email');
        print('Contact Number: $_contactNumber');
      } else {
        print('No user data found for userId: ${widget.userId}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _submitComplaint() async {
    try {
      await FirebaseFirestore.instance.collection('COMPLAINTS').add({
        'userId': widget.userId,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'contact_number': _contactNumberController.text,
        'complaint': _complaintController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Complaint submitted successfully!'),
        backgroundColor: Colors.green,
      ));
      // Clear the form
      _complaintController.clear();
    } catch (e) {
      print('Error submitting complaint: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to submit complaint. Please try again later.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origColor, // Set body background color
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Light green color
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
                print('Refresh clicked');
              } else if (value == 'submitted') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubmittedComplaintsPage(userId: widget.userId),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Text(
                    'Refresh',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'submitted',
                  child: Text(
                    'Submitted Complaints',
                    style: TextStyle(color: Colors.white),
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
              // First Name field
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person),
                  hintText: 'First Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              // Last Name field
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Last Name',
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
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  hintText: 'Email',
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
                controller: _contactNumberController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone),
                  hintText: 'Contact Number',
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
                controller: _complaintController,
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
                onPressed: _submitComplaint,
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
}
