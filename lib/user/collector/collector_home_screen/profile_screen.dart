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
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

import '../../login_as_screen/login_as_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  bool isTruckToggle = false;
  String? selectedAvailability;

  static const String kGoogleApiKey = "AIzaSyD4UAtE_r8JjBbd0o5qfv3ZSPX_8xkNJ7c";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _updateMarkers();
    });
  }

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
                        colors: [Colors.transparent, Colors.green.withOpacity(0.7)],
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

  Widget _buildProfileInfo(Map<String, dynamic> userData) {
    return Column(
      children: [
        _buildAvailabilityToggle(userData),
        SizedBox(height: 24),
        _buildProfileField(Icons.email, 'Email', userData['email'] ?? 'N/A'),
        _buildProfileField(Icons.phone, 'Mobile Number', userData['phone_number'] ?? 'N/A'),
        _buildProfileField(Icons.cake, 'Date of Birth', userData['date_of_birth'] ?? 'N/A'),
        _buildProfileField(Icons.local_shipping, 'Truck Number', userData['truck_number'] ?? 'N/A'),
        _buildProfileField(Icons.location_on, 'Collection Zone', _getCollectionZoneDescription(userData)),
        _buildProfileField(Icons.access_time, 'Created At', _formatTimestamp(userData['createdAt'])),
        _buildProfileField(Icons.verified_user, 'Status', userData['status'] ?? 'N/A'),
      ],
    );
  }

  String _getCollectionZoneDescription(Map<String, dynamic> userData) {
    if (userData['collection_zone'] is Map<String, dynamic>) {
      return userData['collection_zone']['descriptive_location'] ?? 'N/A';
    }
    return 'N/A';
  }

  Widget _buildAvailabilityToggle(Map<String, dynamic> userData) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Availability Type',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<bool>(
                    isExpanded: true,
                    value: isTruckToggle,
                    onChanged: (newValue) {
                      setState(() {
                        isTruckToggle = newValue!;
                        selectedAvailability = null;
                      });
                    },
                    items: [
                      DropdownMenuItem<bool>(
                        value: false,
                        child: Text('Driver Availability'),
                      ),
                      DropdownMenuItem<bool>(
                        value: true,
                        child: Text('Truck Availability'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedAvailability ?? (isTruckToggle
                  ? (userData['truck_availability'] ?? 'For Repair')
                  : (userData['availability'] ?? 'Not Available')),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedAvailability = newValue;
                  });
                  _updateAvailability(newValue, isTruckToggle);
                }
              },
              items: <String>['Available', 'Used', isTruckToggle ? 'For Repair' : 'Not Available']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: value == 'Available'
                          ? Colors.green
                          : value == 'Used'
                          ? Colors.red
                          : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAvailability(String availability, bool isTruck) async {
    try {
      await FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(widget.userId)
          .update({
        isTruck ? 'truck_availability' : 'availability': availability
      });

      Fluttertoast.showToast(
        msg: "${isTruck ? 'Truck' : 'Driver'} availability updated successfully!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update availability: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
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
          'Collector',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMMM d, yyyy \'at\' h:mm:ss a').format(timestamp.toDate());
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
        String fileName = 'collectors/${widget.userId}/selfie_image/${DateTime.now().millisecondsSinceEpoch}.jpg';
        File file = File(image.path);
        await _storage.ref(fileName).putFile(file);

        String downloadUrl = await _storage.ref(fileName).getDownloadURL();

        await FirebaseFirestore.instance
            .collection('USERS_ACCOUNTS')
            .doc(widget.userId)
            .update({'selfieImageUrl': downloadUrl});

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

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginAsScreen()),
                        (Route<dynamic> route) => false,
                  );
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
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                    backgroundColor: Colors.green,
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
                          backgroundColor: Colors.green,
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
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
    TextEditingController truckNumberController = TextEditingController(text: userData['truck_number'] ?? '');
    TextEditingController collectionZoneController = TextEditingController(
      text: userData['collection_zone'] is Map<String, dynamic>
          ? '${userData['collection_zone']['coordinates'].latitude}, ${userData['collection_zone']['coordinates'].longitude}'
          : '',
    );

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
                  _buildEditableProfileField(
                    Icons.local_shipping,
                    'Truck Number',
                    'Change Truck Number',
                    truckNumberController,
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _showCollectionZoneMap(context, collectionZoneController),
                    child: AbsorbPointer(
                      child: _buildEditableProfileField(
                        Icons.location_on,
                        'Collection Zone',
                        'Tap to select on map',
                        collectionZoneController,
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
                          firstNameController.text,
                          middleNameController.text,
                          lastNameController.text,
                          phoneController.text,
                          dobController.text,
                          truckNumberController.text,
                          collectionZoneController.text,
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
      String firstName,
      String middleName,
      String lastName,
      String phoneNumber,
      String dateOfBirth,
      String truckNumber,
      String collectionZone,
      ) async {
    List<String> coordinates = collectionZone.split(',');
    double latitude = double.parse(coordinates[0].trim());
    double longitude = double.parse(coordinates[1].trim());

    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    Placemark place = placemarks[0];
    String descriptiveLocation = [
      place.street ?? '',
      place.subLocality ?? '',
      place.locality ?? '',
      place.subAdministrativeArea ?? '',
      place.administrativeArea ?? '',
      place.country ?? '',
    ].where((element) => element.isNotEmpty).join(', ');

    Map<String, dynamic> updates = {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth,
      'truck_number': truckNumber,
      'collection_zone': {
        'coordinates': GeoPoint(latitude, longitude),
        'descriptive_location': descriptiveLocation,
      },
    };

    try {
      await FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(widget.userId)
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

  void _showCollectionZoneMap(BuildContext context, TextEditingController controller) async {
    LatLng initialLocation;

    if (controller.text.isNotEmpty) {
      List<String> coordinates = controller.text.split(',');
      if (coordinates.length == 2) {
        double? lat = double.tryParse(coordinates[0].trim());
        double? lng = double.tryParse(coordinates[1].trim());
        if (lat != null && lng != null) {
          initialLocation = LatLng(lat, lng);
          _selectedLocation = initialLocation;
        }
      }
    }

    if (_selectedLocation == null) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      initialLocation = LatLng(position.latitude, position.longitude);
    } else {
      initialLocation = _selectedLocation!;
    }

    _updateMarkers();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Select Collection Zone'),
            backgroundColor: Colors.green,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GooglePlaceAutoCompleteTextField(
                  textEditingController: _searchController,
                  googleAPIKey: kGoogleApiKey,
                  inputDecoration: InputDecoration(
                    hintText: "Search for a location",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  debounceTime: 800,
                  countries: ["ph"],
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: (Prediction prediction) {
                    if (prediction.lat != null && prediction.lng != null) {
                      _searchLocation(LatLng(double.parse(prediction.lat!), double.parse(prediction.lng!)));
                    }
                  },
                  itemClick: (Prediction prediction) {
                    _searchController.text = prediction.description!;
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: prediction.description!.length),
                    );
                  },
                ),
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialLocation,
                    zoom: 14.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  markers: _markers,
                  onTap: (LatLng location) {
                    _showConfirmDialog(context, location);
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.my_location),
            backgroundColor: Colors.green,
            onPressed: () {
              if (_currentLocation != null) {
                _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
              }
            },
          ),
        ),
      ),
    );

    if (_selectedLocation != null) {
      controller.text = '${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}';
    } else {
      controller.text = '';
    }
  }

  void _showConfirmDialog(BuildContext context, LatLng location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Mark Collection Zone",
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            "Do you want to mark this location as your collection zone?",
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade800,
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedLocation = location;
                  _updateMarkers();
                });
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green.shade700,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();

      if (_currentLocation != null) {
        _markers.add(Marker(
          markerId: MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Current Location'),
        ));
      }

      if (_selectedLocation != null) {
        _markers.add(Marker(
          markerId: MarkerId('selected_location'),
          position: _selectedLocation!,
          infoWindow: InfoWindow(title: 'Selected Collection Zone'),
        ));
      }
    });
  }

  void _searchLocation(LatLng location) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(location));
    setState(() {
      _selectedLocation = location;
      _updateMarkers();
    });
  }
}




