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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import '../../login_as_screen/login_as_screen.dart';

class AccountPage extends StatefulWidget {
  final String userId;

  AccountPage({required this.userId});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? selectedRegion;
  String? selectedProvince;
  String? selectedMunicipality;
  String? selectedBarangay;

  // Modern green color palette
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFAED581);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color accentGreen = Color(0xFF69F0AE);

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
                style: GoogleFonts.montserrat(
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
                        colors: [Colors.transparent, primaryGreen.withOpacity(0.7)],
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
                  .doc(widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryGreen));
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
              onTap: () => _showProfileDialog(context, userData['selfieImageUrl'] ?? ''),
              child: CircleAvatar(
                radius: 60,
                backgroundImage: userData['selfieImageUrl'] != null
                    ? NetworkImage(userData['selfieImageUrl'])
                    : AssetImage('lib/components/assets/images/default_profile_pic.jpg') as ImageProvider,
                backgroundColor: lightGreen,
              ),
            ),
            IconButton(
              icon: CircleAvatar(
                backgroundColor: accentGreen.withOpacity(0.8),
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              onPressed: () => _updateProfilePicture(context),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          '${userData['first_name']} ${userData['middle_name']} ${userData['last_name']}',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        Text(
          userData['role'] ?? 'User',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: primaryGreen,
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
        _buildProfileField(Icons.location_on, 'Address', userData['address'] ?? 'N/A'),
        _buildProfileField(Icons.access_time, 'Created At', _formatTimestamp(userData['created_at'])),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return DateFormat('MMMM d, yyyy \'at\' h:mm:ss a').format(timestamp.toDate());
    } else if (timestamp is String) {
      return DateFormat('MMMM d, yyyy \'at\' h:mm:ss a').format(DateTime.parse(timestamp));
    }
    return 'N/A';
  }

  Widget _buildProfileField(IconData icon, String label, String value) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: lightGreen.withOpacity(0.3),
          child: Icon(icon, color: darkGreen),
        ),
        title: Text(
          label,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: darkGreen,
          ),
        ),
        subtitle: Text(
          value,
          style: GoogleFonts.montserrat(
            color: Colors.black87,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  void _showProfileDialog(BuildContext context, String profileImageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
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
              Hero(
                tag: 'profileImage',
                child: CircleAvatar(
                  radius: 100,
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : AssetImage('lib/components/assets/images/default_profile_pic.jpg') as ImageProvider,
                  backgroundColor: lightGreen,
                ),
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
        String fileName = 'clients/${widget.userId}/selfie_image/${DateTime.now().millisecondsSinceEpoch}.jpg';
        File file = File(image.path);
        await _storage.ref(fileName).putFile(file);

        String downloadUrl = await _storage.ref(fileName).getDownloadURL();

        await FirebaseFirestore.instance
            .collection('USERS_ACCOUNTS')
            .doc(widget.userId)
            .update({'selfieImageUrl': downloadUrl});

        Fluttertoast.showToast(
          msg: "Profile picture updated successfully.",
          backgroundColor: primaryGreen,
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

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
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
                    backgroundColor: primaryGreen,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginAsScreen()),
                        (Route<dynamic> route) => false,
                  );
                },
                child: Text(
                  'SIGN OUT',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: primaryGreen,
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
        backgroundColor: lightGreen.withOpacity(0.3),
        child: Icon(icon, color: darkGreen),
      ),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w500,
          color: darkGreen,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: primaryGreen),
      onTap: onTap,
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  void _showChangePasswordModal(BuildContext context) {
    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

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
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                SizedBox(height: 20),
                _buildPasswordField('Current Password', currentPasswordController, true),
                SizedBox(height: 20),
                _buildPasswordField('New Password', newPasswordController, true),
                SizedBox(height: 20),
                _buildPasswordField('Confirm New Password', confirmPasswordController, true),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  ),
                  onPressed: () async {
                    if (newPasswordController.text != confirmPasswordController.text) {
                      Fluttertoast.showToast(
                        msg: "New passwords do not match!",
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                      return;
                    }

                    try {
                      User? user = FirebaseAuth.instance.currentUser;

                      if (user != null) {
                        AuthCredential credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: currentPasswordController.text,
                        );

                        await user.reauthenticateWithCredential(credential);
                        await user.updatePassword(newPasswordController.text);

                        Fluttertoast.showToast(
                          msg: "Password changed successfully!",
                          backgroundColor: primaryGreen,
                          textColor: Colors.white,
                        );

                        Navigator.pop(context);
                      }
                    } catch (e) {
                      Fluttertoast.showToast(
                        msg: "Failed to change password: $e",
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  },
                  child: Text(
                    'Change Password',
                    style: GoogleFonts.montserrat(color: Colors.white),
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
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: darkGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
      ),
    );
  }

  void _showChangeAccountInfoModal(BuildContext context) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('USERS_ACCOUNTS')
        .doc(widget.userId)
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

    TextEditingController firstNameController = TextEditingController(text: userData['first_name'] ?? '');
    TextEditingController middleNameController = TextEditingController(text: userData['middle_name'] ?? '');
    TextEditingController lastNameController = TextEditingController(text: userData['last_name'] ?? '');
    TextEditingController emailController = TextEditingController(text: userData['email'] ?? '');
    TextEditingController phoneController = TextEditingController(text: userData['phone_number'] ?? '');
    TextEditingController dobController = TextEditingController(text: userData['date_of_birth'] ?? '');
    TextEditingController addressController = TextEditingController(text: userData['address'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildEditableProfileField(
                        Icons.person,
                        'First Name',
                        'Enter first name',
                        firstNameController,
                      ),
                      SizedBox(height: 20),
                      _buildEditableProfileField(
                        Icons.person,
                        'Middle Name',
                        'Enter middle name',
                        middleNameController,
                      ),
                      SizedBox(height: 20),
                      _buildEditableProfileField(
                        Icons.person,
                        'Last Name',
                        'Enter last name',
                        lastNameController,
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
                      SizedBox(height: 20),
                      _buildAddressField(setState, addressController),
                      SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        ),
                        onPressed: () async {
                          try {
                            await _updateUserInformation(
                              firstNameController.text,
                              middleNameController.text,
                              lastNameController.text,
                              phoneController.text,
                              dobController.text,
                              addressController.text,
                            );

                            Fluttertoast.showToast(
                              msg: "Information updated successfully!",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: primaryGreen,
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
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
        prefixIcon: Icon(icon, color: darkGreen),
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.montserrat(color: darkGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
        filled: true,
        fillColor: isEditable ? Colors.white : Colors.grey[200],
      ),
      readOnly: !isEditable,
    );
  }

  Widget _buildAddressField(StateSetter setState, TextEditingController addressController) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showMap(context, addressController.text),
          child: _buildEditableProfileField(
            Icons.location_on,
            'Current Address',
            'Current address',
            addressController,
            isEditable: false,
          ),
        ),
        SizedBox(height: 20),
        _buildDropDown(
          "Region",
          ["Bicol Region"],
          icon: Icons.location_city,
          value: selectedRegion,
          onChanged: (value) {
            setState(() {
              selectedRegion = value;
              selectedProvince = null;
              selectedMunicipality = null;
              selectedBarangay = null;
              _updateAddress(addressController);
            });
          },
        ),
        SizedBox(height: 16),
        _buildDropDown(
          "Province",
          ["Camarines Sur"],
          icon: Icons.map,
          value: selectedProvince,
          onChanged: selectedRegion != null
              ? (value) {
            setState(() {
              selectedProvince = value;
              selectedMunicipality = null;
              selectedBarangay = null;
              _updateAddress(addressController);
            });
          }
              : null,
        ),
        SizedBox(height: 16),
        _buildDropDown(
          "Municipality",
          ["Naga City"],
          icon: Icons.location_city,
          value: selectedMunicipality,
          onChanged: selectedProvince != null
              ? (value) {
            setState(() {
              selectedMunicipality = value;
              selectedBarangay = null;
              _updateAddress(addressController);
            });
          }
              : null,
        ),
        SizedBox(height: 16),
        _buildDropDown(
          "Barangay",
          ["Agingay", "Bagumbayan", "Bagsak", "Balatas", "Cararayan", "Concepcion Pequeña", "Concepcion Grande",
            "Del Rosario", "Divisoria", "Ermita", "Liboton", "Mabolo", "Magsaysay", "Nabua", "Pacol",
            "Pangpang", "San Felipe", "San Francisco", "San Jose", "San Juan", "San Nicolas", "San Pedro",
            "San Rafael", "San Roque", "Santa Cruz", "Santa Fe", "Santa Lucia", "Santa Maria",
            "Santa Teresita", "Santo Niño", "Santo Domingo"],
          icon: Icons.home,
          value: selectedBarangay,
          onChanged: selectedMunicipality != null
              ? (value) {
            setState(() {
              selectedBarangay = value;
              _updateAddress(addressController);
            });
          }
              : null,
        ),
        SizedBox(height: 20),
        GestureDetector(
          onTap: () => _showMap(context, addressController.text),
          child: _buildEditableProfileField(
            Icons.location_on,
            'New Address',
            'New address based on selections',
            addressController,
            isEditable: false,
          ),
        ),
      ],
    );
  }

  Widget _buildDropDown(String label, List<String> items, {
    required IconData icon,
    required String? value,
    required Function(String?)? onChanged
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: darkGreen)),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: onChanged != null ? darkGreen : Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryGreen, width: 2),
            ),
            filled: true,
            fillColor: onChanged != null ? Colors.white : Colors.grey[200],
          ),
          value: value,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _updateAddress(TextEditingController addressController) {
    String address = "";
    if (selectedRegion != null) address += "$selectedRegion, ";
    if (selectedProvince != null) address += "$selectedProvince, ";
    if (selectedMunicipality != null) address += "$selectedMunicipality, ";
    if (selectedBarangay != null) address += "$selectedBarangay";

    if (address.isNotEmpty) {
      addressController.text = address.trim();
    }
  }

  void _showMap(BuildContext context, String address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green.shade50,
          title: Text(
            'Address on Map',
            style: GoogleFonts.montserrat(
              color: darkGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: FutureBuilder<List<Location>>(
              future: locationFromAddress(address),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: primaryGreen,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.montserrat(color: darkGreen),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Location not found',
                      style: GoogleFonts.montserrat(color: darkGreen),
                    ),
                  );
                }

                Location location = snapshot.data!.first;
                LatLng position = LatLng(location.latitude, location.longitude);

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: position,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('address'),
                      position: position,
                      infoWindow: InfoWindow(title: 'Address'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    ),
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: darkGreen,
              ),
              child: Text('Close', style: GoogleFonts.montserrat()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserInformation(
      String firstName,
      String middleName,
      String lastName,
      String phoneNumber,
      String dateOfBirth,
      String address,
      ) async {
    Map<String, dynamic> updates = {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth,
      'address': address,
    };

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        updates['latitude'] = locations.first.latitude;
        updates['longitude'] = locations.first.longitude;
      }

      await FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(widget.userId)
          .update(updates);

      Fluttertoast.showToast(
        msg: "Information updated successfully!",
        backgroundColor: primaryGreen,
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

