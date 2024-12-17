import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  // Modern green color palette
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFAED581);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color accentGreen = Color(0xFF69F0AE);

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
      _showSnackBar('Please enter your complaint.', Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    _showLoadingDialog();

    int retryCount = 0;
    while (retryCount < 3) {
      try {
        await _forceSubmitComplaint();
        Navigator.of(context).pop(); // Close the loading dialog
        _showSnackBar('Complaint submitted successfully!', primaryGreen);
        _complaintController.clear();
        break;
      } catch (e) {
        print('Error submitting complaint (attempt ${retryCount + 1}): $e');
        retryCount++;
        if (retryCount == 3) {
          Navigator.of(context).pop(); // Close the loading dialog
          _showSnackBar('Failed to submit complaint. Please try again later.', Colors.red);
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
    final complaintData = {
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
    };

    if (connectivityResult == ConnectivityResult.none) {
      await FirebaseFirestore.instance.collection('pending_complaints').add(complaintData);
    } else {
      await FirebaseFirestore.instance.collection('complaints').add(complaintData);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16),
    ));
  }

  void _showLoadingDialog() {
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
                  valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                ),
                SizedBox(height: 16),
                Text(
                  "Submitting complaint...",
                  style: GoogleFonts.montserrat(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Text(
          'Complaints Form',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
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
                  child: Text('Refresh', style: TextStyle(color: darkGreen)),
                ),
                PopupMenuItem<String>(
                  value: 'submitted',
                  child: Text('Submitted Complaints', style: TextStyle(color: darkGreen)),
                ),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.comment,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20),
                  _buildTextField(_firstNameController, 'First Name', Icons.person),
                  SizedBox(height: 20),
                  _buildTextField(_lastNameController, 'Last Name', Icons.person),
                  SizedBox(height: 20),
                  _buildTextField(_emailController, 'Email', Icons.email, enabled: false),
                  SizedBox(height: 20),
                  _buildTextField(_contactNumberController, 'Contact Number', Icons.phone),
                  SizedBox(height: 20),
                  _buildComplaintField(),
                  SizedBox(height: 30),
                  _buildSubmitButton(),
                ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: enabled ? primaryGreen : Colors.grey),
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: lightGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
      ),
    );
  }

  Widget _buildComplaintField() {
    return TextField(
      controller: _complaintController,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Enter your Complaint',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: lightGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitComplaint,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      child: Text(
        _isSubmitting ? 'SUBMITTING...' : 'SUBMIT',
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
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



