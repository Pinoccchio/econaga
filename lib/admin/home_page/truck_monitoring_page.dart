import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

class TruckMonitoringPage extends StatefulWidget {
  @override
  _TruckMonitoringPageState createState() => _TruckMonitoringPageState();
}

class _TruckMonitoringPageState extends State<TruckMonitoringPage> {
  List<Map<String, dynamic>> filteredCollectors = [];
  List<Map<String, dynamic>> allCollectors = [];
  final TextEditingController _searchController = TextEditingController();
  MapController _mapController = MapController(); //Initialized in initState now
  bool _isMapVisible = false;
  String? _selectedTruckId;
  bool _isMapReady = false; // Added _isMapReady variable

  @override
  void initState() {
    super.initState();
    _mapController = MapController(); // Initialize MapController in initState
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose(); // Dispose of MapController
    super.dispose();
  }

  void _filterCollectors(String query) {
    setState(() {
      filteredCollectors = allCollectors.where((collector) {
        return collector['truck_number'].toLowerCase().contains(query.toLowerCase()) ||
            collector['name'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _toggleMapVisibility([String? truckId]) {
    setState(() {
      _isMapVisible = !_isMapVisible;
      _selectedTruckId = _isMapVisible ? (truckId ?? _selectedTruckId) : null;
    });

    if (_isMapVisible && truckId != null) {
      final selectedCollector = filteredCollectors.firstWhere((collector) => collector['id'] == truckId);
      final LatLng position = _parseRealtimeLocation(selectedCollector['realtime_location']);

      // Use Future.delayed to ensure the map is ready before moving
      Future.delayed(Duration(milliseconds: 100), () {
        if (_isMapReady) {
          _mapController.move(position, 14.0);
        }
      });
    }
  }

  LatLng _getCenterPosition() {
    if (filteredCollectors.isNotEmpty) {
      Map<String, dynamic>? realtimeLocation = filteredCollectors[0]['realtime_location'];
      if (realtimeLocation != null) {
        try {
          double latitude = realtimeLocation['latitude'];
          double longitude = realtimeLocation['longitude'];
          return LatLng(latitude, longitude);
        } catch (e) {
          debugPrint("Error parsing coordinates: $e");
        }
      }
    }
    return LatLng(0, 0); // Default center if no valid coordinates
  }

  LatLng _parseRealtimeLocation(Map<String, dynamic> realtimeLocation) {
    double latitude = realtimeLocation['latitude'] ?? 0.0;
    double longitude = realtimeLocation['longitude'] ?? 0.0;
    return LatLng(latitude, longitude);
  }

  String _getDescriptiveLocation(Map<String, dynamic> realtimeLocation) {
    double latitude = realtimeLocation['latitude'] ?? 0.0;
    double longitude = realtimeLocation['longitude'] ?? 0.0;
    // This is a placeholder. In a real application, you would use a geocoding service to get the actual location name.
    return 'Lat: ${latitude.toStringAsFixed(2)}, Long: ${longitude.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Truck Monitoring', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.map, color: Colors.black),
            onPressed: _toggleMapVisibility,
            tooltip: 'Toggle Map',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCollectors,
              decoration: InputDecoration(
                hintText: 'Search by truck number or collector name',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.grey.shade200,
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('USERS_ACCOUNTS')
                  .where('role', isEqualTo: 'collector')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (allCollectors.isEmpty) {
                  allCollectors = snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      'name': '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}',
                      'truck_number': data['truck_number'] ?? '',
                      'availability': data['truck_availability'] ?? 'For Repair',
                      'realtime_location': data['realtime_location'] ?? {'latitude': 0.0, 'longitude': 0.0},
                    };
                  }).toList();
                  filteredCollectors = List.from(allCollectors);
                }

                return _isMapVisible
                    ? _buildMap()
                    : _buildTruckList();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _getCenterPosition(),
        initialZoom: 14.0,
        onMapReady: () {
          setState(() {
            _isMapReady = true;
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: filteredCollectors.map((collector) {
            LatLng position = _parseRealtimeLocation(collector['realtime_location']);
            return Marker(
              point: position,
              width: 40.0,
              height: 40.0,
              child: Icon(
                Icons.local_shipping,
                color: collector['availability'] == 'Available' ? Colors.green : Colors.red,
                size: 40.0,
              ),
            );
          }).toList(),
        ),
        PopupMarkerLayerWidget(
          options: PopupMarkerLayerOptions(
            markers: _selectedTruckId != null
                ? filteredCollectors
                .where((collector) => collector['id'] == _selectedTruckId)
                .map((collector) {
              LatLng position = _parseRealtimeLocation(collector['realtime_location']);
              return Marker(
                point: position,
                width: 40.0,
                height: 40.0,
                child: Icon(
                  Icons.local_shipping,
                  color: Colors.blue,
                  size: 40.0,
                ),
              );
            }).toList()
                : [],
            popupDisplayOptions: PopupDisplayOptions(
              builder: (BuildContext context, Marker marker) {
                final collector = filteredCollectors.firstWhere(
                      (c) => _parseRealtimeLocation(c['realtime_location']) == marker.point,
                );
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(collector['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(collector['truck_number']),
                        Text(collector['availability']),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTruckList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(flex: 3, child: Center(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(flex: 2, child: Center(child: Text('Truck Number', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(flex: 2, child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(flex: 3, child: Center(child: Text('Location', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(flex: 2, child: Center(child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredCollectors.length,
            itemBuilder: (context, index) {
              final collector = filteredCollectors[index];
              return TruckListItem(
                id: collector['id'],
                name: collector['name'],
                truckNumber: collector['truck_number'],
                availability: collector['availability'],
                location: _getDescriptiveLocation(collector['realtime_location']),
                onMapToggle: _toggleMapVisibility,
              );
            },
          ),
        ),
      ],
    );
  }
}

class TruckListItem extends StatelessWidget {
  final String id;
  final String name;
  final String truckNumber;
  final String availability;
  final String location;
  final Function(String?) onMapToggle;

  const TruckListItem({
    Key? key,
    required this.id,
    required this.name,
    required this.truckNumber,
    required this.availability,
    required this.location,
    required this.onMapToggle,
  }) : super(key: key);

  Color get availabilityColor {
    switch (availability) {
      case 'Available':
        return Colors.green;
      case 'Used':
        return Colors.red;
      case 'For Repair':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                truckNumber,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                availability,
                style: TextStyle(
                  color: availabilityColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                location,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => onMapToggle(id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('View Map'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


