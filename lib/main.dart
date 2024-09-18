import 'package:econaga_prj/firebase_options.dart';
import 'package:econaga_prj/user/presentation/client_home_page/client_home_page.dart';
import 'package:econaga_prj/user/presentation/client_home_page/client_home_page_container.dart';
import 'package:econaga_prj/user/presentation/login_as_screen/login_as_screen.dart';
import 'package:econaga_prj/user/presentation/welcome_screen/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:econaga_prj/admin/home_page/admin_home_page.dart';
import 'package:flutter/services.dart';

import 'components/theme/theme_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set the status bar color and navigation bar color
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.green,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Set the theme
  ThemeHelper().changeTheme('primary');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(  // Use MaterialApp instead of GetMaterialApp
      title: 'Econaga',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: _getHomePage(),  // Set initial route
    );
  }

  Widget _getHomePage() {
    if (kIsWeb) {
      return AdminHomePage();  // Adjust as needed for web
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return ClientHomeScreenContainer();  // Use WelcomeScreen for Android
    } else {
      return AdminHomePage();  // For other platforms
    }
  }
}
