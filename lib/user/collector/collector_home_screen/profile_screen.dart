import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  ProfileScreen({required this.userId});

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'PROFILE',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'lib/components/assets/images/official_logo.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showSettingsModal(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('USERS_ACCOUNTS')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text('User not found'));
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildProfileHeader(context, userData),
                      SizedBox(height: 24),
                      _buildProfileInfo(userData),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> userData) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: () => _showProfileDialog(context, userData['profile_picture'] ?? ''),
              child: CircleAvatar(
                radius: 60,
                backgroundImage: userData['profile_picture'] != null
                    ? NetworkImage(userData['profile_picture'])
                    : AssetImage('lib/components/assets/images/default_profile_pic.jpg') as ImageProvider,
              ),
            ),
            IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: Icon(Icons.camera_alt, color: Colors.green),
              ),
              onPressed: () => _updateProfilePicture(context),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          '${userData['first_name']} ${userData['middle_name']} ${userData['last_name']}',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          'Eco Warrior',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> userData) {
    return Column(
      children: [
        _buildProfileField(Icons.email, 'Email', userData['email'] ?? 'N/A'),
        _buildProfileField(Icons.phone, 'Mobile Number', userData['phone_number'] ?? 'N/A'),
        _buildProfileField(Icons.cake, 'Date of Birth', userData['date_of_birth'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildProfileField(IconData icon, String label, String value) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              _buildSettingsOption(Icons.lock, 'Change password', () {
                _showChangePasswordModal(context);
              }),
              _buildSettingsOption(Icons.edit, 'Change Account information', () {
                _showChangeAccountInfoModal(context);
              }),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Fluttertoast.showToast(
                    msg: "Signed out successfully!",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                  SystemNavigator.pop();
                },
                child: Text(
                  'SIGN OUT',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.1),
        child: Icon(icon, color: Colors.green),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showProfileDialog(BuildContext context, String profileImageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 100,
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : AssetImage('lib/components/assets/images/default_profile_pic.jpg') as ImageProvider,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProfilePicture(BuildContext context) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        String fileName = 'clients/$userId/profile_pic/${DateTime.now().millisecondsSinceEpoch}.jpg';
        File file = File(image.path);
        await _storage.ref(fileName).putFile(file);

        String downloadUrl = await _storage.ref(fileName).getDownloadURL();

        await FirebaseFirestore.instance
            .collection('USERS_ACCOUNTS')
            .doc(userId)
            .update({'profile_picture': downloadUrl});

        Fluttertoast.showToast(
          msg: "Profile picture updated successfully.",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Failed to update profile picture: $e",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  void _showChangePasswordModal(BuildContext context) {
    final TextEditingController _currentPasswordController = TextEditingController();
    final TextEditingController _newPasswordController = TextEditingController();
    final TextEditingController _confirmPasswordController = TextEditingController();

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
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Change Password',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                _buildPasswordField('Current Password', _currentPasswordController, true),
                SizedBox(height: 20),
                _buildPasswordField('New Password', _newPasswordController, true),
                SizedBox(height: 20),
                _buildPasswordField('Confirm Password', _confirmPasswordController, true),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  ),
                  onPressed: () async {
                    String currentPassword = _currentPasswordController.text;
                    String newPassword = _newPasswordController.text;
                    String confirmPassword = _confirmPasswordController.text;

                    if (newPassword == confirmPassword) {
                      try {
                        User? user = FirebaseAuth.instance.currentUser;
                        AuthCredential credential = EmailAuthProvider.credential(
                          email: user!.email!,
                          password: currentPassword,
                        );

                        await user.reauthenticateWithCredential(credential);
                        await user.updatePassword(newPassword);
                        Fluttertoast.showToast(
                          msg: "Password updated successfully!",
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                        );
                        Navigator.of(context).pop();
                      } catch (e) {
                        Fluttertoast.showToast(
                          msg: "Error updating password: ${e.toString()}",
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                      }
                    } else {
                      Fluttertoast.showToast(
                        msg: "Passwords do not match!",
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  },
                  child: Text(
                    'Update Password',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscureText) {
    bool _obscureText = obscureText;

    return StatefulBuilder(
      builder: (context, setState) {
        return TextField(
          controller: controller,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(color: Colors.black87),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _showChangeAccountInfoModal(BuildContext context) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('USERS_ACCOUNTS')
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      Fluttertoast.showToast(
        msg: "No user data found",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    TextEditingController emailController = TextEditingController(text: userData['email'] ?? '');
    TextEditingController phoneController = TextEditingController(text: userData['phone_number'] ?? '');
    TextEditingController dobController = TextEditingController(text: userData['date_of_birth'] ?? '');

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
                    Icons.email,
                    'Email Address',
                    'Change email address',
                    emailController,
                    isEditable: false,
                  ),
                  SizedBox(height: 20),
                  _buildEditableProfileField(
                    Icons.phone,
                    'Mobile Number',
                    'Change Mobile Number',
                    phoneController,
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      DateTime initialDate;
                      try {
                        initialDate = DateTime.parse(dobController.text);
                        if (initialDate.isAfter(DateTime.now())) {
                          initialDate = DateTime.now();
                        }
                      } catch (e) {
                        initialDate = DateTime.now();
                      }

                      DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (selectedDate != null) {
                        dobController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
                      }
                    },
                    child: AbsorbPointer(
                      child: _buildEditableProfileField(
                        Icons.calendar_today,
                        'Date of Birth',
                        'DD/MM/YYYY',
                        dobController,
                        isEditable: true,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    ),
                    onPressed: () async {
                      try {
                        await _updateUserInformation(
                          emailController.text,
                          phoneController.text,
                          dobController.text,
                        );

                        Fluttertoast.showToast(
                          msg: "Information updated successfully!",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );

                        Navigator.pop(context);
                      } catch (error) {
                        Fluttertoast.showToast(
                          msg: "Error updating information: $error",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      }
                    },
                    child: Text(
                      'Save Information',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditableProfileField(
      IconData icon,
      String label,
      String hint,
      TextEditingController controller, {
        bool isEditable = true,
      }) {
    return TextField(
      controller: controller,
      enabled: isEditable,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black87),
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isEditable ? Colors.white : Colors.grey[200],
      ),
      readOnly: !isEditable,
    );
  }

  Future<void> _updateUserInformation(
      String email,
      String phoneNumber,
      String dateOfBirth,
      ) async {
    if (email.isEmpty && phoneNumber.isEmpty && dateOfBirth.isEmpty) {
      Fluttertoast.showToast(
        msg: "No changes detected. Please enter new information.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    Map<String, dynamic> updates = {};

    if (email.isNotEmpty) {
      updates['email'] = email;
    }
    if (phoneNumber.isNotEmpty) {
      updates['phone_number'] = phoneNumber;
    }
    if (dateOfBirth.isNotEmpty) {
      updates['date_of_birth'] = dateOfBirth;
    }

    if (updates.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('USERS_ACCOUNTS')
            .doc(userId)
            .update(updates);

        Fluttertoast.showToast(
          msg: "Information updated successfully!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Failed to update information: $e",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }
}