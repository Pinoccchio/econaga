import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TruckMonitoringPage extends StatefulWidget {
  @override
  _TruckMonitoringPageState createState() => _TruckMonitoringPageState();
}

class _TruckMonitoringPageState extends State<TruckMonitoringPage> {
  final TextEditingController _searchController = TextEditingController();
  MapController _mapController = MapController();
  String? _selectedTruckId;
  bool _isMapReady = false;
  final PopupController _popupLayerController = PopupController();
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

  void _selectTruck(String truckId) {
    setState(() {
      _selectedTruckId = truckId;
    });
    _moveMapToTruck(truckId);
  }

  void _moveMapToTruck(String truckId) {
    FirebaseFirestore.instance
        .collection('USERS_ACCOUNTS')
        .doc(truckId)
        .get()
        .then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final location = _showRealtimeLocation ? data['realtime_location'] : data['collection_zone'];
        if (location != null) {
          final position = _showRealtimeLocation
              ? _parseRealtimeLocation(location)
              : _parseCollectionZone(location);
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

  void _toggleLocationView() {
    setState(() {
      _showRealtimeLocation = !_showRealtimeLocation;
    });
    if (_selectedTruckId != null) {
      _moveMapToTruck(_selectedTruckId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by name or truck number',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
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
              ],
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
                    'availability': data['truck_availability'] ?? 'Not set yet',
                    'phone': data['phone_number'] ?? '',
                    'email': data['email'] ?? '',
                    'realtime_location': data['realtime_location'] ?? {'latitude': 0.0, 'longitude': 0.0},
                    'collection_zone': data['collection_zone'] ?? {},
                    'status': data['status'] ?? 'inactive',
                    'selfieImageUrl': data['selfieImageUrl'],
                  };
                }).toList();

                collectors = collectors.where((collector) {
                  final query = _searchController.text.toLowerCase();
                  return collector['truck_number'].toString().toLowerCase().contains(query) ||
                      collector['name'].toLowerCase().contains(query);
                }).toList();

                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ListView.builder(
                        itemCount: collectors.length,
                        itemBuilder: (context, index) {
                          final collector = collectors[index];
                          return TruckCard(
                            collector: collector,
                            isSelected: collector['id'] == _selectedTruckId,
                            onTap: () => _selectTruck(collector['id']),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _buildMap(collectors),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<Map<String, dynamic>> collectors) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(13.6216, 123.1948), // Naga City coordinates
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
              markers: collectors.expand((collector) {
                LatLng realtimePosition = _parseRealtimeLocation(collector['realtime_location']);
                LatLng collectionZonePosition = _parseCollectionZone(collector['collection_zone']);
                return [
                  Marker(
                    point: realtimePosition,
                    width: 40.0,
                    height: 40.0,
                    child: Icon(
                      Icons.local_shipping,
                      color: _getAvailabilityColor(collector['availability']),
                      size: 40.0,
                    ),
                  ),
                  Marker(
                    point: collectionZonePosition,
                    width: 40.0,
                    height: 40.0,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40.0,
                    ),
                  ),
                ];
              }).toList(),
            ),
            PopupMarkerLayerWidget(
              options: PopupMarkerLayerOptions(
                popupController: _popupLayerController,
                markers: collectors.expand((collector) {
                  LatLng realtimePosition = _parseRealtimeLocation(collector['realtime_location']);
                  LatLng collectionZonePosition = _parseCollectionZone(collector['collection_zone']);
                  return [
                    Marker(
                      point: realtimePosition,
                      width: 40.0,
                      height: 40.0,
                      child: Icon(
                        Icons.local_shipping,
                        color: _getAvailabilityColor(collector['availability']),
                        size: 40.0,
                      ),
                    ),
                    Marker(
                      point: collectionZonePosition,
                      width: 40.0,
                      height: 40.0,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 40.0,
                      ),
                    ),
                  ];
                }).toList(),
                popupDisplayOptions: PopupDisplayOptions(
                  builder: (BuildContext context, Marker marker) {
                    final collector = collectors.firstWhere(
                          (c) => _parseRealtimeLocation(c['realtime_location']) == marker.point ||
                          _parseCollectionZone(c['collection_zone']) == marker.point,
                    );
                    final isRealtimeLocation = _parseRealtimeLocation(collector['realtime_location']) == marker.point;
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Truck #: ${collector['truck_number']}'),
                            Text('Driver: ${collector['name']}'),
                            Text('Status: ${collector['availability'] ?? 'Not Set Yet'}'),
                            Text(isRealtimeLocation ? 'Current Location' : 'Collection Zone'),
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
        if (_selectedTruckId != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _toggleLocationView,
              icon: Icon(_showRealtimeLocation ? Icons.map : Icons.location_on),
              label: Text(_showRealtimeLocation ? 'Show Zone' : 'Show Location'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
      ],
    );
  }

  Color _getAvailabilityColor(String availability) {
    switch (availability.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'in use':
        return Colors.orange;
      case 'under maintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class TruckCard extends StatelessWidget {
  final Map<String, dynamic> collector;
  final bool isSelected;
  final VoidCallback onTap;

  const TruckCard({
    Key? key,
    required this.collector,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  Widget _buildProfilePicture() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200],
      ),
      child: ClipOval(
        child: collector['selfieImageUrl'] != null && collector['selfieImageUrl'].isNotEmpty
            ? CachedNetworkImage(
          imageUrl: collector['selfieImageUrl'],
          fit: BoxFit.cover,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Center(
            child: Text(
              collector['name'].isNotEmpty ? collector['name'][0].toUpperCase() : 'U',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
            : Center(
          child: Text(
            collector['name'].isNotEmpty ? collector['name'][0].toUpperCase() : 'U',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getAvailabilityColor() {
    switch (collector['availability'].toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'in use':
        return Colors.orange;
      case 'under maintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getAvailabilityText() {
    return collector['availability'] ?? 'Not Set Yet';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.green.shade50 : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildProfilePicture(),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collector['name'].toLowerCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Truck #: ${collector['truck_number']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAvailabilityColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getAvailabilityText().toUpperCase(),
                  style: TextStyle(
                    color: _getAvailabilityColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(height: 12),
              _buildInfoRow(Icons.phone, collector['phone']),
              _buildInfoRow(Icons.email, collector['email']),
              _buildInfoRow(
                Icons.location_on,
                collector['realtime_location']['descriptive_location'] ?? 'Unknown location',
              ),
              _buildInfoRow(
                Icons.map,
                'Zone: ${(collector['collection_zone'] as Map<String, dynamic>)['descriptive_location'] ?? 'Unknown zone'}',
              ),
              _buildInfoRow(
                Icons.info_outline,
                'Status: ${collector['status']}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

