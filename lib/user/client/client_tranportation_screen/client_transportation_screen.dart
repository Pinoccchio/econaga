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
import '../client_garbage_collection_screen/approval_dialog.dart';

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
  Set<Marker> _pickupMarkers = {};
  Set<Marker> _destinationMarkers = {};
  String _pickupAddress = 'Tap on the map or search to select pickup location';
  String _destinationAddress = 'Tap on the map or search to select destination location';
  final _pickupSearchController = TextEditingController();
  final _destinationSearchController = TextEditingController();

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

  String? selectedRegion;
  String? selectedProvince;
  String? selectedMunicipality;
  String? selectedBarangay;

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
    _addMarker(_center, true);
    _addMarker(_center, false);
  }

  @override
  void dispose() {
    _pickupSearchController.dispose();
    _destinationSearchController.dispose();
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

  void _addMarker(LatLng position, bool isPickup) {
    if (_nagaCityBounds.contains(position)) {
      setState(() {
        if (isPickup) {
          _pickupMarkers.clear();
          _pickupMarkers.add(
            Marker(
              markerId: MarkerId('pickup'),
              position: position,
              infoWindow: InfoWindow(title: 'Pickup Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        } else {
          _destinationMarkers.clear();
          _destinationMarkers.add(
            Marker(
              markerId: MarkerId('destination'),
              position: position,
              infoWindow: InfoWindow(title: 'Destination Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        }
      });
      _updateAddress(position, isPickup);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a location within Naga City.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateAddress(LatLng position, bool isPickup) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          if (isPickup) {
            _pickupAddress = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
          } else {
            _destinationAddress = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
          }
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        if (isPickup) {
          _pickupAddress = 'Unable to fetch address';
        } else {
          _destinationAddress = 'Unable to fetch address';
        }
      });
    }
  }

  Future<void> _getCurrentLocation(bool isPickup) async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      if (_nagaCityBounds.contains(currentLatLng)) {
        _addMarker(currentLatLng, isPickup);
        if (isPickup) {
          _pickupMapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));
        } else {
          _destinationMapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));
        }
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

  void _selectPlace(Prediction prediction, bool isPickup) {
    if (prediction.lat != null && prediction.lng != null) {
      final lat = double.parse(prediction.lat!);
      final lng = double.parse(prediction.lng!);
      final newPosition = LatLng(lat, lng);
      if (_nagaCityBounds.contains(newPosition)) {
        _addMarker(newPosition, isPickup);
        if (isPickup) {
          _pickupMapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
          _pickupSearchController.text = prediction.description!;
        } else {
          _destinationMapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
          _destinationSearchController.text = prediction.description!;
        }
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

  Widget _buildMapSection(String title, String address, bool isPickup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
                  markers: isPickup ? _pickupMarkers : _destinationMarkers,
                  mapType: MapType.normal,
                  onMapCreated: (GoogleMapController controller) {
                    if (isPickup) {
                      _pickupMapController = controller;
                    } else {
                      _destinationMapController = controller;
                    }
                    controller.animateCamera(CameraUpdate.newLatLngBounds(_nagaCityBounds, 50.0));
                  },
                  onTap: (position) => _addMarker(position, isPickup),
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
                        onTap: () => _getCurrentLocation(isPickup),
                      ),
                      SizedBox(height: 8),
                      _buildMapIconButton(
                        icon: Icons.refresh,
                        onTap: () {
                          setState(() {
                            if (isPickup) {
                              _pickupMarkers.clear();
                              _pickupAddress = 'Tap on the map or search to select pickup location';
                            } else {
                              _destinationMarkers.clear();
                              _destinationAddress = 'Tap on the map or search to select destination location';
                            }
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
          address,
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
          'Transportation Request',
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
      style: TextStyle(color: AppColors.textColor),
      icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
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
              'Pickup and Destination Locations',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            SizedBox(height: 16),
            GooglePlaceAutoCompleteTextField(
              textEditingController: _pickupSearchController,
              googleAPIKey: "AIzaSyD4UAtE_r8JjBbd0o5qfv3ZSPX_8xkNJ7c",
              inputDecoration: InputDecoration(
                hintText: "Search for pickup location",
                border: OutlineInputBorder(),
              ),
              debounceTime: 800,
              countries: ["ph"],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (Prediction prediction) {
                _selectPlace(prediction, true);
              },
              itemClick: (Prediction prediction) {
                _selectPlace(prediction, true);
              },
            ),
            SizedBox(height: 16),
            _buildMapSection('Pickup Location', _pickupAddress, true),
            SizedBox(height: 24),
            GooglePlaceAutoCompleteTextField(
              textEditingController: _destinationSearchController,
              googleAPIKey: "AIzaSyD4UAtE_r8JjBbd0o5qfv3ZSPX_8xkNJ7c",
              inputDecoration: InputDecoration(
                hintText: "Search for destination location",
                border: OutlineInputBorder(),
              ),
              debounceTime: 800,
              countries: ["ph"],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (Prediction prediction) {
                _selectPlace(prediction, false);
              },
              itemClick: (Prediction prediction) {
                _selectPlace(prediction, false);
              },
            ),
            SizedBox(height: 16),
            _buildMapSection('Destination Location', _destinationAddress, false),
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
              'Note to Driver',
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
        onPressed: _submitTransportationRequest,
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

  void _submitTransportationRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_pickupMarkers.isEmpty || _destinationMarkers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select both pickup and destination locations on the map.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (_serviceType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select a service type.',
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
          'pickup_location': {
            'latitude': _pickupMarkers.first.position.latitude,
            'longitude': _pickupMarkers.first.position.longitude,
            'address': _pickupAddress,
          },
          'destination_location': {
            'latitude': _destinationMarkers.first.position.latitude,
            'longitude': _destinationMarkers.first.position.longitude,
            'address': _destinationAddress,
          },
          'note': _note.isNotEmpty ? _note : null,
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
          'user_type': _isExternalClient ? 'external' : 'official',
          'service_type': _serviceType,
        };

        String collectionName = _serviceType == 'burial' ? 'BURIAL_REQUESTS' : 'TRANSPORTATION_REQUESTS';
        await FirebaseFirestore.instance.collection(collectionName).add(requestData);

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

