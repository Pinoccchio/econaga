import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TransportationAndBurialMapScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  TransportationAndBurialMapScreen({required this.userData});

  @override
  _TransportationAndBurialMapScreenState createState() => _TransportationAndBurialMapScreenState();
}

class _TransportationAndBurialMapScreenState extends State<TransportationAndBurialMapScreen> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  bool _hasArrivedAtPickup = false;
  bool _hasArrivedAtDestination = false;
  StreamSubscription<Position>? _positionStream;
  MapType _mapType = MapType.normal;
  List<Step> _directions = [];
  String _estimatedArrival = '';
  bool _isNavigating = false;
  bool _isNavigatingToPickup = true;
  String? _selfieImageUrl;
  bool _canCompleteTrip = false;

  @override
  void initState() {
    super.initState();
    _pickupLocation = LatLng(
      widget.userData['pickup_location']['latitude'],
      widget.userData['pickup_location']['longitude'],
    );
    _destinationLocation = LatLng(
      widget.userData['destination_location']['latitude'],
      widget.userData['destination_location']['longitude'],
    );
    _addMarkers();
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

  void _addMarkers() {
    _markers.add(
      Marker(
        markerId: MarkerId('pickup_location'),
        position: _pickupLocation!,
        infoWindow: InfoWindow(title: 'Pickup Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );
    _markers.add(
      Marker(
        markerId: MarkerId('destination_location'),
        position: _destinationLocation!,
        infoWindow: InfoWindow(title: 'Destination Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
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

    LatLng destination = _isNavigatingToPickup ? _pickupLocation! : _destinationLocation!;
    _directions = await _getDirections(_currentPosition!, destination);

    if (_directions.isNotEmpty) {
      _estimatedArrival = _directions.first.duration;
    }

    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> polylineCoordinates = [];

    PolylineRequest request = PolylineRequest(
      origin:  PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      destination:  PointLatLng(destination.latitude, destination.longitude),
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
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=YOUR_GOOGLE_API_KEY';

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

    LatLng targetLocation = _isNavigatingToPickup ? _pickupLocation! : _destinationLocation!;
    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );

    if (distanceInMeters < 50) {
      if (_isNavigatingToPickup) {
        setState(() {
          _hasArrivedAtPickup = true;
          _isNavigatingToPickup = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have arrived at the pickup location!'),
            backgroundColor: Colors.green,
          ),
        );
        _updatePolylines();
      } else {
        setState(() {
          _hasArrivedAtDestination = true;
          _isNavigating = false;
          _canCompleteTrip = true;
        });
        _positionStream?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have arrived at the destination!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _changeMapType(MapType type) {
    setState(() {
      _mapType = type;
    });
  }

  Future<void> _completeTrip() async {
    String? docId = widget.userData['request_id'] as String?;
    if (docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Request ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      String dateCompleted = DateFormat('MMM d, yyyy h:mm a').format(DateTime.now());
      String collectionName = widget.userData['request_type'] == 'Transportation'
          ? 'TRANSPORTATION_REQUESTS'
          : 'BURIAL_REQUESTS';

      await FirebaseFirestore.instance.collection(collectionName).doc(docId).update({
        'status': 'completed',
        'dateCompleted': dateCompleted,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _canCompleteTrip = false;
      });
    } catch (error) {
      print('Error completing trip: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete trip. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _pickupLocation!,
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
                    _buildInfoRow(Icons.category, 'Request Type', widget.userData['request_type']),
                    _buildInfoRow(Icons.phone, 'Contact', widget.userData['contact_number']),
                    _buildInfoRow(Icons.location_on, 'Pickup', widget.userData['pickup_location']['address']),
                    _buildInfoRow(Icons.location_on, 'Destination', widget.userData['destination_location']['address']),
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
                    if (_canCompleteTrip)
                      Center(
                        child: ElevatedButton(
                          onPressed: _completeTrip,
                          child: Text('Complete Trip'),
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
            '${data['first_name']} ${data['last_name']}',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text('$title: $value', style: GoogleFonts.poppins(fontSize: 14)),
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

