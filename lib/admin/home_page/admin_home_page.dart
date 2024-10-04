import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../requests_page/admin_garbage_collection_request.dart';
import 'admin_dashboard.dart';
import 'admin_sign_in_page.dart';

class AdminHomePage extends StatefulWidget {
  final String userId;

  AdminHomePage({required this.userId});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String _currentPage = 'Dashboard';
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
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
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.green),
                onPressed: () {
                  // Notification functionality here
                },
                splashColor: Colors.grey.withOpacity(0.3),
                highlightColor: Colors.grey.withOpacity(0.1),
              ),
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '20',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 10),
          CircleAvatar(
            backgroundImage: AssetImage('lib/components/assets/images/sample-profile-pic.png'),
          ),
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
              return Text(userData['full_name'] ?? 'Unknown', style: TextStyle(color: Colors.black));
            },
          ),
          SizedBox(width: 10),
          IconButton(
            icon: Icon(Icons.person, color: Colors.green),
            onPressed: () {
              showChangeAccountInfoModal(context);
            },
            splashColor: Colors.grey.withOpacity(0.3),
            highlightColor: Colors.grey.withOpacity(0.1),
          ),
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
                  _buildListTile('Monitoring', Icons.monitor, 'Monitoring'),
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

  void showChangeAccountInfoModal(BuildContext context) {
    FirebaseFirestore.instance.collection('ADMIN_ACCOUNTS').doc(widget.userId).get().then((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        var userData = snapshot.data() as Map<String, dynamic>;
        fullNameController.text = userData['full_name'] ?? '';
        emailController.text = userData['email'] ?? '';

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          builder: (BuildContext context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
                    border: Border.all(
                      color: Colors.green,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Change Account Information',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildEditableProfileField(
                        Icons.person,
                        'Full Name',
                        'Enter your full name',
                        fullNameController,
                        borderColor: Colors.green,
                      ),
                      SizedBox(height: 20),
                      _buildEditableProfileField(
                        Icons.email,
                        'Email Address',
                        'Enter your email address',
                        emailController,
                        borderColor: Colors.green,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Change Password',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildEditableProfileField(
                        Icons.lock,
                        'Current Password',
                        'Enter your current password',
                        currentPasswordController,
                        isObscure: true,
                        borderColor: Colors.green,
                      ),
                      SizedBox(height: 20),
                      _buildEditableProfileField(
                        Icons.lock,
                        'New Password',
                        'Enter your new password',
                        newPasswordController,
                        isObscure: true,
                        borderColor: Colors.green,
                      ),
                      SizedBox(height: 20),
                      _buildEditableProfileField(
                        Icons.lock,
                        'Confirm New Password',
                        'Re-enter your new password',
                        confirmPasswordController,
                        isObscure: true,
                        borderColor: Colors.green,
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          _updateAccountInfo(context);
                        },
                        child: Text('Update Information'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      } else {
        _showSnackbar(context, "No user data found", Colors.red);
      }
    }).catchError((error) {
      _showSnackbar(context, "Error fetching user data: $error", Colors.red);
    });
  }

  Widget _buildEditableProfileField(
      IconData icon,
      String label,
      String hint,
      TextEditingController controller, {
        bool isObscure = false,
        Color borderColor = Colors.green
      }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green),
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
      ),
    );
  }

  void _updateAccountInfo(BuildContext context) {
    String currentPassword = currentPasswordController.text.trim();
    String newPassword = newPasswordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackbar(context, "All password fields are required for password change.", Colors.red);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackbar(context, "New passwords do not match.", Colors.red);
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      user.reauthenticateWithCredential(credential).then((_) {
        user.updatePassword(newPassword).then((_) {
          FirebaseFirestore.instance.collection('ADMIN_ACCOUNTS').doc(widget.userId).update({
            'full_name': fullNameController.text.trim(),
            'email': emailController.text.trim(),
          }).then((_) {
            _showSnackbar(context, "Account information and password updated successfully.", Colors.green);
            Navigator.of(context).pop();
          }).catchError((error) {
            _showSnackbar(context, "Error updating account information: $error", Colors.red);
          });
        }).catchError((error) {
          _showSnackbar(context, "Error updating password: $error", Colors.red);
        });
      }).catchError((error) {
        _showSnackbar(context, "Error authenticating: $error", Colors.red);
      });
    } else {
      _showSnackbar(context, "No user is currently signed in.", Colors.red);
    }
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}