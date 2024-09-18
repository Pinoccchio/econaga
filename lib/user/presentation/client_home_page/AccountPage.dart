import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../designs/app_colors.dart';

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen, // Light green background for the body
      appBar: AppBar(
        backgroundColor: AppColors.secondaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'PROFILE',
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.black),
            onPressed: () {
              // Add settings action here
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture with light green background
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondaryGreen, // Use the color from the class
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('lib/components/assets/images/sample-profile-pic.png'),
                ),
              ),
              SizedBox(height: 10),
              // User full name
              Text(
                'John Oliver C. Rivero',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: 30),
              // Profile Fields
              _buildProfileField(Icons.person, 'User Name', 'Oliver'),
              SizedBox(height: 20),
              _buildProfileField(Icons.email, 'Email', 'JohnoliverRivero@gmail.com'),
              SizedBox(height: 20),
              _buildProfileField(Icons.phone, 'Mobile Number', '09509871849'),
              SizedBox(height: 20),
              _buildProfileField(Icons.calendar_today, 'Date of Birth', '02 / 04 / 1996'),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(IconData icon, String label, String hint) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.black), // Use dark green for icons
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.lato(color: AppColors.black),
        hintStyle: TextStyle(color: AppColors.lightGray), // Lighter hint text
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.darkGray), // Use dark gray for the border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.black, width: 2), // Use black for focused border
        ),
        filled: true,
        fillColor: AppColors.white, // Use white for the background of text fields
      ),
    );
  }
}
