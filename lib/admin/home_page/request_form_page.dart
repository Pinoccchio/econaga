import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestFormPage extends StatefulWidget {
  final DateTime selectedDate;

  RequestFormPage({required this.selectedDate});

  @override
  _RequestFormPageState createState() => _RequestFormPageState();
}

class _RequestFormPageState extends State<RequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _serviceType;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _contactNumberController;
  late TextEditingController _noteController;
  late TextEditingController _addressController;
  late TextEditingController _pickupAddressController;
  late TextEditingController _destinationAddressController;
  TimeOfDay? _selectedTime;
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _contactNumberController = TextEditingController();
    _noteController = TextEditingController();
    _addressController = TextEditingController();
    _pickupAddressController = TextEditingController();
    _destinationAddressController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _noteController.dispose();
    _addressController.dispose();
    _pickupAddressController.dispose();
    _destinationAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Walk-in Request'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Request',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
                SizedBox(height: 8),
                Text(
                  'Date: ${DateFormat('MMMM d, yyyy').format(widget.selectedDate)}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                SizedBox(height: 32),
                _buildServiceTypeDropdown(),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildTextField('First Name', _firstNameController)),
                    SizedBox(width: 16),
                    Expanded(child: _buildTextField('Last Name', _lastNameController)),
                  ],
                ),
                SizedBox(height: 24),
                _buildTextField('Email', _emailController),
                SizedBox(height: 24),
                _buildTextField('Contact Number', _contactNumberController),
                SizedBox(height: 24),
                _buildTimePicker(),
                SizedBox(height: 24),
                _buildLocationSearch(),
                SizedBox(height: 24),
                _buildTextField('Note', _noteController, maxLines: 3),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitRequest,
                  child: Text('Submit Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Service Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      value: _serviceType,
      items: [
        DropdownMenuItem(value: 'garbage', child: Text('Garbage Collection')),
        DropdownMenuItem(value: 'burial', child: Text('Burial Service')),
        DropdownMenuItem(value: 'transportation', child: Text('Transportation')),
      ],
      onChanged: (value) {
        setState(() {
          _serviceType = value;
        });
      },
      validator: (value) => value == null ? 'Please select a service type' : null,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildTimePicker() {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(
        text: _selectedTime?.format(context) ?? '',
      ),
      decoration: InputDecoration(
        labelText: 'Time',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: Icon(Icons.access_time, color: Colors.green),
      ),
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime ?? TimeOfDay.now(),
        );
        if (picked != null && picked != _selectedTime) {
          setState(() {
            _selectedTime = picked;
          });
        }
      },
    );
  }

  Widget _buildLocationSearch() {
    if (_serviceType == 'garbage') {
      return _buildSingleLocationSearch('Address', _addressController);
    } else {
      return Column(
        children: [
          _buildSingleLocationSearch('Pickup Address', _pickupAddressController),
          SizedBox(height: 16),
          _buildSingleLocationSearch('Destination Address', _destinationAddressController),
        ],
      );
    }
  }

  Widget _buildSingleLocationSearch(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.green),
              onPressed: () {
                setState(() {
                  controller.clear();
                });
              },
            )
                : Icon(Icons.search, color: Colors.green),
          ),
          onChanged: (String value) {
            setState(() {});
          },
        ),
        if (controller.text.isNotEmpty)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getLocationSuggestions(controller.text),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(height: 0);
              }

              final suggestions = snapshot.data!;
              return Card(
                margin: EdgeInsets.only(top: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: suggestions.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    return ListTile(
                      title: Text(suggestion['description'] as String),
                      onTap: () {
                        setState(() {
                          controller.text = suggestion['description'] as String;
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _getLocationSuggestions(String input) async {
    if (input.isEmpty) {
      return [];
    }

    final String apiKey = 'AIzaSyA0W_IsJ-OexHkiQFWU-J3Z5PgkSSUzgTc';
    final String baseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    final String url = '$baseUrl?input=$input&key=$apiKey&components=country:ph';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(result['predictions']);
        }
        throw Exception(result['error_message']);
      } else {
        throw Exception('Failed to fetch suggestions');
      }
    } catch (e) {
      print('Error fetching location suggestions: $e');
      return [];
    }
  }

  void _submitRequest() async {
    if (_formKey.currentState!.validate() && _selectedTime != null) {
      try {
        String collectionName;
        Map<String, dynamic> requestData = {
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'email': _emailController.text,
          'contact_number': _contactNumberController.text,
          'note': _noteController.text,
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
          'requested_date_time': Timestamp.fromDate(DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          )),
          'user_type': 'walk_in',
        };

        switch (_serviceType) {
          case 'garbage':
            collectionName = 'GARBAGE_REQUESTS';
            requestData['location'] = {'address': _addressController.text};
            break;
          case 'burial':
          case 'transportation':
            collectionName = _serviceType == 'burial' ? 'BURIAL_REQUESTS' : 'TRANSPORTATION_REQUESTS';
            requestData['pickup_location'] = {'address': _pickupAddressController.text};
            requestData['destination_location'] = {'address': _destinationAddressController.text};
            break;
          default:
            throw Exception('Invalid service type');
        }

        // Check for existing requests
        QuerySnapshot existingRequests = await FirebaseFirestore.instance
            .collection(collectionName)
            .where('requested_date_time', isEqualTo: requestData['requested_date_time'])
            .where('status', whereIn: ['pending', 'approved'])
            .get();

        if (existingRequests.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This time slot is already booked. Please choose a different time.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await FirebaseFirestore.instance.collection(collectionName).add(requestData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request submitted successfully')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        print('Error submitting request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request. Please try again.')),
        );
      }
    }
  }
}

