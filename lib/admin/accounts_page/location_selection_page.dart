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
  LatLng _nagaCity = LatLng(13.6218, 123.1945); // Naga City coordinates
  LatLng _markerPosition = LatLng(13.6218, 123.1945); // Initial marker position (Naga City)
  bool _isLoading = false;

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

        // Update the marker position and map
        setState(() {
          _markerPosition = LatLng(latitude, longitude);
          _mapController.move(_markerPosition, 14.0); // Move map to current position
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
            _markerPosition = LatLng(newLocation.latitude, newLocation.longitude);
            _mapController.move(_markerPosition, 14.0); // Move map to new location
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

  void _goToCurrentLocation() async {
    // Fetch the current location from IP
    await getLocationFromIP();
  }

  void _resetToNagaCity() {
    setState(() {
      _markerPosition = _nagaCity;
      _mapController.move(_nagaCity, 14.0);
    });
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
              Navigator.pop(context, _markerPosition); // Return the selected location
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _nagaCity,
              initialZoom: 14.0,
              backgroundColor: Colors.grey[300]!,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _markerPosition = latLng; // Update marker position on tap
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
                    point: _markerPosition,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  onPressed: _goToCurrentLocation,
                  child: Icon(Icons.my_location),
                  backgroundColor: Colors.green,
                  heroTag: 'currentLocation',
                ),
                SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: _resetToNagaCity,
                  child: Icon(Icons.home),
                  backgroundColor: Colors.blue,
                  heroTag: 'nagaCity',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

