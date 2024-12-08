import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../designs/app_colors.dart';
import 'SubmittedComplainsPage.dart';

class ComplaintsPage extends StatefulWidget {
  final String userId;

  ComplaintsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ComplaintsPageState createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _complaintController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _initializeFirestore();
  }

  void _initializeFirestore() {
    FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        setState(() {
          _firstNameController.text = doc['first_name'] ?? '';
          _lastNameController.text = doc['last_name'] ?? '';
          _emailController.text = doc['email'] ?? '';
          _contactNumberController.text = doc['phone_number'] ?? '';
        });
      } else {
        print('No user data found for userId: ${widget.userId}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _submitComplaint() async {
    if (_complaintController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter your complaint.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryGreen),
                ),
                SizedBox(height: 16),
                Text(
                  "Submitting complaint...",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    int retryCount = 0;
    while (retryCount < 3) {
      try {
        await _forceSubmitComplaint();
        Navigator.of(context).pop(); // Close the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Complaint submitted successfully!'),
          backgroundColor: AppColors.secondaryGreen,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ));
        _complaintController.clear();
        break;
      } catch (e) {
        print('Error submitting complaint (attempt ${retryCount + 1}): $e');
        retryCount++;
        if (retryCount == 3) {
          Navigator.of(context).pop(); // Close the loading dialog
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to submit complaint. Please try again later.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ));
        } else {
          await Future.delayed(Duration(seconds: 2)); // Wait before retrying
        }
      }
    }

    setState(() {
      _isSubmitting = false;
    });
  }


  Future<void> _forceSubmitComplaint() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // If offline, add to a local collection for syncing later
      await FirebaseFirestore.instance.collection('pending_complaints').add({
        'userId': widget.userId,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'contact_number': _contactNumberController.text,
        'complaint': _complaintController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'open',
        'messages': [
          {
            'content': _complaintController.text,
            'senderId': widget.userId,
            'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
          }
        ],
        'lastMessage': _complaintController.text,
        'lastMessageTimestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
      });
    } else {
      // If online, submit directly
      await FirebaseFirestore.instance.collection('complaints').add({
        'userId': widget.userId,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'contact_number': _contactNumberController.text,
        'complaint': _complaintController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'open',
        'messages': [
          {
            'content': _complaintController.text,
            'senderId': widget.userId,
            'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
          }
        ],
        'lastMessage': _complaintController.text,
        'lastMessageTimestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
                _fetchUserData();
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
                  child: Text('Refresh', style: TextStyle(color: Colors.white)),
                ),
                PopupMenuItem<String>(
                  value: 'submitted',
                  child: Text('Submitted Complaints', style: TextStyle(color: Colors.white)),
                ),
              ];
            },
            color: Color(0xFF4D4D4D),
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
              _buildTextField(_firstNameController, 'First Name', Icons.person),
              SizedBox(height: 20),
              _buildTextField(_lastNameController, 'Last Name', Icons.person),
              SizedBox(height: 20),
              _buildTextField(_emailController, 'Email', Icons.email),
              SizedBox(height: 20),
              _buildTextField(_contactNumberController, 'Contact Number', Icons.phone),
              SizedBox(height: 20),
              TextField(
                controller: _complaintController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your Complaint',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: Text(
                  _isSubmitting ? 'SUBMITTING...' : 'SUBMIT',
                  style: GoogleFonts.lato(
                    fontSize: 16,
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

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _complaintController.dispose();
    super.dispose();
  }
}

