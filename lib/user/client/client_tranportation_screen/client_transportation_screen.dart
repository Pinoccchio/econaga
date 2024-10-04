import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../designs/app_colors.dart';

class ClientTransportationScreen extends StatefulWidget {
  final String userId;

  ClientTransportationScreen({required this.userId});

  @override
  _ClientTransportationScreenState createState() => _ClientTransportationScreenState();
}

class _ClientTransportationScreenState extends State<ClientTransportationScreen> {
  final _formKey = GlobalKey<FormState>();
  GoogleMapController? _pickupMapController;
  GoogleMapController? _destinationMapController;

  String? _serviceType;
  LatLng _center = LatLng(13.6217, 123.1948);
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  Set<Marker> _markers = {};
  String _pickupAddress = 'Tap on the map to select Pickup location';
  String _destinationAddress = 'Tap on the map to select Destination location';

  MapType _selectedMapType = MapType.normal;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _contactNumberController;

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _contactNumber = '';

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _contactNumberController = TextEditingController();
    _fetchUserData();
    _addMarker(_center, 'pickup');
    _addMarker(_center, 'destination');
  }

  @override
  void dispose() {
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


  void _addMarker(LatLng position, String locationType) {
    setState(() {
      if (locationType == 'pickup') {
        _pickupLocation = position;
        _pickupAddress = 'Updating...';
      } else {
        _destinationLocation = position;
        _destinationAddress = 'Updating...';
      }

      _updateAddress(position, locationType);

      _markers = {
        if (_pickupLocation != null)
          Marker(
            markerId: MarkerId('pickup'),
            position: _pickupLocation!,
            infoWindow: InfoWindow(title: 'Pickup Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        if (_destinationLocation != null)
          Marker(
            markerId: MarkerId('destination'),
            position: _destinationLocation!,
            infoWindow: InfoWindow(title: 'Destination Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
      };

      _pickupMapController?.animateCamera(CameraUpdate.newLatLng(position));
      _destinationMapController?.animateCamera(CameraUpdate.newLatLng(position));
    });
  }

  void _updateAddress(LatLng position, String locationType) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          if (locationType == 'pickup') {
            _pickupAddress = '${place.street}, ${place.locality}, ${place.country}';
          } else {
            _destinationAddress = '${place.street}, ${place.locality}, ${place.country}';
          }
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _onMapTap(LatLng position, String locationType) {
    _addMarker(position, locationType);
  }

  Future<void> _getCurrentLocation(String locationType) async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      _addMarker(currentLatLng, locationType);
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _resetMarkers(String locationType) {
    setState(() {
      if (locationType == 'pickup') {
        _pickupLocation = null;
        _pickupAddress = 'Tap on the map to select Pickup location';
      } else {
        _destinationLocation = null;
        _destinationAddress = 'Tap on the map to select Destination location';
      }
      _markers = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Transportation Request',
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
              _buildMapSection('Pickup', _pickupAddress, 'pickup'),
              SizedBox(height: 24),
              _buildMapSection('Destination', _destinationAddress, 'destination'),
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
            SizedBox(height: 12),
            _buildServiceTypeDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Service Type',
        border: OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: 'burial', child: Text('Burial Service')),
        DropdownMenuItem(value: 'lipat_bahay', child: Text('Lipat Bahay Service')),
      ],
      onChanged: (String? newValue) {
        setState(() {
          _serviceType = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a service type';
        }
        return null;
      },
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

  Widget _buildMapSection(String title, String address, String locationType) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title Location',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              address,
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
                        // Disable the scroll interruption here
                        FocusScope.of(context).unfocus();
                      },
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(target: _center, zoom: 14),
                        markers: _markers,
                        mapType: _selectedMapType,
                        onMapCreated: (GoogleMapController controller) {
                          if (locationType == 'pickup') {
                            _pickupMapController = controller;
                          } else {
                            _destinationMapController = controller;
                          }
                        },
                        onTap: (position) => _onMapTap(position, locationType),
                        gestureRecognizers: Set()
                          ..add(Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer())),
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
                        onTap: () => _getCurrentLocation(locationType),
                      ),
                      SizedBox(height: 8),
                      _buildMapIconButton(
                        icon: Icons.refresh,
                        onTap: () => _resetMarkers(locationType),
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


  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Perform submit action
          }
        },
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
