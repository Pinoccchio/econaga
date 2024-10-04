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
          .doc(widget.userId) // Access document by userId
          .get();

      if (doc.exists) {
        setState(() {
          _firstName = doc['first_name'] ?? '';
          _lastName = doc['last_name'] ?? '';
          _email = doc['email'] ?? '';
          _contactNumber = doc['phone_number'] ?? '';

          // Update controllers with fetched data
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
  }

  Future<void> _updateAddress(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = '${place.street}, ${place.locality}, ${place.country}';
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
      _addMarker(currentLatLng);
      _mapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _selectPlace(Prediction prediction) {
    if (prediction.lat != null && prediction.lng != null) {
      final lat = double.parse(prediction.lat!);
      final lng = double.parse(prediction.lng!);
      final newPosition = LatLng(lat, lng);
      _addMarker(newPosition);
      _mapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
      _searchController.text = prediction.description!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Garbage Collection Request',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPersonalInfoSection(),
              SizedBox(height: 24),
              _buildMapTypeSelector(),
              SizedBox(height: 24),
              _buildMapSection(),
              SizedBox(height: 24),
              _buildNoteSection(),
              SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
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

  Widget _buildMapTypeSelector() {
    return Row(
      children: [
        Text(
          'Map View: ',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        DropdownButton<MapType>(
          value: _selectedMapType,
          items: [
            DropdownMenuItem(value: MapType.normal, child: Text('Normal')),
            DropdownMenuItem(value: MapType.satellite, child: Text('Satellite')),
            DropdownMenuItem(value: MapType.terrain, child: Text('Terrain')),
            DropdownMenuItem(value: MapType.hybrid, child: Text('Hybrid')),
          ],
          onChanged: (MapType? type) {
            setState(() {
              _selectedMapType = type ?? MapType.normal;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            GooglePlaceAutoCompleteTextField(
              textEditingController: _searchController,
              googleAPIKey: "YOUR_GOOGLE_API_KEY",
              inputDecoration: InputDecoration(
                hintText: "Search for a location",
                border: OutlineInputBorder(),
              ),
              debounceTime: 800,
              countries: ["ph"],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: _selectPlace,
              itemClick: _selectPlace,
            ),
            SizedBox(height: 16),
            Text(
              _address,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            ),
            SizedBox(height: 16),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 200,
                    child: GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                      },
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(target: _center, zoom: 14),
                        markers: _markers,
                        mapType: _selectedMapType,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                        },
                        onTap: (position) => _addMarker(position),
                        gestureRecognizers: Set()
                          ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer())),
                      ),
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Enter your instructions here',
                border: OutlineInputBorder(),
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
        onPressed: _submitGarbageCollectionRequest,  // Call the submit function
        child: Text(
          'Submit Request',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _submitGarbageCollectionRequest() async {
    // Check if any of the required fields are empty
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _contactNumberController.text.isEmpty) {

      // Show red SnackBar for error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,  // Red color for the error
          duration: Duration(seconds: 3),
        ),
      );
      return;  // Stop further execution
    }

    if (_markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a location on the map.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,  // Red color for the error
          duration: Duration(seconds: 3),
        ),
      );
      return;  // Stop further execution
    }

    // If no field is empty, continue with the submission process
    try {
      // Prepare the data to save
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
        'note': _note.isNotEmpty ? _note : null,  // Note is optional
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      };

      // Automatically generate a unique ID for each request
      await FirebaseFirestore.instance.collection('GARBAGE_REQUESTS').add(requestData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request submitted successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,  // Green color for success
          duration: Duration(seconds: 3),
        ),
      );

      // Show the Pending Approval dialog
      showDialog(
        context: context,
        builder: (context) => ApprovalDialog(),
      );

    } catch (e) {
      // Show error message if saving fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request. Please try again.'),
          backgroundColor: Colors.red,  // Red color for the error
          duration: Duration(seconds: 3),
        ),
      );
      print('Error submitting request: $e');
    }
  }


  Widget _buildTextField(String label, TextEditingController controller, String errorText) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return errorText;
        }
        return null;
      },
    );
  }

  Widget _buildMapIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }
}