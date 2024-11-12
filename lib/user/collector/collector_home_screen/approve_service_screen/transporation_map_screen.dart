import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TransportationMapScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  TransportationMapScreen({required this.userData});

  @override
  _TransportationMapScreenState createState() => _TransportationMapScreenState();
}

class _TransportationMapScreenState extends State<TransportationMapScreen> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  bool _isNavigating = false;
  bool _hasArrived = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _addMarkers();
    _getCurrentLocation();
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
    if (widget.userData['pickup_location'] != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('pickup_location'),
          position: LatLng(
            widget.userData['pickup_location']['latitude'],
            widget.userData['pickup_location']['longitude'],
          ),
          infoWindow: InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    if (widget.userData['destination_location'] != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('destination_location'),
          position: LatLng(
            widget.userData['destination_location']['latitude'],
            widget.userData['destination_location']['longitude'],
          ),
          infoWindow: InfoWindow(title: 'Destination Location'),
        ),
      );
    }
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    });
  }

  void _startNavigation() async {
    // Display a toast message indicating that navigation is not available
    Fluttertoast.showToast(
      msg: "Navigation feature is not available for now.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    // If you have future navigation logic, you can uncomment this
    /*
  setState(() {
    _isNavigating = true;
  });

  _positionStream = Geolocator.getPositionStream(
    desiredAccuracy: LocationAccuracy.high,
    distanceFilter: 10,
  ).listen((Position position) {
    _updateCurrentPosition(LatLng(position.latitude, position.longitude));
  });
  */
  }


  void _updateCurrentPosition(LatLng position) {
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
      _updatePolylines();
      _checkArrival();
    });
  }

  void _updatePolylines() async {
    if (_currentPosition == null || widget.userData['destination_location'] == null) return;

    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> polylineCoordinates = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: 'AIzaSyD4UAtE_r8JjBbd0o5qfv3ZSPX_8xkNJ7c', // Replace with your API key
      request: PolylineRequest(
        origin: PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination: PointLatLng(
          widget.userData['destination_location']['latitude'], // Extract latitude correctly
          widget.userData['destination_location']['longitude'], // Extract longitude correctly
        ),
        mode: TravelMode.driving,
      ),
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
            _currentPosition!.latitude < widget.userData['destination_location']['latitude']
                ? _currentPosition!.latitude
                : widget.userData['destination_location']['latitude'],
            _currentPosition!.longitude < widget.userData['destination_location']['longitude']
                ? _currentPosition!.longitude
                : widget.userData['destination_location']['longitude'],
          ),
          northeast: LatLng(
            _currentPosition!.latitude > widget.userData['destination_location']['latitude']
                ? _currentPosition!.latitude
                : widget.userData['destination_location']['latitude'],
            _currentPosition!.longitude > widget.userData['destination_location']['longitude']
                ? _currentPosition!.longitude
                : widget.userData['destination_location']['longitude'],
          ),
        ),
        100.0,
      ),
    );
  }

  void _checkArrival() {
    if (_currentPosition == null || widget.userData['destination_location'] == null) return;

    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.userData['destination_location']['latitude'],
      widget.userData['destination_location']['longitude'],
    );

    if (distanceInMeters < 50) {
      if (!mounted) return;
      setState(() {
        _hasArrived = true;
      });
      _positionStream?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have arrived at the destination!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Transportation Map',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.userData['pickup_location']['latitude'],
                  widget.userData['pickup_location']['longitude'],
                ),
                zoom: 15.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('USERS_ACCOUNTS')
                          .doc(widget.userData['user_id'])
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return _buildListTile(
                            context,
                            initials: '${widget.userData['first_name'][0]}${widget.userData['last_name'][0]}',
                            data: widget.userData,
                            profilePicture: null,
                          );
                        }

                        // Use updated data from Firestore
                        if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          final profilePicture = userData['profile_picture'];
                          return _buildListTile(
                            context,
                            initials: '${userData['first_name'][0]}${userData['last_name'][0]}', // Use updated initials
                            data: userData, // Use updated data
                            profilePicture: profilePicture,
                          );
                        } else {
                          return _buildListTile(
                            context,
                            initials: '${widget.userData['first_name'][0]}${widget.userData['last_name'][0]}',
                            data: widget.userData,
                            profilePicture: null,
                          );
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow(Icons.phone, 'Contact', widget.userData['contact_number'] ?? 'N/A'),
                    _buildInfoRow(Icons.location_on, 'Pickup', widget.userData['pickup_location']['address'] ?? 'N/A'),
                    _buildInfoRow(Icons.location_on, 'Destination', widget.userData['destination_location']['address'] ?? 'N/A'),
                    SizedBox(height: 16),
                    if (!_isNavigating && !_hasArrived)
                      ElevatedButton(
                        onPressed: _startNavigation,
                        child: Text('Start Navigation'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          textStyle: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ),
                    if (_hasArrived)
                      ElevatedButton(
                        onPressed: () {
                          // Add completion logic here
                        },
                        child: Text('Complete Trip'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          textStyle: GoogleFonts.poppins(fontSize: 16),
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
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue,
            child: profilePicture != null && profilePicture.isNotEmpty
                ? ClipOval(child: Image.network(profilePicture, fit: BoxFit.cover, width: 60, height: 60))
                : Text(initials, style: TextStyle(fontSize: 24, color: Colors.white)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              '${data['first_name']} ${data['last_name']}', // Use updated user data
              style: GoogleFonts.poppins(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        SizedBox(width: 8),
        Expanded(
          child: Text('$title: $value', style: GoogleFonts.poppins(fontSize: 16)),
        ),
      ],
    );
  }
}
