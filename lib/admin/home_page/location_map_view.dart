import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationMapView extends StatefulWidget {
  final String userId;

  LocationMapView({required this.userId});

  @override
  _LocationMapViewState createState() => _LocationMapViewState();
}

class _LocationMapViewState extends State<LocationMapView> {
  late Future<DocumentSnapshot> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = FirebaseFirestore.instance
        .collection('USERS_ACCOUNTS')
        .doc(widget.userId)
        .get();
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
        title: Text('Collection Zone Map'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('User data not found'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String collectionZoneString = userData['collection_zone'] as String? ?? '0,0';
          final LatLng collectionZone = _parseCollectionZone(collectionZoneString);

          return FlutterMap(
            options: MapOptions(
              initialCenter: collectionZone,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: collectionZone,
                    width: 80.0,
                    height: 80.0,
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40.0,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

