import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../designs/app_colors.dart';
import 'approval_dialog.dart';


class ClientGarbageCollectionScreen extends StatefulWidget {
  final String userId;

  ClientGarbageCollectionScreen({required this.userId});

  @override
  _ClientGarbageCollectionScreenState createState() => _ClientGarbageCollectionScreenState();
}

class _ClientGarbageCollectionScreenState extends State<ClientGarbageCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  GoogleMapController? _mapController;

  LatLng _center = LatLng(13.6217, 123.1948);
  Set<Marker> _markers = {};
  String _address = 'Tap on the map or search to select location';
  final _searchController = TextEditingController();

  MapType _selectedMapType = MapType.normal;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _contactNumberController;

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _contactNumber = '';
  String _note = '';

  bool _isExternalClient = false;


  final LatLngBounds _nagaCityBounds = LatLngBounds(
    southwest: LatLng(13.5500, 123.1500),
    northeast: LatLng(13.6934, 123.2397),
  );

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _contactNumberController = TextEditingController();
    _fetchUserData();
    _addMarker(_center);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      print('Fetching user data for userId: ${widget.userId}');
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        setState(() {
          _firstName = doc['first_name'] ?? '';
          _lastName = doc['last_name'] ?? '';
          _email = doc['email'] ?? '';
          _contactNumber = doc['phone_number'] ?? '';

          _firstNameController.text = _firstName;
          _lastNameController.text = _lastName;
          _emailController.text = _email;
          _contactNumberController.text = _contactNumber;
        });
        print('User data fetched successfully:');
        print('First Name: $_firstName');
        print('Last Name: $_lastName');
        print('Email: $_email');
        print('Contact Number: $_contactNumber');
      } else {
        print('No user data found for userId: ${widget.userId}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _addMarker(LatLng position) {
    if (_nagaCityBounds.contains(position)) {
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId('selectedLocation'),
            position: position,
            infoWindow: InfoWindow(title: 'Selected Location'),
          ),
        );
      });
      _updateAddress(position);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a location within Naga City.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _address = 'Unable to fetch address';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      if (_nagaCityBounds.contains(currentLatLng)) {
        _addMarker(currentLatLng);
        _mapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your current location is outside Naga City. Please select a location within Naga City.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _selectPlace(Prediction prediction) {
    if (prediction.lat != null && prediction.lng != null) {
      final lat = double.parse(prediction.lat!);
      final lng = double.parse(prediction.lng!);
      final newPosition = LatLng(lat, lng);
      if (_nagaCityBounds.contains(newPosition)) {
        _addMarker(newPosition);
        _mapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
        _searchController.text = prediction.description!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected location is outside Naga City. Please choose a location within Naga City.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Naga City Map',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _center, zoom: 14),
                  markers: _markers,
                  mapType: MapType.normal,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    controller.animateCamera(CameraUpdate.newLatLngBounds(_nagaCityBounds, 50.0));
                  },
                  onTap: (position) => _addMarker(position),
                  zoomGesturesEnabled: true,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  polygons: {
                    Polygon(
                      polygonId: PolygonId('nagaCityBoundary'),
                      points: [
                        LatLng(13.5500, 123.1500),
                        LatLng(13.6934, 123.1500),
                        LatLng(13.6934, 123.2397),
                        LatLng(13.5500, 123.2397),
                      ],
                      strokeWidth: 3,
                      strokeColor: Colors.blue,
                      fillColor: Colors.blue.withOpacity(0.1),
                    ),
                  },
                  gestureRecognizers: Set()
                    ..add(Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer())),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Column(
                    children: [
                      _buildMapIconButton(
                        icon: Icons.my_location,
                        onTap: _getCurrentLocation,
                      ),
                      SizedBox(height: 8),
                      _buildMapIconButton(
                        icon: Icons.refresh,
                        onTap: () {
                          setState(() {
                            _markers.clear();
                            _address = 'Tap on the map or search to select location';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          _address,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textColor.withOpacity(0.7)),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: Text(
          'Garbage Collection Request',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPersonalInfoSection(),
                SizedBox(height: 24),
                _buildLocationSection(),
                SizedBox(height: 24),
                _buildNoteSection(),
                SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('External Client', style: GoogleFonts.poppins(color: AppColors.textColor)),
                Switch(
                  value: _isExternalClient,
                  onChanged: (value) {
                    setState(() {
                      _isExternalClient = value;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildTextField('First Name', _firstNameController, 'Please enter your first name'),
            SizedBox(height: 12),
            _buildTextField('Last Name', _lastNameController, 'Please enter your last name'),
            SizedBox(height: 12),
            _buildTextField('Email', _emailController, 'Please enter a valid email'),
            SizedBox(height: 12),
            _buildTextField('Contact Number', _contactNumberController, 'Please enter a contact number'),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collection Location',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            SizedBox(height: 16),
            GooglePlaceAutoCompleteTextField(
              textEditingController: _searchController,
              googleAPIKey: "AIzaSyD4UAtE_r8JjBbd0o5qfv3ZSPX_8xkNJ7c",
              inputDecoration: InputDecoration(
                hintText: "Search for location",
                border: OutlineInputBorder(),
              ),
              debounceTime: 800,
              countries: ["ph"],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (Prediction prediction) {
                _selectPlace(prediction);
              },
              itemClick: (Prediction prediction) {
                _selectPlace(prediction);
              },
            ),
            SizedBox(height: 16),
            _buildMapSection(),
          ],
        ),
      ),
    );
  }


  Widget _buildNoteSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Note to Collector',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Enter your instructions here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accentColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                ),
              ),
              maxLines: 3,
              onChanged: (value) => _note = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitGarbageCollectionRequest,
        child: Text(
          'Submit Request',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
      ),
    );
  }

  void _submitGarbageCollectionRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_markers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select a location on the map.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      try {
        Map<String, dynamic> requestData = {
          'user_id': widget.userId,
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'email': _emailController.text,
          'contact_number': _contactNumberController.text,
          'location': {
            'latitude': _markers.first.position.latitude,
            'longitude': _markers.first.position.longitude,
            'address': _address,
          },
          'note': _note.isNotEmpty ? _note : null,
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
          'user_type': _isExternalClient ? 'external' : 'official',
        };

        await FirebaseFirestore.instance.collection('GARBAGE_REQUESTS').add(requestData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request submitted successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        showDialog(
          context: context,
          builder: (context) => ApprovalDialog(),
        );

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        print('Error submitting request: $e');
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, String errorText) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textColor.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.accentColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
      ),
      style: TextStyle(color: AppColors.textColor),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return errorText;
        }
        return null;
      },
      enabled: label != 'Email', // Disable editing for the email field
    );
  }

  Widget _buildMapIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primaryColor, size: 24),
      ),
    );
  }
}

class AppColors {
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color accentColor = Color(0xFF81C784);
  static const Color backgroundColor = Color(0xFFF1F8E9);
  static const Color textColor = Color(0xFF333333);
  static const Color cardColor = Colors.white;
}

