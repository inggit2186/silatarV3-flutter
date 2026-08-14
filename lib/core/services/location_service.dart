import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final DateTime timestamp;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.timestamp,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);
}

class LocationService {
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;
  LocationService._();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await geo.Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permission
  Future<geo.LocationPermission> checkPermission() async {
    return await geo.Geolocator.checkPermission();
  }

  /// Request location permission
  Future<geo.LocationPermission> requestPermission() async {
    return await geo.Geolocator.requestPermission();
  }

  /// Get current position
  Future<LocationResult?> getCurrentPosition() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          return null;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        return null;
      }

      // Get position
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        timestamp: position.timestamp,
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between two points (in meters)
  double calculateDistance(LatLng from, LatLng to) {
    return geo.Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Check if user is within radius of office
  bool isWithinRadius(LatLng userLocation, LatLng officeLocation, double radiusInMeters) {
    double distance = calculateDistance(userLocation, officeLocation);
    return distance <= radiusInMeters;
  }

  /// Get distance text
  String getDistanceText(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }
}
