import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../components/widgets/app_bar/custom_text_form_field.dart';
import '../../../../components/widgets/custom_drop_down.dart';
import '../../../../firebase_services/firebase_services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'collector_sign_in_screen.dart';

class CollectorSignUpScreen extends StatefulWidget {
  @override
  _CollectorSignUpScreenState createState() => _CollectorSignUpScreenState();
}

class _CollectorSignUpScreenState extends State<CollectorSignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseServices _firebaseServices = FirebaseServices();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController vehicleDetailsController = TextEditingController();
  final TextEditingController collectionZoneController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();

  bool _isLoading = false;
  bool isChecked = false;
  File? idImage;
  File? selfieImage;
  String? selectedRegion;
  String? selectedProvince;
  String? selectedMunicipality;
  String? selectedBarangay;
  String? selectedIdType;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('Collector Sign Up',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )),
                background: Image.asset(
                  'lib/components/assets/images/official_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._buildTextFields(),
                      SizedBox(height: 24),
                      _buildRegionDropDown(),
                      SizedBox(height: 24),
                      _buildTextField(addressController, "Address", icon: Icons.location_on, readOnly: true),
                      SizedBox(height: 20),
                      _buildPrivacyPolicyCheckBox(),
                      _buildSignUpButton(),
                      _buildLogInLink(),
                    ],
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTextFields() {
    return [
      _buildTextField(emailController, "Email Address", icon: Icons.email, textInputType: TextInputType.emailAddress),
      SizedBox(height: 16),
      _buildTextField(passwordController, "Password", icon: Icons.lock, obscureText: true),
      SizedBox(height: 16),
      _buildTextField(firstNameController, "First Name", icon: Icons.person),
      SizedBox(height: 16),
      _buildTextField(middleNameController, "Middle Name", icon: Icons.person_outline),
      SizedBox(height: 16),
      _buildTextField(lastNameController, "Last Name", icon: Icons.person),
      SizedBox(height: 16),
      _buildDatePicker(),
      SizedBox(height: 16),
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
      SizedBox(height: 16),
      _buildTextField(phoneNumberController, "Contact Number", icon: Icons.phone, textInputType: TextInputType.phone),
      SizedBox(height: 16),
      _buildTextField(vehicleDetailsController, "Vehicle Details", icon: Icons.directions_car),
      SizedBox(height: 16),
      _buildTextField(collectionZoneController, "Collection Zone", icon: Icons.map),
      SizedBox(height: 24),
      _buildImageUploadSection(),
    ];
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool obscureText = false,
        TextInputType textInputType = TextInputType.text,
        bool readOnly = false,
        IconData? icon,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: textInputType,
      readOnly: readOnly,
      style: GoogleFonts.poppins(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        filled: true,
        fillColor: Colors.green.withOpacity(0.1),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  Widget _buildDropDown(String hintText, List<String> items, {IconData? icon, Function(String?)? onChanged}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: hintText,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        filled: true,
        fillColor: Colors.green.withOpacity(0.1),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: GoogleFonts.poppins()),
        );
      }).toList(),
      onChanged: onChanged ?? (String? newValue) {
        setState(() {
          if (hintText == "ID Type") {
            selectedIdType = newValue;
          }
        });
      },
      style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: _buildTextField(
          dateOfBirthController,
          "Date of Birth",
          icon: Icons.calendar_today,
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Documents',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        _buildImageUploadButton('Upload ID Photo', () => _pickImage('id')),
        SizedBox(height: 8),
        _buildImageUploadButton('Upload Selfie with ID', () => _pickImage('selfie')),
      ],
    );
  }

  Widget _buildImageUploadButton(String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.upload_file),
      label: Text(label, style: GoogleFonts.poppins()),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Widget _buildPrivacyPolicyCheckBox() {
    return Row(
      children: [
        Checkbox(
          value: isChecked,
          onChanged: (bool? value) {
            setState(() {
              isChecked = value ?? false;
            });
          },
          activeColor: Colors.green,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
              children: [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    // Navigate to Terms
                  },
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    // Navigate to Privacy Policy
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signUpCollector,
        child: _isLoading
            ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : Text('Sign Up', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildLogInLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
          children: [
            TextSpan(text: 'Already have an account? '),
            TextSpan(
              text: 'Log In',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => CollectorSignInScreen()),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionDropDown() {
    return Column(
      children: [
        _buildDropDown(
          "Region",
          ["Bicol Region"],
          icon: Icons.location_city,
          onChanged: (value) {
            setState(() {
              selectedRegion = value;
              selectedProvince = null;
              selectedMunicipality = null;
              selectedBarangay = null;
              _updateAddress();
            });
          },
        ),
        SizedBox(height: 16),
        _buildDropDown(
          "Province",
          ["Camarines Sur"],
          icon: Icons.map,
          onChanged: (value) {
            setState(() {
              selectedProvince = value;
              selectedMunicipality = null;
              selectedBarangay = null;
              _updateAddress();
            });
          },
        ),
        SizedBox(height: 16),
        _buildDropDown(
          "Municipality",
          ["Naga City"],
          icon: Icons.location_city,
          onChanged: (value) {
            setState(() {
              selectedMunicipality = value;
              selectedBarangay = null;
              _updateAddress();
            });
          },
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
          onChanged: (value) {
            setState(() {
              selectedBarangay = value;
              _updateAddress();
            });
          },
        ),
      ],
    );
  }

  void _updateAddress() {
    String address = "";
    if (selectedRegion != null) address += "$selectedRegion, ";
    if (selectedProvince != null) address += "$selectedProvince, ";
    if (selectedMunicipality != null) address += "$selectedMunicipality, ";
    if (selectedBarangay != null) address += "$selectedBarangay";

    setState(() {
      addressController.text = address.trim();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green,
            hintColor: Colors.green,
            colorScheme: ColorScheme.light(primary: Colors.green),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dateOfBirthController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  void _pickImage(String type) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        if (type == 'id') {
          idImage = File(image.path);
        } else if (type == 'selfie') {
          selfieImage = File(image.path);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image uploaded successfully')),
      );
    }
  }

  Future<void> _signUpCollector() async {
    if (_formKey.currentState!.validate() && isChecked) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await _firebaseServices.createUserWithEmailAndPassword(
          emailController.text,
          passwordController.text,
        );

        if (user != null) {
          String? idImageUrl;
          String? selfieImageUrl;

          if (idImage != null) {
            idImageUrl = await _firebaseServices.uploadImageToFirebase(
              idImage!,
              'collectors/${user.uid}/id_image',
            );
          }

          if (selfieImage != null) {
            selfieImageUrl = await _firebaseServices.uploadImageToFirebase(
              selfieImage!,
              'collectors/${user.uid}/selfie_image',
            );
          }

          await _firebaseServices.saveUserData(user.uid, {
            'first_name': firstNameController.text,
            'middle_name': middleNameController.text,
            'last_name': lastNameController.text,
            'email': emailController.text,
            'date_of_birth': dateOfBirthController.text,
            'phone_number': phoneNumberController.text,
            'address': addressController.text,
            'vehicle_details': vehicleDetailsController.text,
            'collection_zone': collectionZoneController.text,
            'id_image_url': idImageUrl,
            'selfie_image_url': selfieImageUrl,
            'created_at': DateTime.now().toIso8601String(),
            'role': 'collector',
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign up successful!')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CollectorSignInScreen()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and accept the terms')),
      );
    }
  }
}