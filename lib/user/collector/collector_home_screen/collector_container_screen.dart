import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/location_services.dart';
import 'approve_service_screen/approve_service_screen.dart';
import 'collector_home_page_screen.dart';
import 'profile_screen.dart';

class CollectorContainer extends StatefulWidget {
  final String userId;

  const CollectorContainer({Key? key, required this.userId}) : super(key: key);

  @override
  _CollectorContainerState createState() => _CollectorContainerState();
}

class _CollectorContainerState extends State<CollectorContainer> {
  int _currentIndex = 1;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ApproveServicesScreen(),
      CollectorHomePage(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];

    // Start location tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationService>(context, listen: false).startTracking(widget.userId);
    });
  }

  @override
  void dispose() {
    // Stop location tracking
    Provider.of<LocationService>(context, listen: false).stopTracking();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 300,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.exit_to_app,
                  size: 48,
                  color: Color(0xFF4CAF50),
                ).animate().scale(duration: 300.ms, curve: Curves.easeInOut),
                SizedBox(height: 20),
                Text(
                  'Exit App?',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Are you sure you want to exit the app?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        exit(0); // This will exit the app
                      },
                      child: Text('Exit'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description, color: Color(0xFF4CAF50)),
              label: 'Approved',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home, color: Color(0xFF4CAF50)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: Color(0xFF4CAF50)),
              label: 'Profile',
            ),
          ],
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF4CAF50), // Modern green for selected icons
          unselectedItemColor: Color(0xFF81C784), // Lighter green for unselected icons
          type: BottomNavigationBarType.fixed,
          elevation: 8.0,
          iconSize: 24,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          enableFeedback: true,
        ),
      ),
    );
  }
}

