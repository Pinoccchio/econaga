import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DrivingMonitoringPage extends StatefulWidget {
  @override
  _DrivingMonitoringPageState createState() => _DrivingMonitoringPageState();
}

class _DrivingMonitoringPageState extends State<DrivingMonitoringPage> {
  final TextEditingController _searchController = TextEditingController();
  MapController _mapController = MapController();
  bool _isMapVisible = false;
  String? _selectedDriverId;
  bool _isMapReady = false;
  bool _showRealtimeLocation = true;

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by driver name',
                prefixIcon: Icon(Icons.search, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.green.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.green.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.green),
                ),
                fillColor: Colors.green.shade50,
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

                List<Map<String, dynamic>> drivers = snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    'name': '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}',
                    'truck_number': data['truck_number'] ?? '',
                    'availability': data['availability'] ?? 'Not Set Yet',
                    'realtime_location': data['realtime_location'] ?? {'latitude': 0.0, 'longitude': 0.0},
                    'collection_zone': data['collection_zone'] ?? {},
                    'selfieImageUrl': data['selfieImageUrl'] ?? '',
                    'phone_number': data['phone_number'] ?? '',
                    'email': data['email'] ?? '',
                    'status': data['status'] ?? 'inactive',
                    'duty_time': data['duty_time'] ?? {},
                  };
                }).toList();

                drivers = drivers.where((driver) {
                  final query = _searchController.text.toLowerCase();
                  return driver['name'].toLowerCase().contains(query);
                }).toList();

                return _isMapVisible
                    ? _buildMap(drivers)
                    : _buildDriverList(drivers);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<Map<String, dynamic>> drivers) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: drivers.isNotEmpty
                ? _parseRealtimeLocation(drivers[0]['realtime_location'])
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
              markers: drivers.map((driver) {
                LatLng position = _showRealtimeLocation
                    ? _parseRealtimeLocation(driver['realtime_location'])
                    : _parseCollectionZone(driver['collection_zone']);
                return Marker(
                  point: position,
                  width: 40.0,
                  height: 40.0,
                  child: _buildDriverMarker(driver),
                );
              }).toList(),
            ),
            PopupMarkerLayerWidget(
              options: PopupMarkerLayerOptions(
                markers: drivers.map((driver) {
                  LatLng position = _showRealtimeLocation
                      ? _parseRealtimeLocation(driver['realtime_location'])
                      : _parseCollectionZone(driver['collection_zone']);
                  return Marker(
                    point: position,
                    width: 40.0,
                    height: 40.0,
                    child: _buildDriverMarker(driver),
                  );
                }).toList(),
                popupDisplayOptions: PopupDisplayOptions(
                  builder: (BuildContext context, Marker marker) {
                    final driver = drivers.firstWhere(
                          (d) => _parseRealtimeLocation(d['realtime_location']) == marker.point ||
                          _parseCollectionZone(d['collection_zone']) == marker.point,
                    );
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(driver['selfieImageUrl']),
                              radius: 30,
                            ),
                            SizedBox(height: 8),
                            Text(driver['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Truck #: ${driver['truck_number']}'),
                            Text(driver['availability']),
                            Text(_showRealtimeLocation ? 'Current Location' : 'Collection Zone'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverMarker(Map<String, dynamic> driver) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(driver['selfieImageUrl']),
        backgroundColor: _getAvailabilityColor(driver['availability']),
      ),
    );
  }

  Widget _buildDriverList(List<Map<String, dynamic>> drivers) {
    return ListView.builder(
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driver = drivers[index];
        return DriverListItem(
          name: driver['name'],
          truckNumber: driver['truck_number'],
          availability: driver['availability'],
          location: driver['realtime_location']['descriptive_location'] ?? 'Unknown',
          collectionZone: (driver['collection_zone'] as Map<String, dynamic>)['descriptive_location'] ?? 'Unknown',
          selfieImageUrl: driver['selfieImageUrl'],
          phoneNumber: driver['phone_number'],
          email: driver['email'],
          status: driver['status'],
          dutyTimeStart: driver['duty_time']?['start'],
          dutyTimeEnd: driver['duty_time']?['end'],
        );
      },
    );
  }

  Color _getAvailabilityColor(String availability) {
    switch (availability.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'on duty':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class DriverListItem extends StatelessWidget {
  final String name;
  final String truckNumber;
  final String availability;
  final String location;
  final String collectionZone;
  final String selfieImageUrl;
  final String phoneNumber;
  final String email;
  final String status;
  final String? dutyTimeStart;
  final String? dutyTimeEnd;

  const DriverListItem({
    Key? key,
    required this.name,
    required this.truckNumber,
    required this.availability,
    required this.location,
    required this.collectionZone,
    required this.selfieImageUrl,
    required this.phoneNumber,
    required this.email,
    required this.status,
    this.dutyTimeStart,
    this.dutyTimeEnd,
  }) : super(key: key);

  Color _getAvailabilityColor(String availability) {
    switch (availability.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'on duty':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(selfieImageUrl),
                  radius: 25,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toLowerCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Truck #: $truckNumber',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getAvailabilityColor(availability).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                availability.toUpperCase(),
                style: TextStyle(
                  color: _getAvailabilityColor(availability),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  phoneNumber,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.map, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Collection Zone: $collectionZone',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Duty Time: ${dutyTimeStart != null && dutyTimeEnd != null ? "$dutyTimeStart - $dutyTimeEnd" : "Not set"}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Status: $status',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



