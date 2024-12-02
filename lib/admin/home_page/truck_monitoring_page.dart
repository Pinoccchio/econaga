import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

class TruckMonitoringPage extends StatefulWidget {
  @override
  _TruckMonitoringPageState createState() => _TruckMonitoringPageState();
}

class _TruckMonitoringPageState extends State<TruckMonitoringPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> filteredCollectors = [];
  TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  bool _isMapVisible = false;
  String? _selectedTruckId;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterCollectors(String query) {
    setState(() {
      filteredCollectors = filteredCollectors.where((collector) {
        return collector['truck_number']
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
    });
  }

  void _toggleMapVisibility([String? truckId]) {
    setState(() {
      _isMapVisible = !_isMapVisible;
      _selectedTruckId = _isMapVisible ? (truckId ?? _selectedTruckId) : null;
    });
    if (_isMapVisible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          onChanged: _filterCollectors,
          decoration: InputDecoration(
            hintText: 'Search by truck number',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.grey.shade200,
            filled: true,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.view_list,
              progress: _animation,
              color: Colors.green,
            ),
            onPressed: _toggleMapVisibility,
            tooltip: 'Toggle Map',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('USERS_ACCOUNTS')
            .where('role', isEqualTo: 'collector')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          filteredCollectors = snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'truck_number': data['truck_number'] ?? '',
              'availability': data['truck_availability'] ?? 'For Repair',
              'collection_zone': data['collection_zone'] ?? '0,0',
            };
          }).toList();

          if (_searchController.text.isNotEmpty) {
            filteredCollectors = filteredCollectors.where((collector) {
              return collector['truck_number']
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase());
            }).toList();
          }

          return Stack(
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * _animation.value,
                    child: child!,
                  );
                },
                child: FlutterMap(
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
                        markers: filteredCollectors.where((collector) =>
                        _selectedTruckId == null || collector['id'] == _selectedTruckId
                        ).map((collector) {
                          LatLng position = _parseCollectionZone(collector['collection_zone'] as String);
                          return Marker(
                            point: position,
                            width: 40.0,
                            height: 40.0,
                            child: Icon(
                              Icons.local_shipping,
                              color: collector['availability'] == 'Available'
                                  ? Colors.green
                                  : Colors.red,
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
                                    Text(collector['truck_number'], style: TextStyle(fontWeight: FontWeight.bold)),
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
                ),
              ),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Positioned(
                    top: MediaQuery.of(context).size.height * _animation.value,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: child!,
                  );
                },
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text('Truck Number',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text('Availability',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text('Collection Zone',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: ListView.separated(
                            itemCount: filteredCollectors.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final collector = filteredCollectors[index];
                              return TruckCard(
                                id: collector['id'],
                                truckNumber: collector['truck_number'],
                                availability: collector['availability'],
                                collectionZone: collector['collection_zone'] as String,
                                onMapToggle: _toggleMapVisibility,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TruckCard extends StatelessWidget {
  final String id;
  final String truckNumber;
  final String availability;
  final String collectionZone;
  final Function(String?) onMapToggle;

  TruckCard({
    required this.id,
    required this.truckNumber,
    required this.availability,
    required this.collectionZone,
    required this.onMapToggle,
  });

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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(truckNumber, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    color: availabilityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    availability.toUpperCase(),
                    style: TextStyle(color: availabilityColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: IconButton(
                  icon: Icon(Icons.map, color: Colors.green),
                  onPressed: () {
                    onMapToggle(id);
                  },
                  tooltip: 'View Collection Zone',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

