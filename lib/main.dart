import 'package:econaga_prj/services/location_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:econaga_prj/admin/home_page/admin_welcome_screen.dart';
import 'package:econaga_prj/admin/home_page/admin_sign_in_page.dart';
import 'package:econaga_prj/designs/app_colors.dart';
import 'package:econaga_prj/firebase_options.dart';
import 'package:econaga_prj/user/collector/collector_home_screen/collector_container_screen.dart';
import 'package:econaga_prj/user/login_as_screen/login_as_screen.dart';
import 'package:econaga_prj/user/welcome_screen/welcome_screen.dart';
import 'package:geolocator/geolocator.dart';

import 'components/theme/theme_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    print('Firebase Auth persistence set to local');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: AppColors.primaryGreen,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  ThemeHelper().changeTheme('primary');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationService()),
      ],
      child: MyApp(),
    ),
  );

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
      title: 'Econaga',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: _getHomePage(),
    );
  }

  Widget _getHomePage() {
    if (kIsWeb) {
      return AdminWelcomeScreen();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return WelcomeScreen();
    } else {
      return AdminWelcomeScreen();
    }
  }
}

