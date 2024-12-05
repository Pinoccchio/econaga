import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    // Start location tracking when the container is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationService>(context, listen: false).startTracking(widget.userId);
    });
  }

  @override
  void dispose() {
    // Stop location tracking when the container is disposed
    Provider.of<LocationService>(context, listen: false).stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            icon: Icon(Icons.description),
            label: 'Approved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
