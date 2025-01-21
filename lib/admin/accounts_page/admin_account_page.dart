import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'location_selection_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminAccountPage extends StatefulWidget {
  @override
  _AdminAccountPageState createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends State<AdminAccountPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController truckNumberController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _dateRegisteredController = TextEditingController();

  bool _isLoading = false;
  LatLng? selectedLocation;
  String? selectedIdType;
  String selectedRole = 'collector';
  File? idImage;
  File? selfieImage;
  bool _obscurePassword = true;
  File? _profileImage;

  late List<FocusNode> _focusNodes;

  Map<String, dynamic> _adminProfile = {
    'full_name': '',
    'email': '',
    'created_at': null,
    'contact_number': '',
    'role': 'admin',
    'profile_picture_url': null,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _focusNodes = List.generate(9, (index) => FocusNode());
    _loadAdminProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white
            )
        ),
        backgroundColor: Colors.green.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text('Admin Profile',
                  style: GoogleFonts.poppins(color: Colors.white)
              ),
            ),
            Tab(
              child: Text('Account Management',
                  style: GoogleFonts.poppins(color: Colors.white)
              ),
            ),
          ],
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAdminProfileTab(),
          _buildAccountManagementTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAdminProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('ADMIN_ACCOUNTS')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _adminProfile = {
              'full_name': data['full_name'] ?? '',
              'email': data['email'] ?? '',
              'created_at': data['created_at'],
              'contact_number': data['contact_number'] ?? '',
              'role': data['role'] ?? 'admin',
              'profile_picture_url': data['profile_picture_url'],
            };

            // Set controller values
            _fullNameController.text = data['full_name'] ?? '';
            _contactNumberController.text = data['contact_number'] ?? '';
            emailController.text = data['email'] ?? '';
            if (data['created_at'] != null) {
              _dateRegisteredController.text = DateFormat('MM/dd/yyyy')
                  .format((data['created_at'] as Timestamp).toDate());
            }
          });
        }
      }
    } catch (e) {
      print('Error loading admin profile: $e');
    }
  }

  Widget _buildAdminProfileTab() {
    return Container(
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.green.shade200,
                                  backgroundImage: _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : (_adminProfile['profile_picture_url'] != null
                                      ? NetworkImage(_adminProfile['profile_picture_url'] as String)
                                      : null) as ImageProvider?,
                                  child: _profileImage == null && _adminProfile['profile_picture_url'] == null
                                      ? Text(
                                    _adminProfile['full_name']?.isNotEmpty == true
                                        ? _adminProfile['full_name'][0].toUpperCase()
                                        : 'A',
                                    style: TextStyle(fontSize: 40, color: Colors.green.shade700),
                                  )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.green.shade600,
                                    radius: 18,
                                    child: IconButton(
                                      icon: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                      onPressed: _updateProfilePicture,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              _adminProfile['role'] ?? 'Admin',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _adminProfile['full_name'] ?? 'Admin Name',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                _adminProfile['email'] ?? 'admin@example.com',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Joined ${_formatDate(_adminProfile['created_at'])}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildProfileInfoTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoTab() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, color: Colors.green.shade700),
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _contactNumberController,
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone, color: Colors.green.shade700),
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email, color: Colors.green.shade700),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _dateRegisteredController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date Registered',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.green.shade700),
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
                onTap: _selectDate,
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateAdminProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'Update Info',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _sendPasswordResetEmail(_adminProfile['email']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'Send Reset Password Email to Admin Account',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green.shade700,
            hintColor: Colors.green.shade700,
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
            colorScheme: ColorScheme.light(primary: Colors.green.shade700),
            textTheme: TextTheme(
              headline6: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dateRegisteredController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _updateAdminProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('ADMIN_ACCOUNTS')
            .doc(user.uid)
            .update({
          'full_name': _fullNameController.text.trim(),
          'contact_number': _contactNumberController.text.trim(),
          'created_at': Timestamp.fromDate(DateFormat('MM/dd/yyyy').parse(_dateRegisteredController.text)),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );

        _loadAdminProfile();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<String> getDescriptiveLocation(double lat, double lon) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final address = data['address'];

      final road = address['road'] ?? '';
      final suburb = address['suburb'] ?? '';
      final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
      final state = address['state'] ?? '';
      final country = address['country'] ?? '';
      final postcode = address['postcode'] ?? '';

      return '${road.isNotEmpty ? road + ', ' : ''}'
          '${suburb.isNotEmpty ? suburb + ', ' : ''}'
          '${city.isNotEmpty ? city + ', ' : ''}'
          '${state.isNotEmpty ? state + ', ' : ''}'
          '${country.isNotEmpty ? country + ', ' : ''}'
          '${postcode.isNotEmpty ? postcode : ''}'.trim();
    } else {
      throw Exception('Failed to get location description');
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  Widget _buildAccountManagementTab() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildAccountForm(),
        ),
        VerticalDivider(thickness: 1, width: 1, color: Colors.green.shade200),
        Expanded(
          flex: 1,
          child: _buildAccountList(),
        ),
      ],
    );
  }

  Widget _buildAccountForm() {
    return Container(
      color: Colors.green.shade50,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700),
              ),
              SizedBox(height: 20),
              _buildTextField(firstNameController, 'First Name', icon: Icons.person),
              SizedBox(height: 10),
              _buildTextField(middleNameController, 'Middle Name', icon: Icons.person_outline),
              SizedBox(height: 10),
              _buildTextField(lastNameController, 'Last Name', icon: Icons.person),
              SizedBox(height: 10),
              _buildTextField(emailController, 'Email', icon: Icons.email, keyboardType: TextInputType.emailAddress),
              SizedBox(height: 10),
              _buildTextField(passwordController, 'Password', icon: Icons.lock),
              SizedBox(height: 10),
              _buildTextField(phoneNumberController, 'Contact Number', icon: Icons.phone, keyboardType: TextInputType.phone),
              SizedBox(height: 10),
              _buildDatePicker(),
              SizedBox(height: 10),
              _buildDropDown("ID Type", [
                "Philippine Passport",
                "SSS/GSIS",
                "Philippine Driver's License",
                "Digitized Postal ID",
                "Digitized Philhealth ID",
                "National ID",
                "Student ID",
                "Voter's ID",
                "Senior Citizen ID",
                "Non-digitized Postal ID",
                "Non-digitized Philhealth ID"
              ], icon: Icons.badge),
              SizedBox(height: 10),
              _buildRoleDropdown(),
              SizedBox(height: 10),
              _buildTextField(truckNumberController, 'Truck Number', icon: Icons.local_shipping),
              SizedBox(height: 10),
              _buildLocationSelector(),
              SizedBox(height: 10),
              _buildTextField(addressController, "Collection Zone", icon: Icons.location_on, readOnly: true),
              SizedBox(height: 10),
              _buildImageUploadSection(),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  child: Text(_isLoading ? 'Saving...' : 'Create Account', style: GoogleFonts.poppins(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        IconData? icon,
        bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
        bool readOnly = false,
      }) {
    int index = [
      firstNameController,
      middleNameController,
      lastNameController,
      emailController,
      passwordController,
      phoneNumberController,
      dateOfBirthController,
      truckNumberController,
      addressController,
    ].indexOf(controller);

    return TextFormField(
      controller: controller,
      obscureText: label == 'Password' ? _obscurePassword : obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      focusNode: _focusNodes[index],
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
      onFieldSubmitted: (_) {
        _moveFocus(index);
      },
      onChanged: (value) {
        if (value.isEmpty) {
          _moveFocusBack(index);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.green.shade700) : null,
        suffixIcon: label == 'Password'
            ? IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.green.shade700,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        )
            : null,
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade200)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade700)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  void _moveFocus(int currentIndex) {
    if (currentIndex < _focusNodes.length - 1) {
      _focusNodes[currentIndex + 1].requestFocus();
    } else {
      _focusNodes[currentIndex].unfocus();
    }
  }

  void _moveFocusBack(int currentIndex) {
    if (currentIndex > 0) {
      _focusNodes[currentIndex - 1].requestFocus();
    }
  }

  Widget _buildDatePicker() {
    return TextFormField(
      controller: dateOfBirthController,
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        prefixIcon: Icon(Icons.calendar_today, color: Colors.green.shade700),
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade200)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade700)),
        filled: true,
        fillColor: Colors.white,
      ),
      readOnly: true,
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please select your Date of Birth';
        }
        return null;
      },
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2101),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData.light().copyWith(
                primaryColor: Colors.green.shade700,
                colorScheme: ColorScheme.light(primary: Colors.green.shade700),
                buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          setState(() {
            dateOfBirthController.text = "${pickedDate.toLocal()}".split(' ')[0];
          });
        }
      },
    );
  }

  Widget _buildDropDown(String label, List<String> items, {IconData? icon}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.green.shade700) : null,
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade200)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade700)),
        filled: true,
        fillColor: Colors.white,
      ),
      value: selectedIdType,
      onChanged: (String? newValue) {
        setState(() {
          selectedIdType = newValue;
        });
      },
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      validator: (value) => value == null ? 'Please select an ID Type' : null,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Role',
        prefixIcon: Icon(Icons.work, color: Colors.green.shade700),
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade200)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade700)),
        filled: true,
        fillColor: Colors.white,
      ),
      value: 'collector',
      onChanged: (String? newValue) {
        // No need to change the state as there's only one option
      },
      items: <String>['collector'].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text('Driver'),
        );
      }).toList(),
    );
  }

  Widget _buildLocationSelector() {
    return TextFormField(
      controller: addressController,
      decoration: InputDecoration(
        labelText: 'Location',
        prefixIcon: Icon(Icons.search, color: Colors.green.shade700),
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade200)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade700)),
        filled: true,
        fillColor: Colors.white,
      ),
      readOnly: true,
      validator: (value) {
        if (selectedLocation == null) {
          return 'Please select your Location';
        }
        return null;
      },
      onTap: () async {
        final LatLng? selectedLocation = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LocationSelectionPage()),
        );
        if (selectedLocation != null) {
          setState(() {
            this.selectedLocation = selectedLocation;
            addressController.text = "${selectedLocation.latitude}, ${selectedLocation.longitude}";
          });
        }
      },
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Documents',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildImageUploadButton('Upload ID Photo *', () => _pickImage('id')),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _buildImageUploadButton('Upload Selfie with ID *', () => _pickImage('selfie')),
            ),
          ],
        ),
        if (idImage == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'ID photo is required',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        if (selfieImage == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Selfie with ID is required',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildImageUploadButton(String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.upload_file, color: Colors.white),
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }

  void _pickImage(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      setState(() {
        if (type == 'id') {
          idImage = File(pickedFile.path);
        } else {
          selfieImage = File(pickedFile.path);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.capitalize()} photo uploaded successfully'),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick ${type.capitalize()} photo. Please try again.'),
            backgroundColor: Colors.red.shade600,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      String? imageError = _validateImageUploads();
      if (imageError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(imageError),
            backgroundColor: Colors.red.shade600,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      _formKey.currentState!.save();

      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        String? idImageUrl;
        String? selfieImageUrl;

        if (idImage != null) {
          idImageUrl = await _uploadImageToFirebase(idImage!, 'collectors/${userCredential.user!.uid}/id_image');
        }

        if (selfieImage != null) {
          selfieImageUrl = await _uploadImageToFirebase(selfieImage!, 'collectors/${userCredential.user!.uid}/selfie_image');
        }

        Map<String, dynamic> userData = {
          'first_name': firstNameController.text.trim(),
          'middle_name': middleNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'phone_number': phoneNumberController.text.trim(),
          'date_of_birth': dateOfBirthController.text.trim(),
          'id_type': selectedIdType,
          'role': 'collector',
          'idImageUrl': idImageUrl,
          'selfieImageUrl': selfieImageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
        };

        if (selectedLocation != null) {
          final descriptiveLocation = await getDescriptiveLocation(selectedLocation!.latitude, selectedLocation!.longitude);
          userData['collection_zone'] = {
            'coordinates': GeoPoint(selectedLocation!.latitude, selectedLocation!.longitude),
            'descriptive_location': descriptiveLocation,
          };
          userData['truck_number'] = truckNumberController.text.trim();
        }

        await FirebaseFirestore.instance.collection('USERS_ACCOUNTS').doc(userCredential.user!.uid).set(userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Driver account created successfully'),
              backgroundColor: Colors.green.shade600,
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
          _clearForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating account: $e'),
              backgroundColor: Colors.red.shade600,
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String? _validateImageUploads() {
    if (idImage == null) {
      return 'Please upload your ID photo';
    }
    if (selfieImage == null) {
      return 'Please upload your selfie with ID';
    }
    return null;
  }

  Future<String> _uploadImageToFirebase(File image, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final uploadTask = ref.putFile(image);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  void _clearForm() {
    firstNameController.clear();
    middleNameController.clear();
    lastNameController.clear();
    emailController.clear();
    passwordController.clear();
    phoneNumberController.clear();
    dateOfBirthController.clear();
    truckNumberController.clear();
    addressController.clear();
    selectedIdType = null;
    selectedLocation = null;
    idImage = null;
    selfieImage = null;
    setState(() {});
    null;
    idImage = null;
    selfieImage = null;
    setState(() {});
  }

  Widget _buildAccountList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .where('role', isEqualTo: 'collector')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No driver accounts yet',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var accountData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var accountId = snapshot.data!.docs[index].id;
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: accountData['status'] == 'inactive' ? Colors.red.shade100 : Colors.green.shade100,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: accountData['selfieImageUrl'] != null
                      ? NetworkImage(accountData['selfieImageUrl'])
                      : null,
                  child: accountData['selfieImageUrl'] == null
                      ? Icon(Icons.person)
                      : null,
                  backgroundColor: accountData['status'] == 'inactive' ? Colors.red.shade200 : Colors.green.shade200,
                ),
                title: Text('${accountData['first_name']} ${accountData['last_name']}',
                  style: TextStyle(color: accountData['status'] == 'inactive' ? Colors.red.shade700 : Colors.green.shade700),
                ),
                subtitle: Text('${accountData['email']} (Driver)'),
                trailing: Icon(Icons.chevron_right,
                    color: accountData['status'] == 'inactive' ? Colors.red.shade700 : Colors.green.shade700
                ),
                onTap: () => _showAccountDetails(accountId, accountData),
              ),
            );
          },
        );
      },
    );
  }

  void _showAccountDetails(String accountId, Map<String, dynamic> accountData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: contentBox(context, accountId, accountData),
        );
      },
    );
  }

  Widget contentBox(BuildContext context, String accountId, Map<String, dynamic> accountData) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 20, top: 65, right: 20, bottom: 20),
          margin: EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black,offset: Offset(0,10),
                    blurRadius: 10
                ),
              ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Account Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 15,),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDetailRow('Name', '${accountData['first_name']} ${accountData['middle_name']} ${accountData['last_name']}'),
                      _buildDetailRow('Email', accountData['email']),
                      _buildDetailRow('Phone', accountData['phone_number']),
                      _buildDetailRow('Date of Birth', accountData['date_of_birth']),
                      _buildDetailRow('ID Type', accountData['id_type']),
                      _buildDetailRow('Role', accountData['role'] == 'collector' ? 'Driver' : accountData['role']),
                      _buildDetailRow('Truck Number', accountData['truck_number']),
                      _buildDetailRow('Collection Zone', accountData['collection_zone']['descriptive_location']),
                      _buildDetailRow('Status', accountData['status'] ?? 'Active'),
                      SizedBox(height: 20),
                      if (accountData['idImageUrl'] != null)
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              accountData['idImageUrl'],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      SizedBox(height: 10),
                      if (accountData['selfieImageUrl'] != null)
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              accountData['selfieImageUrl'],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    child: Text('Close', style: TextStyle(color: Colors.white)),
                    style: TextButton.styleFrom(backgroundColor: Colors.green.shade600),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text(accountData['status'] == 'inactive' ? 'Activate' : 'Deactivate', style: TextStyle(color: Colors.white)),
                    style: TextButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () {
                      _toggleAccountStatus(accountId, accountData['status'] ?? 'active');
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Reset Password', style: TextStyle(color: Colors.white)),
                    style: TextButton.styleFrom(backgroundColor: Colors.blue.shade600),
                    onPressed: () {
                      _showPasswordResetOptions(accountId, accountData['email']);
                    },
                  ),
                  TextButton(
                    child: Text('Delete', style: TextStyle(color: Colors.white)),
                    style: TextButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      _deleteAccount(accountId);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 45,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(45)),
              child: Image.network(accountData['selfieImageUrl'] ?? ''),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleAccountStatus(String accountId, String currentStatus) async {
    try {
      String newStatus = currentStatus == 'active' ? 'inactive' : 'active';
      await FirebaseFirestore.instance.collection('USERS_ACCOUNTS').doc(accountId).update({
        'status': newStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account ${newStatus == 'active' ? 'activated' : 'deactivated'} successfully'),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating account status: $e'),
            backgroundColor: Colors.red.shade600,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  void _deleteAccount(String accountId) async {
    Navigator.of(context).pop();

    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete', style: TextStyle(color: Colors.green.shade700)),
          content: Text('Are you sure you want to delete this account?'),
          backgroundColor: Colors.green.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.green.shade700)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: Text('Delete', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('USERS_ACCOUNTS').doc(accountId).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green.shade600,
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: Colors.red.shade600,
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    }
  }

  void _showPasswordResetOptions(String accountId, String email) {
    _sendPasswordResetEmail(email);
  }

  void _sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending password reset email: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _updateProfilePicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('admin_profile_pictures')
              .child('${user.uid}.jpg');

          await ref.putFile(_profileImage!);
          final url = await ref.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('ADMIN_ACCOUNTS')
              .doc(user.uid)
              .update({'profile_picture_url': url});

          setState(() {
            _adminProfile['profile_picture_url'] = url;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        }
      } catch (e) {
        print('Error updating profile picture: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

String _formatDate(dynamic timestamp) {
  if (timestamp == null) return 'N/A';
  if (timestamp is Timestamp) {
    return DateFormat('MMMM d, y').format(timestamp.toDate());
  }
  return 'N/A';
}

