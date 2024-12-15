import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GarbageMapScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  GarbageMapScreen({required this.userData});

  @override
  _GarbageMapScreenState createState() => _GarbageMapScreenState();
}

class _GarbageMapScreenState extends State<GarbageMapScreen> {
  late GoogleMapController mapController;
  late LatLng _center;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  bool _hasArrived = false;
  StreamSubscription<Position>? _positionStream;
  MapType _mapType = MapType.normal;
  List<Step> _directions = [];
  String _estimatedArrival = '';
  bool _isNavigating = false;
  String? _selfieImageUrl;
  bool _canCompletePickup = false;

  @override
  void initState() {
    super.initState();
    _center = LatLng(
      widget.userData['location']['latitude'],
      widget.userData['location']['longitude'],
    );
    _markers.add(
      Marker(
        markerId: MarkerId('user_location'),
        position: _center,
        infoWindow: InfoWindow(
          title: '${widget.userData['first_name']} ${widget.userData['last_name']}',
          snippet: widget.userData['location']['address'],
        ),
      ),
    );
    _getCurrentLocation();
    _fetchSelfieImageUrl();
  }

  Future<void> _fetchSelfieImageUrl() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(widget.userData['user_id'])
          .get();

      if (userDoc.exists) {
        setState(() {
          _selfieImageUrl = (userDoc.data() as Map<String, dynamic>)['selfieImageUrl'];
        });
      }
    } catch (e) {
      print('Error fetching selfie image URL: $e');
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _setCurrentPosition(LatLng(position.latitude, position.longitude));
  }

  void _setCurrentPosition(LatLng position) {
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    });
  }

  void _startNavigation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _setCurrentPosition(LatLng(position.latitude, position.longitude));

    _positionStream = Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ).listen((Position newPosition) {
      _updateCurrentPosition(LatLng(newPosition.latitude, newPosition.longitude));
    });

    await _updatePolylines();
    setState(() {
      _isNavigating = true;
    });
  }

  void _updateCurrentPosition(LatLng position) {
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
      _updatePolylines();
      _checkArrival();
    });
  }

  Future<void> _updatePolylines() async {
    if (_currentPosition == null) return;

    _directions = await _getDirections(_currentPosition!, _center);

    if (_directions.isNotEmpty) {
      _estimatedArrival = _directions.first.duration;
    }

    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> polylineCoordinates = [];

    PolylineRequest request = PolylineRequest(
      origin:  PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      destination:  PointLatLng(_center.latitude, _center.longitude),
      mode: TravelMode.driving,
    );

// Request directions with your API key
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: 'AIzaSyD4UAtE_r8JjBbd0o5qfv3ZSPX_8xkNJ7c', // Provide your Google API key here
      request: request,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    if (!mounted) return;
    setState(() {
      _polylines.clear();
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        color: Colors.blue,
        points: polylineCoordinates,
        width: 5,
      ));
    });

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            polylineCoordinates.map((point) => point.latitude).reduce((a, b) => a < b ? a : b),
            polylineCoordinates.map((point) => point.longitude).reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            polylineCoordinates.map((point) => point.latitude).reduce((a, b) => a > b ? a : b),
            polylineCoordinates.map((point) => point.longitude).reduce((a, b) => a > b ? a : b),
          ),
        ),
        100.0,
      ),
    );
  }

  Future<List<Step>> _getDirections(LatLng origin, LatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=AIzaSyD4UAtE_r8JjBbd0o5qfv3ZSPX_8xkNJ7c';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Step> steps = [];
      if (data['status'] == 'OK') {
        for (var step in data['routes'][0]['legs'][0]['steps']) {
          steps.add(Step(
            instruction: step['html_instructions'],
            distance: step['distance']['text'],
            duration: step['duration']['text'],
          ));
        }
      }
      return steps;
    } else {
      throw Exception('Failed to load directions');
    }
  }

  void _checkArrival() {
    if (_currentPosition == null) return;

    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _center.latitude,
      _center.longitude,
    );

    if (distanceInMeters < 50) {
      setState(() {
        _hasArrived = true;
        _isNavigating = false;
        _canCompletePickup = true;
      });
      _positionStream?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have arrived at the destination!'),
          backgroundColor: Colors.green, // Green for positive messages
        ),
      );
    }
  }

  Future<void> _completePickup() async {
    String? docId = widget.userData['request_id'] as String?;
    if (docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Request ID not found'),
          backgroundColor: Colors.red, // Red for errors
        ),
      );
      return;
    }

    try {
      // Format the current date and time as "Dec 15, 2024 9:32 PM"
      String dateCompleted = DateFormat('MMM d, yyyy h:mm a').format(DateTime.now());

      await FirebaseFirestore.instance.collection('GARBAGE_REQUESTS').doc(docId).update({
        'status': 'completed',
        'dateCompleted': dateCompleted, // Add the formatted date
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pickup completed successfully!'),
          backgroundColor: Colors.green, // Green for success
        ),
      );

      setState(() {
        _canCompletePickup = false;
      });
    } catch (error) {
      print('Error completing pickup: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete pickup. Please try again.'),
          backgroundColor: Colors.red, // Red for errors
        ),
      );
    }
  }

  void _changeMapType(MapType type) {
    setState(() {
      _mapType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 15.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: _mapType,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: 40,
            right: 10,
            child: PopupMenuButton<MapType>(
              icon: Icon(Icons.layers, color: Colors.black),
              onSelected: _changeMapType,
              itemBuilder: (context) => <PopupMenuEntry<MapType>>[
                const PopupMenuItem<MapType>(
                  value: MapType.normal,
                  child: Text('Normal'),
                ),
                const PopupMenuItem<MapType>(
                  value: MapType.hybrid,
                  child: Text('Hybrid'),
                ),
                const PopupMenuItem<MapType>(
                  value: MapType.satellite,
                  child: Text('Satellite'),
                ),
                const PopupMenuItem<MapType>(
                  value: MapType.terrain,
                  child: Text('Terrain'),
                ),
              ],
            ),
          ),
          if (_isNavigating)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Arrival: $_estimatedArrival',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      if (_directions.isNotEmpty)
                        html.Html(data: _directions.first.instruction),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 70,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildListTile(
                      context,
                      initials: '${widget.userData['first_name'][0]}${widget.userData['last_name'][0]}',
                      data: widget.userData,
                      profilePicture: _selfieImageUrl,
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow(Icons.phone, 'Contact', widget.userData['contact_number'] as String?),
                    _buildInfoRow(Icons.location_on, 'Address', widget.userData['location']?['address'] as String?),
                    if (widget.userData['note'] != null)
                      _buildInfoRow(Icons.note, 'Note', widget.userData['note'] as String?),
                    SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isNavigating ? null : _startNavigation,
                        child: Text(_isNavigating ? 'Navigating...' : 'Start Navigation'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          textStyle: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ),
                    ),
                    if (_canCompletePickup)
                      Center(
                        child: ElevatedButton(
                          onPressed: _completePickup,
                          child: Text('Complete Pickup'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            textStyle: GoogleFonts.poppins(fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {String initials = '', required Map<String, dynamic> data, String? profilePicture}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue,
          backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
          child: profilePicture == null
              ? Text(initials, style: TextStyle(fontSize: 24, color: Colors.white))
              : null,
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String? value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(value ?? 'N/A', style: GoogleFonts.poppins(fontSize: 14)),
        ),
      ],
    );
  }
}

class Step {
  final String instruction;
  final String distance;
  final String duration;

  Step({required this.instruction, required this.distance, required this.duration});
}