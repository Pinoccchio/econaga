import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../client_sign_in_screen/client_sign_in_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  EmailVerificationScreen({required this.email});

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _countdown = 59;
  late Timer _timer;
  late Timer _verificationCheckTimer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startVerificationCheck();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  void _startVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _auth.currentUser?.reload();
      User? user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        _verificationCheckTimer.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ClientSignInScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email verified! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      setState(() {
        _countdown = 59;
        _canResend = false;
      });
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email resent'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resending verification email: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _verificationCheckTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Email Verification'),
        backgroundColor: Colors.green,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.email,
                  size: 80,
                  color: Colors.green,
                ),
                SizedBox(height: 20),
                Text(
                  'Verify your email',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'We\'ve sent a verification email to:',
                  style: GoogleFonts.poppins(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                Text(
                  widget.email,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'Click the link in the email to verify your account.',
                  style: GoogleFonts.poppins(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _canResend ? _resendVerificationEmail : null,
                  child: Text(
                    _canResend ? 'Resend Email' : 'Resend in $_countdown seconds',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => ClientSignInScreen()),
                    );
                  },
                  child: Text(
                    'Back to Sign In',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.green,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
