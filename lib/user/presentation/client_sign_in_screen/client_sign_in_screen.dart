import 'package:econaga_prj/user/presentation/client_sign_up_screen/client_sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../components/widgets/app_bar/custom_text_form_field.dart';
import '../../../components/widgets/custom_image_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../client_home_page/client_home_page.dart';

class ClientSignInScreen extends StatefulWidget {
  @override
  _ClientSignInScreenState createState() => _ClientSignInScreenState();
}

class _ClientSignInScreenState extends State<ClientSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Sign in the user using Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Fetch user data from Firestore
        User? user = userCredential.user;
        if (user != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            // Sign-in successful, show toast
            Fluttertoast.showToast(
              msg: "Sign-in successful!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            );

            // Use the user data here if needed
            Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

            // Navigate to the ClientHomePage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ClientHomePage()),
            );

          } else {
            Fluttertoast.showToast(
              msg: "No user data found.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided.';
        } else {
          errorMessage = e.message ?? 'An error occurred during sign-in.';
        }
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }



  void _forgotPassword() {
    // Implement forgot password logic here
  }

  void _googleSignIn() {
    // Implement Google sign-in logic here
  }

  void _goToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ClientSignUpScreen()),
    );
  }

  void _goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _goBack,
          ),
          title: Center(
            child: Text(
              "Sign In",
              style: TextStyle(color: Colors.black, fontSize: 20.0),
            ),
          ),
          actions: [
            SizedBox(width: 56.0),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  "Welcome Back!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20.0,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 11.0),
                decoration: BoxDecoration(
                  color: Color(0xFF86CF64),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(42.0),
                    topRight: Radius.circular(42.0),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEmailField(),
                            SizedBox(height: 24.0),
                            _buildPasswordField(),
                            SizedBox(height: 24.0),
                            _buildSignInButton(),
                            SizedBox(height: 28.0),
                            _buildForgotPasswordLink(),
                          ],
                        ),
                      ),
                      SizedBox(height: 57.0),
                      _buildOrDivider(),
                      SizedBox(height: 33.0),
                      _buildSocial(),
                      SizedBox(height: 49.0),
                      _buildSignUpLink(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return CustomTextFormField(
      controller: _emailController,
      hintText: "Email",
      textInputType: TextInputType.emailAddress,
      prefix: _buildPrefixIcon('lib/components/assets/images/email-icon.png'),
      prefixConstraints: BoxConstraints(maxHeight: 60.0),
      contentPadding: EdgeInsets.only(top: 21.0, right: 30.0, bottom: 21.0),
      fillColor: Colors.white,
      textStyle: TextStyle(
        color: Colors.black,
        fontSize: 16.0,
      ),
    );
  }

  Widget _buildPasswordField() {
    return CustomTextFormField(
      controller: _passwordController,
      hintText: "Password",
      textInputAction: TextInputAction.done,
      textInputType: TextInputType.visiblePassword,
      prefix: _buildPrefixIcon('lib/components/assets/images/password-icon.png'),
      suffix: GestureDetector(
        onTap: _togglePasswordVisibility,
        child: Container(
          margin: EdgeInsets.fromLTRB(30.0, 20.0, 20.0, 20.0),
          child: CustomImageView(
            height: 20.0,
            imagePath: _isPasswordVisible
                ? 'lib/components/assets/images/imgEye.png'
                : 'lib/components/assets/images/imgEyeClosed.png',
            width: 20.0,
          ),
        ),
      ),
      prefixConstraints: BoxConstraints(maxHeight: 60.0),
      suffixConstraints: BoxConstraints(maxHeight: 60.0),
      fillColor: Colors.white,
      obscureText: !_isPasswordVisible,
      contentPadding: EdgeInsets.symmetric(vertical: 21.0),
      textStyle: TextStyle(
        color: Colors.black,
        fontSize: 16.0,
      ),
    );
  }

  Widget _buildPrefixIcon(String imagePath) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.0, 20.0, 12.0, 20.0),
      child: CustomImageView(
        imagePath: imagePath,
        height: 20.0,
        width: 20.0,
      ),
    );
  }

  Widget _buildSignInButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _signIn,
        child: Text(
          "Sign In",
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(horizontal: 120, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: _forgotPassword,
        child: Text(
          "Forgot the password?",
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDivider(),
          Text("or continue with", style: TextStyle(color: Colors.black)),
          _buildDivider(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return SizedBox(
      width: 96.0,
      child: Divider(),
    );
  }

  Widget _buildSocial() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 38.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _googleSignIn,
            child: _buildSocialIconButton('lib/components/assets/images/google-icon.png'),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIconButton(String imagePath) {
    return Container(
      height: 60.0,
      width: 88.0,
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 17.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: CustomImageView(
        imagePath: imagePath,
        height: 24.0,
        width: 24.0,
        alignment: Alignment.center,
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don’t have an account?", style: TextStyle(color: Colors.black)),
        GestureDetector(
          onTap: _goToSignUp,
          child: Padding(
            padding: EdgeInsets.only(left: 3.0),
            child: Text(
              "Sign Up",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
