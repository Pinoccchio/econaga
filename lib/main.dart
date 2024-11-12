import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:econaga_prj/admin/home_page/admin_welcome_screen.dart';
import 'package:econaga_prj/admin/home_page/admin_sign_in_page.dart';
import 'package:econaga_prj/designs/app_colors.dart';
import 'package:econaga_prj/firebase_options.dart';
import 'package:econaga_prj/user/collector/collector_home_screen/collector_container_screen.dart';
import 'package:econaga_prj/user/login_as_screen/login_as_screen.dart';
import 'package:econaga_prj/user/welcome_screen/welcome_screen.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator

import 'components/theme/theme_helper.dart'; // Custom theme helper for dynamic theme switching

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with default options for the current platform
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Set persistence to local (to persist sessions across restarts)
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    print('Firebase Auth persistence set to local');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Set preferred device orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Customize system UI overlay styles
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: AppColors.primaryGreen, // Set status bar color to match theme
    statusBarIconBrightness: Brightness.light, // Use light icons on the status bar
    systemNavigationBarColor: Colors.white, // Set navigation bar color for consistency
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Apply custom theme using ThemeHelper
  ThemeHelper().changeTheme('primary');

  runApp(MyApp());

  // Ensure Geolocator is initialized by checking permission after Flutter is fully initialized
  _checkLocationPermission();
}

Future<void> _checkLocationPermission() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied.');
      } else if (permission == LocationPermission.denied) {
        print('Location permissions are denied.');
      } else {
        print('Location permissions granted.');
      }
    } else {
      print('Location permissions already granted.');
    }
  } catch (e) {
    print('Error checking location permission: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Econaga', // Application title
      theme: ThemeData(
        primarySwatch: Colors.blue, // Default theme color
      ),
      debugShowCheckedModeBanner: false, // Disable debug banner for production-like UI
      home: _getHomePage(), // Determine the initial page based on platform
    );
  }

  /// Determines the initial home page based on platform
  Widget _getHomePage() {
    if (kIsWeb) {
      // Return the admin welcome screen for web platform
      return AdminWelcomeScreen();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Use the user welcome screen for Android platform
      return WelcomeScreen();
    } else {
      // Default to admin welcome screen for other platforms (e.g., Windows)
      return AdminWelcomeScreen();
    }
  }
}
