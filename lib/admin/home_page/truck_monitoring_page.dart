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
  final TextEditingController _searchController = TextEditingController();
  MapController _mapController = MapController();
  bool _isMapVisible = false;
  String? _selectedTruckId;
  bool _isMapReady = false;
  bool _isCollectionZoneMapVisible = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _toggleMapVisibility([String? truckId]) {
    setState(() {
      _isMapVisible = !_isMapVisible;
      _isCollectionZoneMapVisible = false;
      _selectedTruckId = _isMapVisible ? (truckId ?? _selectedTruckId) : null;
    });

    if (_isMapVisible && truckId != null) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (_isMapReady) {
          _moveMapToTruck(truckId);
        }
      });
    }
  }

  void _toggleCollectionZoneMap([String? truckId]) {
    setState(() {
      _isCollectionZoneMapVisible = !_isCollectionZoneMapVisible;
      _isMapVisible = false;
      _selectedTruckId = _isCollectionZoneMapVisible ? (truckId ?? _selectedTruckId) : null;
    });

    if (_isCollectionZoneMapVisible && truckId != null) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (_isMapReady) {
          _moveMapToCollectionZone(truckId);
        }
      });
    }
  }

  void _moveMapToTruck(String truckId) {
    FirebaseFirestore.instance
        .collection('USERS_ACCOUNTS')
        .doc(truckId)
        .get()
        .then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final realtimeLocation = data['realtime_location'];
        if (realtimeLocation != null) {
          final position = _parseRealtimeLocation(realtimeLocation);
          _mapController.move(position, 14.0);
        }
      }
    });
  }

  void _moveMapToCollectionZone(String truckId) {
    FirebaseFirestore.instance
        .collection('USERS_ACCOUNTS')
        .doc(truckId)
        .get()
        .then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final collectionZone = data['collection_zone'];
        if (collectionZone != null) {
          final position = _parseCollectionZone(collectionZone);
          _mapController.move(position, 14.0);
        }
      }
    });
  }

  LatLng _parseRealtimeLocation(Map<String, dynamic>? location) {
    double latitude = location?['latitude'] ?? 0.0;
    double longitude = location?['longitude'] ?? 0.0;
    return LatLng(latitude, longitude);
  }

  LatLng _parseCollectionZone(Map<String, dynamic>? collectionZone) {
    if (collectionZone == null) return LatLng(0, 0);
    final coordinates = collectionZone['coordinates'] as GeoPoint?;
    if (coordinates == null) return LatLng(0, 0);
    return LatLng(coordinates.latitude, coordinates.longitude);
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
              onChanged: (value) => setState(() {}),
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

                List<Map<String, dynamic>> collectors = snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    'name': '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}',
                    'truck_number': data['truck_number'] ?? '',
                    'availability': data['truck_availability'] ?? 'For Repair',
                    'realtime_location': data['realtime_location'] ?? {'latitude': 0.0, 'longitude': 0.0},
                    'collection_zone': data['collection_zone'] ?? {},
                  };
                }).toList();

                collectors = collectors.where((collector) {
                  final query = _searchController.text.toLowerCase();
                  return collector['truck_number'].toLowerCase().contains(query) ||
                      collector['name'].toLowerCase().contains(query);
                }).toList();

                return _isMapVisible
                    ? _buildMap(collectors)
                    : _isCollectionZoneMapVisible
                    ? _buildCollectionZoneMap(collectors)
                    : _buildTruckList(collectors);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<Map<String, dynamic>> collectors) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: collectors.isNotEmpty
            ? _parseRealtimeLocation(collectors[0]['realtime_location'])
            : LatLng(0, 0),
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
          markers: collectors.map((collector) {
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
                ? collectors
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
                final collector = collectors.firstWhere(
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

  Widget _buildCollectionZoneMap(List<Map<String, dynamic>> collectors) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: collectors.isNotEmpty
            ? _parseCollectionZone(collectors[0]['collection_zone'])
            : LatLng(0, 0),
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
          markers: collectors.map((collector) {
            LatLng position = _parseCollectionZone(collector['collection_zone']);
            return Marker(
              point: position,
              width: 40.0,
              height: 40.0,
              child: Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 40.0,
              ),
            );
          }).toList(),
        ),
        PopupMarkerLayerWidget(
          options: PopupMarkerLayerOptions(
            markers: _selectedTruckId != null
                ? collectors
                .where((collector) => collector['id'] == _selectedTruckId)
                .map((collector) {
              LatLng position = _parseCollectionZone(collector['collection_zone']);
              return Marker(
                point: position,
                width: 40.0,
                height: 40.0,
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40.0,
                ),
              );
            }).toList()
                : [],
            popupDisplayOptions: PopupDisplayOptions(
              builder: (BuildContext context, Marker marker) {
                final collector = collectors.firstWhere(
                      (c) => _parseCollectionZone(c['collection_zone']) == marker.point,
                );
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(collector['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(collector['truck_number']),
                        Text('Collection Zone'),
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

  Widget _buildTruckList(List<Map<String, dynamic>> collectors) {
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
              Expanded(flex: 3, child: Center(child: Text('Collection Zone', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(flex: 4, child: Center(child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: collectors.length,
            itemBuilder: (context, index) {
              final collector = collectors[index];
              return TruckListItem(
                id: collector['id'],
                name: collector['name'],
                truckNumber: collector['truck_number'],
                availability: collector['availability'],
                location: collector['realtime_location']['descriptive_location'] ?? 'Unknown',
                collectionZone: (collector['collection_zone'] as Map<String, dynamic>)['descriptive_location'] ?? 'Unknown',
                onMapToggle: _toggleMapVisibility,
                onCollectionZoneMapToggle: _toggleCollectionZoneMap,
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
  final String collectionZone;
  final Function(String?) onMapToggle;
  final Function(String?) onCollectionZoneMapToggle;

  const TruckListItem({
    Key? key,
    required this.id,
    required this.name,
    required this.truckNumber,
    required this.availability,
    required this.location,
    required this.collectionZone,
    required this.onMapToggle,
    required this.onCollectionZoneMapToggle,
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
              flex: 3,
              child: Text(
                collectionZone,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
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
                  ElevatedButton(
                    onPressed: () => onCollectionZoneMapToggle(id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('View Zone'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

