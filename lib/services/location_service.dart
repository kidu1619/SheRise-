import 'package:geolocator/geolocator.dart';

/// Reads the device location ONLY when the person taps "Use my approximate
/// location". The result is rounded to 2 decimals (about 1 km) so it shows
/// the area, never an exact spot.
class LocationService {
  static Future<({double? lat, double? lng, String? error})>
      approximate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return (
          lat: null,
          lng: null,
          error: 'Location is turned off on this device. You can type a city instead.'
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return (
          lat: null,
          lng: null,
          error: 'Location permission was not granted. You can type a city instead.'
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return (
          lat: null,
          lng: null,
          error: 'Location permission is blocked for this app. You can type a city instead.'
        );
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (lat: _round(p.latitude), lng: _round(p.longitude), error: null);
    } catch (_) {
      return (
        lat: null,
        lng: null,
        error: 'Could not get your location. You can type a city instead.'
      );
    }
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;
}
