import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

class LocationService {
  LocationService({Logger? logger}) : _logger = logger ?? Logger();
  final Logger _logger;

  /// Check and request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        _logger.i('Location permission denied, requesting...');
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse ||
            result == LocationPermission.always;
      } else if (permission == LocationPermission.deniedForever) {
        _logger.w('Location permission denied forever');
        return false;
      }

      return true;
    } on Object catch (e) {
      _logger.e('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      _logger.i('Getting current location...');

      // Check and request permission
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        _logger.w('Location permission not granted');
        return null;
      }

      // Get location
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );

      _logger.i(
        'Current location: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } on Object catch (e) {
      _logger.e('Error getting current location: $e');
      return null;
    }
  }

  /// Get location stream for real-time updates
  Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.best,
    Duration updateInterval = const Duration(seconds: 5),
  }) {
    _logger.i('Starting location stream...');
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: 10, // Update when moved 10 meters
      ),
    );
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } on Object catch (e) {
      _logger.e('Error checking location service: $e');
      return false;
    }
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    try {
      _logger.i('Opening location settings');
      await Geolocator.openLocationSettings();
    } on Object catch (e) {
      _logger.e('Error opening location settings: $e');
    }
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    try {
      _logger.i('Opening app settings');
      await Geolocator.openAppSettings();
    } on Object catch (e) {
      _logger.e('Error opening app settings: $e');
    }
  }
}
