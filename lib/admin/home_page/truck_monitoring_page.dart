import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
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
  final MapController _mapController = MapController();
  bool _isMapVisible = false;
  String? _selectedTruckId;

  @override
  void dispose() {
    _searchController.dispose();
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
  }

  LatLng _getCenterPosition() {
    if (filteredCollectors.isNotEmpty) {
      List<String> coordinates = (filteredCollectors[0]['collection_zone'] as String).split(',');
      double latitude = double.parse(coordinates[0]);
      double longitude = double.parse(coordinates[1]);
      return LatLng(latitude, longitude);
    }
    return LatLng(13.6218, 123.1945); // Default position if no trucks
  }

  LatLng _parseCollectionZone(String collectionZone) {
    List<String> coordinates = collectionZone.split(',');
    double latitude = double.parse(coordinates[0]);
    double longitude = double.parse(coordinates[1]);
    return LatLng(latitude, longitude);
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
                      'collection_zone': data['collection_zone'] ?? '0,0',
                    };
                  }).toList();
                  filteredCollectors = List.from(allCollectors); // Initially show all
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
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        PopupMarkerLayerWidget(
          options: PopupMarkerLayerOptions(
            markers: filteredCollectors
                .where((collector) =>
            _selectedTruckId == null || collector['id'] == _selectedTruckId)
                .map((collector) {
              LatLng position = _parseCollectionZone(collector['collection_zone'] as String);
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
            popupDisplayOptions: PopupDisplayOptions(
              builder: (BuildContext context, Marker marker) {
                final collector = filteredCollectors.firstWhere(
                      (c) => _parseCollectionZone(c['collection_zone'] as String) == marker.point,
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
              Expanded(flex: 4, child: Center(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(flex: 3, child: Center(child: Text('Truck Number', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(flex: 2, child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(flex: 3, child: Center(child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold)))),
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
  final Function(String?) onMapToggle;

  const TruckListItem({
    Key? key,
    required this.id,
    required this.name,
    required this.truckNumber,
    required this.availability,
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
              flex: 4,
              child: Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  truckNumber,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  availability,
                  style: TextStyle(
                    color: availabilityColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () => onMapToggle(id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,  // Background color of the button
                  foregroundColor: Colors.white,  // Text color of the button
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
