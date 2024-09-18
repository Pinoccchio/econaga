import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../components/widgets/app_bar/custom_text_form_field.dart';
import '../../../components/widgets/custom_drop_down.dart';
import '../../../components/widgets/custom_image_view.dart';
import '../../../firebase_services/firebase_services.dart';
import '../client_sign_in_screen/client_sign_in_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ClientSignUpScreen extends StatefulWidget {
  @override
  _ClientSignUpScreenState createState() => _ClientSignUpScreenState();
}

class _ClientSignUpScreenState extends State<ClientSignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final FirebaseServices _firebaseServices = FirebaseServices();
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
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Center(
            child: Text("Sign Up",
                style: TextStyle(color: Colors.black, fontSize: 20.0)),
          ),
          actions: [SizedBox(width: 56.0)],
        ),
        backgroundColor: Colors.white,
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                ..._buildTextFields(),
                SizedBox(height: 24),
                _buildRegionDropDown(),
                SizedBox(height: 24),
                _buildTextField(addressController, "Address", readOnly: true),
                SizedBox(height: 20),
                _buildPrivacyPolicyCheckBox(),
                _buildSignUpButton(),
                _buildLogInLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTextFields() {
    return [
      _buildTextField(usernameController, "Username"),
      SizedBox(height: 24),
      _buildTextField(passwordController, "Password", obscureText: true),
      SizedBox(height: 24),
      _buildTextField(firstNameController, "First Name"),
      SizedBox(height: 24),
      _buildTextField(middleNameController, "Middle Name"),
      SizedBox(height: 24),
      _buildTextField(lastNameController, "Last Name"),
      SizedBox(height: 24),
      _buildTextField(emailController, "Email Address", textInputType: TextInputType.emailAddress),
      SizedBox(height: 24),
      GestureDetector(
        onTap: () => _selectDate(context),
        child: AbsorbPointer(
          child: _buildTextField(dateOfBirthController, "Date of Birth"),
        ),
      ),
      SizedBox(height: 24),
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
      ], onChanged: (value) {
        setState(() {
          selectedIdType = value;
          print('Selected ID Type: $selectedIdType');
        });
      }),
      SizedBox(height: 24),
      _buildTextField(idNumberController, "ID Number"),
      SizedBox(height: 24),
      _buildInstructionText('PLEASE PROVIDE FRONT PHOTO OF YOUR ID'),
      _buildAttachButton('ATTACH ID', () => _pickImage('id')),
      SizedBox(height: 24),
      _buildInstructionText('PLEASE PROVIDE A SELFIE WITH YOUR ID'),
      _buildAttachButton('ATTACH SELFIE WITH FRONT ID', () => _pickImage('selfie')),
      SizedBox(height: 24),
      _buildTextField(phoneNumberController, "Contact Number", textInputType: TextInputType.phone),
    ];
  }

  Widget _buildPrivacyPolicyCheckBox() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return GestureDetector(
          onTap: () {
            setState(() {
              isChecked = !isChecked;
            });
            print('Privacy policy checkbox tapped: $isChecked');
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isChecked,
                activeColor: Colors.black,
                onChanged: (value) {
                  setState(() {
                    isChecked = value ?? false;
                  });
                  print('Privacy policy checkbox changed: $isChecked');
                },
              ),
              Flexible(
                child: RichText(
                  text: TextSpan(
                    text: 'By signing up, you agree to our ',
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Terms',
                        style: TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navigate to Terms and Conditions
                            print('Terms tapped');
                          },
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navigate to Privacy Policy
                            print('Privacy Policy tapped');
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String hintText, {
        bool obscureText = false,
        TextInputType textInputType = TextInputType.text,
        bool readOnly = false, // Add the readOnly parameter
      }) {
    return CustomTextFormField(
      controller: controller,
      hintText: hintText,
      obscureText: obscureText,
      textInputType: textInputType,
      readOnly: readOnly, // Pass the readOnly parameter
      prefix: _buildPrefixIcon(),
      prefixConstraints: BoxConstraints(maxHeight: 60.0),
      contentPadding: EdgeInsets.only(top: 21.0, right: 30.0, bottom: 21.0),
      fillColor: Color(0xFF86CF64),
      textStyle: TextStyle(color: Colors.black, fontSize: 14.0),
      validator: (value) {
        if (value == null || value.isEmpty) {
          print('$hintText is required');
          return '$hintText is required';
        }
        return null;
      },
    );
  }

  Widget _buildDropDown(String hintText, List<String> items, {ValueChanged<String?>? onChanged}) {
    return CustomDropDown(
      hintText: hintText,
      items: items,
      backgroundColor: Colors.white,
      textColor: Colors.black,
      prefix: _buildPrefixIcon(),
      prefixConstraints: BoxConstraints(maxHeight: 60.0),
      contentPadding: EdgeInsets.only(top: 21.0, right: 30.0, bottom: 21.0),
      onChanged: (value) {
        onChanged?.call(value);
        print('Selected $hintText: $value');
      },
    );
  }

  Widget _buildPrefixIcon() {
    return Container(
      margin: EdgeInsets.fromLTRB(20.0, 20.0, 12.0, 20.0),
      child: CustomImageView(
        imagePath: 'lib/components/assets/images/email-icon.png',
        height: 20.0,
        width: 20.0,
      ),
    );
  }

  Widget _buildInstructionText(String text) {
    return Container(
      margin: EdgeInsets.fromLTRB(10, 0, 10, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(right: 12),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage('lib/components/assets/images/exclamation_icon.png'),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1.7,
                color: Color(0xFF272727),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickImage(String type) async {
    final pickedFile = await showModalBottomSheet<File?>(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          color: Colors.green,
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.black),
                title: Text('Gallery', style: TextStyle(color: Colors.black)),
                onTap: () async {
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                  Navigator.of(context).pop(File(pickedFile?.path ?? ''));
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.black),
                title: Text('Camera', style: TextStyle(color: Colors.black)),
                onTap: () async {
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
                  Navigator.of(context).pop(File(pickedFile?.path ?? ''));
                },
              ),
            ],
          ),
        );
      },
    );

    if (pickedFile != null) {
      setState(() {
        if (type == 'id') {
          idImage = pickedFile;
          print('ID Image selected: ${pickedFile.path}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ID image selected successfully!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );

        } else if (type == 'selfie') {
          selfieImage = pickedFile;
          print('Selfie Image selected: ${pickedFile.path}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selfie image selected successfully!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Image selection cancelled.',
            style: TextStyle(color: Colors.red),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }


  Widget _buildAttachButton(String buttonText, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: Align(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {
            print('$buttonText tapped');
            onTap();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF1EA0FF),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.8,
                  color: Color(0xFF272727),
                ),
              ),
            ),
          ),
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
          onChanged: (value) {
            setState(() {
              selectedRegion = value;
              print('Selected Region: $selectedRegion');
              selectedProvince = null;
              selectedMunicipality = null;
              selectedBarangay = null;
              _updateAddress();
            });
          },
        ),
        SizedBox(height: 24),
        _buildDropDown(
          "Province",
          ["Camarines Sur"],
          onChanged: (value) {
            setState(() {
              selectedProvince = value;
              print('Selected Province: $selectedProvince');
              selectedMunicipality = null;
              selectedBarangay = null;
              _updateAddress();
            });
          },
        ),
        SizedBox(height: 24),
        _buildDropDown(
          "Municipality",
          ["Naga City"],
          onChanged: (value) {
            setState(() {
              selectedMunicipality = value;
              print('Selected Municipality: $selectedMunicipality');
              selectedBarangay = null;
              _updateAddress();
            });
          },
        ),
        SizedBox(height: 24),
        _buildDropDown(
          "Barangay",
          [
            "Agingay", "Bagumbayan", "Bagsak", "Balatas", "Cararayan", "Concepcion Pequeña", "Concepcion Grande",
            "Del Rosario", "Divisoria", "Ermita", "Liboton", "Mabolo", "Magsaysay", "Nabua", "Pacol",
            "Pangpang", "San Felipe", "San Francisco", "San Jose", "San Juan", "San Nicolas", "San Pedro",
            "San Rafael", "San Roque", "Santa Cruz", "Santa Fe", "Santa Lucia", "Santa Maria",
            "Santa Teresita", "Santo Niño", "Santo Domingo"
          ],
          onChanged: (value) {
            setState(() {
              selectedBarangay = value;
              print('Selected Barangay: $selectedBarangay');
              _updateAddress();
            });
          },
        ),
      ],
    );
  }

  void _updateAddress() {
    String address = "";

    if (selectedRegion != null) {
      address += "$selectedRegion, ";
    }

    if (selectedProvince != null) {
      address += "$selectedProvince, ";
    }

    if (selectedMunicipality != null) {
      address += "$selectedMunicipality, ";
    }

    if (selectedBarangay != null) {
      address += "$selectedBarangay";
    }

    addressController.text = address;
    print('Updated Address: $address');
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : () async {
        if (_formKey.currentState?.validate() ?? false) {
          if (!isChecked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You must agree to the Privacy Policy to sign up.'),
                backgroundColor: Colors.red, // Set the background color to red
              ),
            );
            return;
          }

          if (idImage == null || selfieImage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please attach both ID and selfie images to continue.'),
                backgroundColor: Colors.red, // Set the background color to red
              ),
            );
            return;
          }

          setState(() {
            _isLoading = true; // Set loading state to true
          });

          try {
            await _signUpUser();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Sign-up successful!',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ClientSignInScreen()), // Replace `SignInScreen()` with your sign-in screen widget
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to sign-up. Please try again.',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );

          } finally {
            setState(() {
              _isLoading = false; // Set loading state to false after completion
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please fill all required fields.'),
              backgroundColor: Colors.red, // Set the background color to red
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 130, vertical: 15),
        backgroundColor: _isLoading ? Colors.grey : Colors.green, // Change color based on loading state
        foregroundColor: Colors.white, // Text color
      ),
      child: _isLoading
          ? CircularProgressIndicator( // Show loading indicator if in loading state
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      )
          : Text(
        "Sign Up",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _signUpUser() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final String username = usernameController.text.trim();
      final String password = passwordController.text.trim();
      final String firstName = firstNameController.text.trim();
      final String middleName = middleNameController.text.trim();
      final String lastName = lastNameController.text.trim();
      final String email = emailController.text.trim();
      final String dateOfBirth = dateOfBirthController.text.trim();
      final String idNumber = idNumberController.text.trim();
      final String phoneNumber = phoneNumberController.text.trim();
      final String address = addressController.text.trim();

      if (idImage == null || selfieImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please attach both ID and selfie images.')),
        );
        return;
      }

      final user = await _firebaseServices.createUserWithEmailAndPassword(email, password);

      if (user != null) {
        String idImageUrl = await _firebaseServices.uploadImageToFirebase(idImage!, 'id_images/${user.uid}');
        String selfieImageUrl = await _firebaseServices.uploadImageToFirebase(selfieImage!, 'selfie_images/${user.uid}');

        await _firebaseServices.saveUserData(user.uid, {
          'username': username,
          'password': password,
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'email': email,
          'date_of_birth': dateOfBirth,
          'id_type': selectedIdType,
          'id_number': idNumber,
          'phone_number': phoneNumber,
          'address': address,
          'id_image_url': idImageUrl,
          'selfie_image_url': selfieImageUrl,
          'created_at': DateTime.now(),
        });

        /*
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-up successful!')),
        );

         */
      }
    } catch (e) {
      /*
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-up failed: $e')),
      );
      */
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }


  Widget _buildLogInLink() {
    return Padding(
      padding: EdgeInsets.only(top: 16.0),
      child: RichText(
        text: TextSpan(
          text: 'Already have an account? ',
          style: TextStyle(color: Colors.black),
          children: [
            TextSpan(
              text: 'Login',
              style: TextStyle(color: Colors.blue),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ClientSignInScreen()),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null && selectedDate != DateTime.now()) {
      setState(() {
        dateOfBirthController.text = "${selectedDate.toLocal()}".split(' ')[0];
        print('Selected Date of Birth: ${dateOfBirthController.text}');
      });
    }
  }
}
