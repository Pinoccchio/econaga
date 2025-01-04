import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DrivingMonitoringPage extends StatefulWidget {
  const DrivingMonitoringPage({Key? key}) : super(key: key);

  @override
  _DrivingMonitoringPageState createState() => _DrivingMonitoringPageState();
}

class _DrivingMonitoringPageState extends State<DrivingMonitoringPage> {
  List<DocumentSnapshot<Map<String, dynamic>>> filteredCollectors = [];
  TextEditingController _searchController = TextEditingController();
  MapController mapController = MapController();
  final PopupController _popupLayerController = PopupController();
  String? _selectedTruckId;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _fetchCollectors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchCollectors() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('USERS_ACCOUNTS')
        .where('role', isEqualTo: 'collector')
        .get();

    setState(() {
      filteredCollectors = snapshot.docs;
    });
  }

  void _filterCollectors(String query) {
    setState(() {
      filteredCollectors = filteredCollectors.where((doc) {
        final data = doc.data();
        if (data == null) return false;
        final firstName = data['first_name'] as String? ?? '';
        final lastName = data['last_name'] as String? ?? '';
        final fullName = '$firstName $lastName'.toLowerCase();
        final truckNumber = data['truck_number']?.toString() ?? '';
        return fullName.contains(query.toLowerCase()) ||
            truckNumber.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildCollectorList(),
                ),
                Expanded(
                  flex: 3,
                  child: _buildMap(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.green[50],
      child: TextField(
        controller: _searchController,
        onChanged: _filterCollectors,
        decoration: InputDecoration(
          hintText: 'Search by name or truck number',
          prefixIcon: Icon(Icons.search, color: Colors.green),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.green),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCollectorList() {
    return ListView.builder(
      itemCount: filteredCollectors.length,
      itemBuilder: (context, index) {
        final data = filteredCollectors[index].data()!;
        return CollectorCard(
          collector: data,
          onTap: () {
            setState(() {
              _selectedTruckId = filteredCollectors[index].id;
            });
            _focusOnCollector(data);
          },
        );
      },
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: filteredCollectors.isNotEmpty && _selectedTruckId != null
            ? _parseRealtimeLocation(filteredCollectors.firstWhere((doc) => doc.id == _selectedTruckId).data()!['realtime_location'])
            : LatLng(13.6216, 123.1948), // Coordinates for Naga, Philippines
        initialZoom: 14.0,
        onMapReady: () {
          setState(() {
            _isMapReady = true;
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: filteredCollectors.map((doc) {
            final data = doc.data()!;
            LatLng position = _parseRealtimeLocation(data['realtime_location']);
            return Marker(
              point: position,
              width: 40.0,
              height: 40.0,
              child: Icon(
                Icons.local_shipping,
                color: data['truck_availability'] == 'Available' ? Colors.green : Colors.red,
                size: 40.0,
              ),
            );
          }).toList(),
        ),
        PopupMarkerLayerWidget(
          options: PopupMarkerLayerOptions(
            popupController: _popupLayerController,
            markers: _selectedTruckId != null
                ? filteredCollectors
                .where((doc) => doc.id == _selectedTruckId)
                .map((doc) {
              final data = doc.data()!;
              LatLng position = _parseRealtimeLocation(data['realtime_location']);
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
                final collectorDoc = filteredCollectors.firstWhere(
                      (doc) => _parseRealtimeLocation(doc.data()!['realtime_location']) == marker.point,
                  orElse: () => filteredCollectors.first,
                );
                final collector = collectorDoc.data()!;
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${collector['first_name']} ${collector['last_name']}'),
                        Text('Truck #: ${collector['truck_number']}'),
                        Text('Status: ${collector['status']}'),
                        Text('Availability: ${collector['truck_availability']}'),
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

  LatLng _parseRealtimeLocation(Map<String, dynamic>? location) {
    if (location != null && location['latitude'] != null && location['longitude'] != null) {
      return LatLng(location['latitude'] as double, location['longitude'] as double);
    }
    return LatLng(0, 0); // Default location if parsing fails
  }

  void _focusOnCollector(Map<String, dynamic> collectorData) {
    final location = collectorData['realtime_location'] as Map<String, dynamic>?;
    if (location != null && location['latitude'] != null && location['longitude'] != null) {
      mapController.move(LatLng(location['latitude'], location['longitude']), 15);
    }
  }
}

class CollectorCard extends StatelessWidget {
  final Map<String, dynamic> collector;
  final VoidCallback onTap;

  const CollectorCard({Key? key, required this.collector, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: CachedNetworkImageProvider(collector['selfieImageUrl'] ?? ''),
                    child: collector['selfieImageUrl'] == null ? Icon(Icons.person) : null,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${collector['first_name']} ${collector['last_name']}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text('Truck #: ${collector['truck_number']}'),
                        _buildAvailabilityBadge(collector['truck_availability']),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildInfoRow(Icons.phone, collector['phone_number']),
              _buildInfoRow(Icons.email, collector['email']),
              _buildInfoRow(Icons.location_on, collector['realtime_location']?['descriptive_location'] ?? 'N/A'),
              _buildInfoRow(Icons.work, 'Zone: ${collector['collection_zone']?['descriptive_location'] ?? 'N/A'}'),
              _buildInfoRow(Icons.info_outline, 'Status: ${collector['status']}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityBadge(String? availability) {
    Color color;
    switch (availability?.toLowerCase()) {
      case 'used':
        color = Colors.red;
        break;
      case 'available':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        availability?.toUpperCase() ?? 'N/A',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

