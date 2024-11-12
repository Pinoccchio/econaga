import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';

class LocationSelectionPage extends StatefulWidget {
  @override
  _LocationSelectionPageState createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng _currentPosition = LatLng(13.6218, 123.1945); // Default to Naga City
  LatLng _initialPosition = LatLng(13.6218, 123.1945); // Initial center
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getLocationFromIP(); // Fetch location from IP on initialization
  }

  Future<void> getLocationFromIP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('https://ipinfo.io/json?token=ccd831dd8116ed'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final location = data['loc'].split(',');
        final latitude = double.parse(location[0]);
        final longitude = double.parse(location[1]);

        // Update the current position and map
        setState(() {
          _currentPosition = LatLng(latitude, longitude);
          _initialPosition = LatLng(latitude, longitude); // Update initial position
          _mapController.move(_currentPosition, 14.0); // Move map to current position
        });
      } else {
        print('Failed to get location from IP');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location. Using default.')),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location. Using default.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchLocation() async {
    if (_searchController.text.isNotEmpty) {
      try {
        final locations = await locationFromAddress(_searchController.text);
        if (locations.isNotEmpty) {
          final newLocation = locations.first;
          setState(() {
            _currentPosition = LatLng(newLocation.latitude, newLocation.longitude);
            _mapController.move(_currentPosition, 14.0); // Move map to new location
          });
        }
      } catch (e) {
        print('Error searching location: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location not found')),
        );
      }
    }
  }

  Future<void> _goToCurrentLocation() async {
    // Fetch the current location from IP again
    await getLocationFromIP();
    // After fetching, move the map to the current position
    _mapController.move(_currentPosition, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _currentPosition); // Return the selected location
            },
          ),
        ],
      ),
      body: Expanded(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialPosition,
                initialZoom: 14.0,
                backgroundColor: Colors.grey[300]!,
                onTap: (tapPosition, latLng) {
                  setState(() {
                    _currentPosition = latLng; // Update current position on tap
                    _mapController.move(latLng, 14.0);
                  });
                },
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition, // Use current position for marker
                      width: 80.0,
                      height: 80.0,
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _goToCurrentLocation,
                child: Icon(Icons.my_location),
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
