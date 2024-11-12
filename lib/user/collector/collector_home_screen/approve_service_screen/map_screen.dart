import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MapScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  MapScreen({required this.userData});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  late LatLng _center;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  bool _isNavigating = false;
  bool _hasArrived = false;
  StreamSubscription<Position>? _positionStream;

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
    if (!mounted) return; // Check if the widget is still mounted
    setState(() {
      _currentPosition = position;
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // Set the marker color to green
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

    // Optionally, if you want to set _isNavigating to true, you can keep this line:
   // setState(() {
    //  _isNavigating = true; // This may be commented out if you don't want to indicate navigation is starting
  //  });

    // Uncomment this section if you decide to add position updates later
    /*
  // Start the position stream
  _positionStream = Geolocator.getPositionStream(
    desiredAccuracy: LocationAccuracy.high,
    distanceFilter: 10, // Distance in meters to trigger updates
  ).listen((Position position) {
    _updateCurrentPosition(LatLng(position.latitude, position.longitude));
  });
  */
  }


  void _updateCurrentPosition(LatLng position) {
    if (!mounted) return; // Check if the widget is still mounted
    setState(() {
      _currentPosition = position;
      _updatePolylines();
      _checkArrival();
    });
  }

  void _updatePolylines() async {
    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> polylineCoordinates = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: 'AIzaSyD4UAtE_r8JjBbd0o5qfv3ZSPX_8xkNJ7c', // Replace with your API key
      request: PolylineRequest(
        origin: PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination: PointLatLng(_center.latitude, _center.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    if (!mounted) return; // Check if the widget is still mounted
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
            _currentPosition!.latitude < _center.latitude ? _currentPosition!.latitude : _center.latitude,
            _currentPosition!.longitude < _center.longitude ? _currentPosition!.longitude : _center.longitude,
          ),
          northeast: LatLng(
            _currentPosition!.latitude > _center.latitude ? _currentPosition!.latitude : _center.latitude,
            _currentPosition!.longitude > _center.longitude ? _currentPosition!.longitude : _center.longitude,
          ),
        ),
        100.0,
      ),
    );
  }

  void _checkArrival() {
    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _center.latitude,
      _center.longitude,
    );

    if (distanceInMeters < 50) { // Consider arrived if within 50 meters
      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        _hasArrived = true;
      });
      _positionStream?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have arrived at the destination!')),
      );
    }
  }

  void _completePickup() {
    FirebaseFirestore.instance
        .collection('GARBAGE_REQUESTS')
        .doc(widget.userData['request_id'])
        .update({'status': 'completed'})
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pickup completed successfully!')),
      );
      Navigator.of(context).pop(); // Return to the previous screen
    })
        .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing pickup: $error')),
      );
    });
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
          'User Location',
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
                target: _center,
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

                        if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          final profilePicture = userData['profile_picture'];
                          return _buildListTile(
                            context,
                            initials: '${widget.userData['first_name'][0]}${widget.userData['last_name'][0]}',
                            data: widget.userData,
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
                    _buildInfoRow(Icons.phone, 'Contact', widget.userData['contact_number']),
                    _buildInfoRow(Icons.location_on, 'Address', widget.userData['location']['address']),
                    if (widget.userData['note'] != null)
                      _buildInfoRow(Icons.note, 'Note', widget.userData['note']),
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
                        onPressed: _completePickup,
                        child: Text('Complete Pickup'),
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
              '${data['first_name']} ${data['last_name']}',
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
