import 'package:geolocator/geolocator.dart';

class DevicePosition {
  final double latitude;
  final double longitude;
  DevicePosition({required this.latitude, required this.longitude});
}

class LocationService {
  Future<DevicePosition> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw StateError('Location services are turned off');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission was not granted');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
    return DevicePosition(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
