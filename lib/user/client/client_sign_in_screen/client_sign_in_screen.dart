import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../client_home_page/client_home_page_container.dart';
import '../client_sign_up_screen/client_sign_up_screen.dart';
import '../client_sign_up_screen/email_verification_screen.dart';

class ClientSignInScreen extends StatefulWidget {
  @override
  _ClientSignInScreenState createState() => _ClientSignInScreenState();
}

class _ClientSignInScreenState extends State<ClientSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

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
      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;
        if (user != null) {
          // Check if the email is verified
          if (!user.emailVerified) {
            // If not verified, redirect to email verification page
            Fluttertoast.showToast(
              msg: "Please verify your email before logging in.",
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
            await user.sendEmailVerification(); // Send a new verification email
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => EmailVerificationScreen(email: _emailController.text)), // Navigate to Email Verification screen
            );
          } else {
            // User is verified, proceed to home screen
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('USERS_ACCOUNTS')
                .doc(user.uid)
                .get();

            if (userDoc.exists) {
              Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

              if (userData != null && userData['role'] == 'client') {
                Fluttertoast.showToast(
                  msg: "Welcome, ${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}!".trim(),
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClientHomeScreenContainer(userId: user.uid),
                  ),
                );
              } else {
                Fluttertoast.showToast(
                  msg: "You are not registered as a client.",
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            } else {
              Fluttertoast.showToast(
                msg: "No user data found.",
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
            }
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = e.code == 'user-not-found'
            ? 'No user found for that email.'
            : e.code == 'wrong-password'
            ? 'Wrong password provided.'
            : e.message ?? 'An error occurred during sign-in.';

        Fluttertoast.showToast(
          msg: errorMessage,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void _forgotPassword() async {
    final TextEditingController forgotPasswordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.green.shade50,
        title: Text(
          "Forgot Password",
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: forgotPasswordController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Enter your email",
              hintStyle: TextStyle(color: Colors.green.shade300),
              fillColor: Colors.green.shade100,
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green.shade700),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.green.shade700),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                String email = forgotPasswordController.text.trim();
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Fluttertoast.showToast(
                    msg: "Password reset link sent to $email",
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  Fluttertoast.showToast(
                    msg: "Error sending reset link",
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              }
            },
            child: Text(
              "Send",
              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }


  void _goToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ClientSignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green.shade200, Colors.green.shade600],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 50),
                    Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                    SizedBox(height: 8),
                    Text(
                      "Sign in to continue",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                    SizedBox(height: 50),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            hintText: "Email",
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: "Password",
                            prefixIcon: Icons.lock,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white70,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                          ),
                          SizedBox(height: 24),
                          _buildSignInButton(),
                          SizedBox(height: 16),
                          _buildForgotPasswordLink(),
                        ],
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                    ),
                    SizedBox(height: 50),
                    _buildSignUpLink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(prefixIcon, color: Colors.white70),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $hintText';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _signIn,
      child: _isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text(
        "Sign In",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.green,
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return TextButton(
      onPressed: _forgotPassword,
      child: Text(
        "Forgot Password?",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account?", style: TextStyle(color: Colors.white70)),
        TextButton(
          onPressed: _goToSignUp,
          child: Text(
            "Sign Up",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
