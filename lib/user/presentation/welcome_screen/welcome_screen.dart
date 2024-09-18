import 'package:flutter/material.dart';
import '../../../components/core/utils/size_utils.dart';
import '../../../components/theme/custom_text_style.dart';
import '../../../components/widgets/custom_image_view.dart';
import '../login_as_screen/login_as_screen.dart';

class WelcomeScreen extends StatelessWidget {
  // Controller functionality can be handled directly within the widget or using a state management solution if needed

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);

    return GestureDetector(
      onTap: () => _navigateToNextScreen(context),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white, // Set the background color to white
          body: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 120, top: 200, right: 120),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20), // Optional: Rounded corners
                      child: CustomImageView(
                        imagePath: 'lib/components/assets/images/official_logo.png',
                        height: 167.v, // Adjust the height
                        width: 167.h,  // Adjust the width
                        fit: BoxFit.contain, // Ensure the image scales correctly
                      ),
                    ),
                  ),
                  SizedBox(height: 76.v),
                  _buildWelcomeSection(context),
                  SizedBox(height: 5.v),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToNextScreen(BuildContext context) {
    // Replace with your navigation logic
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginAsScreen()), // Replace with your actual next screen
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome to",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.black), // Set the text color to black
          ),
          SizedBox(height: 23.v),
          Text(
            "Econaga",
            style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.black), // Set the text color to black
          ),
          SizedBox(height: 40.v),
          Container(
            width: 319.h,
            margin: EdgeInsets.only(right: 44.h),
            child: Text(
              "Schedule your garbage collection with just a tap and help us make a positive impact on the environment, one pickup at a time!",
              style: CustomTextStyles.titleMediumSemiBold_1.copyWith(
                height: 1.50,
                color: Colors.black, // Set the text color to black
              ),
            ),
          ),
        ],
      ),
    );
  }
}
