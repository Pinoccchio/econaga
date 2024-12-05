import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isTracking = false;
  String? _userId;

  Future<void> startTracking(String userId) async {
    if (_isTracking) return;

    _userId = userId;
    _isTracking = true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Updated usage of getPositionStream with no LocationSettings required
      Geolocator.getPositionStream(
        desiredAccuracy: LocationAccuracy.high, // Set desired accuracy level
        distanceFilter: 10, // Update every 10 meters
      ).listen((Position position) {
        _updateLocation(position);
      });
    } catch (e) {
      _isTracking = false;
      print('Error starting location tracking: $e');
    }
  }

  void stopTracking() {
    _isTracking = false;
    _userId = null;
  }

  Future<void> _updateLocation(Position position) async {
    if (!_isTracking || _userId == null) return;

    try {
      await _firestore.collection('USERS_ACCOUNTS').doc(_userId).update({
          'realtime_location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });

      // Print the updated location
      print('Location sent: Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    } catch (e) {
      print('Error updating location: $e');
    }
  }
}
