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

class AdminAccountPage extends StatefulWidget {
  @override
  _AdminAccountPageState createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends State<AdminAccountPage> {
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

  bool _isLoading = false;
  LatLng? selectedLocation;
  String? selectedIdType;
  String selectedRole = 'collector';
  File? idImage;
  File? selfieImage;
  bool _obscurePassword = true;

  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(9, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Management', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green.shade700,
      ),
      body: Row(
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
      ),
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
              if (selectedRole == 'collector') ...[
                _buildTextField(truckNumberController, 'Truck Number', icon: Icons.local_shipping),
                SizedBox(height: 10),
                _buildLocationSelector(),
                SizedBox(height: 10),
                _buildTextField(addressController, "Collection Zone", icon: Icons.location_on, readOnly: true),
                SizedBox(height: 10),
              ],
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
      value: selectedRole,
      onChanged: (String? newValue) {
        setState(() {
          selectedRole = newValue!;
        });
      },
      items: <String>['collector', 'client'].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value.capitalize()),
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
          idImageUrl = await _uploadImageToFirebase(idImage!, '${selectedRole}s/${userCredential.user!.uid}/id_image');
        }

        if (selfieImage != null) {
          selfieImageUrl = await _uploadImageToFirebase(selfieImage!, '${selectedRole}s/${userCredential.user!.uid}/selfie_image');
        }

        Map<String, dynamic> userData = {
          'first_name': firstNameController.text.trim(),
          'middle_name': middleNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'phone_number': phoneNumberController.text.trim(),
          'date_of_birth': dateOfBirthController.text.trim(),
          'id_type': selectedIdType,
          'role': selectedRole,
          'idImageUrl': idImageUrl,
          'selfieImageUrl': selfieImageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
        };

        if (selectedRole == 'collector') {
          userData['truck_number'] = truckNumberController.text.trim();
          userData['location'] = selectedLocation != null
              ? GeoPoint(selectedLocation!.latitude, selectedLocation!.longitude)
              : null;
          userData['collection_zone'] = addressController.text.trim();
        }

        await FirebaseFirestore.instance.collection('USERS_ACCOUNTS').doc(userCredential.user!.uid).set(userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${selectedRole.capitalize()} account created successfully'),
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
  }

  Widget _buildAccountList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('USERS_ACCOUNTS').snapshots(),
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
              'No accounts yet',
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
                subtitle: Text('${accountData['email']} (${accountData['role'].toString().capitalize()})'),
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
                      _buildDetailRow('Role', accountData['role']),
                      if (accountData['role'] == 'collector') ...[
                        _buildDetailRow('Truck Number', accountData['truck_number']),
                        _buildDetailRow('Collection Zone', accountData['collection_zone']),
                      ],
                      _buildDetailRow('Status', accountData['status'] ?? 'Active'),
                      SizedBox(height: 20),
                      if (accountData['idImageUrl'] != null)
                        Container(
                          width: double.infinity, // Makes the image stretch to fit within the parent
                          height: 200, // Adjustable height
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              accountData['idImageUrl'],
                              fit: BoxFit.contain, // Ensures the full image is visible
                            ),
                          ),
                        ),
                      SizedBox(height: 10),
                      if (accountData['selfieImageUrl'] != null)
                        Container(
                          width: double.infinity, // Makes the image stretch to fit within the parent
                          height: 200, // Adjustable height
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              accountData['selfieImageUrl'],
                              fit: BoxFit.contain, // Ensures the full image is visible
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

