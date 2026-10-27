import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult({
    required this.success,
    this.locationString,
    this.latitude,
    this.longitude,
    this.errorMessage,
  });

  final bool success;
  final String? locationString;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Requests permission and retrieves the device GPS position.
  Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          success: false,
          errorMessage: 'Location services are disabled on this device.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            success: false,
            errorMessage: 'Location permission was denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          success: false,
          errorMessage:
              'Location permissions are permanently denied. Please enable in device settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final lat = position.latitude;
      final lon = position.longitude;
      final friendlyName = _formatCoordinates(lat, lon);

      return LocationResult(
        success: true,
        latitude: lat,
        longitude: lon,
        locationString: friendlyName,
      );
    } catch (e) {
      debugPrint('LocationService error: $e');
      return LocationResult(
        success: false,
        errorMessage: 'Could not acquire location: $e',
      );
    }
  }

  static String _formatCoordinates(double lat, double lon) {
    String area = 'GPS Location';
    if (lat >= 8.5 && lat <= 9.5 && lon >= 38.4 && lon <= 39.0) {
      area = 'Addis Ababa Area';
    } else if (lat >= 8.3 && lat <= 8.8 && lon >= 39.1 && lon <= 39.5) {
      area = 'Adama Area';
    } else if (lat >= 11.4 && lat <= 11.8 && lon >= 37.2 && lon <= 37.6) {
      area = 'Bahir Dar Area';
    } else if (lat >= 6.8 && lat <= 7.3 && lon >= 38.3 && lon <= 38.7) {
      area = 'Hawassa Area';
    }

    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'W';
    return '$area (${lat.abs().toStringAsFixed(3)}° $latDir, ${lon.abs().toStringAsFixed(3)}° $lonDir)';
  }
}
