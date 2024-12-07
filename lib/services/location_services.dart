import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

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

      Geolocator.getPositionStream(
        desiredAccuracy: LocationAccuracy.high,
        distanceFilter: 10,
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

  Future<String> _getDescriptiveLocation(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> locationParts = [
          place.street ?? '',
          place.subLocality ?? '',
          place.locality ?? '',
          place.subAdministrativeArea ?? '',
          place.administrativeArea ?? '',
          place.country ?? '',
        ].where((part) => part.isNotEmpty).toList();

        return locationParts.join(', ');
      }
    } catch (e) {
      print('Error getting descriptive location: $e');
    }
    return 'Unknown Location';
  }

  Future<void> _updateLocation(Position position) async {
    if (!_isTracking || _userId == null) return;

    try {
      String descriptiveLocation = await _getDescriptiveLocation(position);
      await _firestore.collection('USERS_ACCOUNTS').doc(_userId).update({
        'realtime_location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'descriptive_location': descriptiveLocation,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });

      print('Location sent: $descriptiveLocation');
      print('Coordinates: Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    } catch (e) {
      print('Error updating location: $e');
    }
  }
}
