import 'dart:math';
import '../models/station.dart';

const vilniusLat = 54.6872;
const vilniusLng = 25.2797;

double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthKm = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return earthKm * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _toRad(double deg) => deg * pi / 180;

bool hasCoordinates(Station station) =>
    station.latitude != null && station.longitude != null;

Station? nearestStation(
  List<Station> stations,
  double latitude,
  double longitude,
) {
  Station? best;
  var bestDistance = double.infinity;
  for (final station in stations) {
    if (!hasCoordinates(station)) continue;
    final distance = distanceKm(
      latitude,
      longitude,
      station.latitude!,
      station.longitude!,
    );
    if (distance < bestDistance) {
      bestDistance = distance;
      best = station;
    }
  }
  return best;
}

List<Station> stationsNear(
  List<Station> stations,
  double latitude,
  double longitude, {
  int limit = 250,
}) {
  final ranked = stations.where(hasCoordinates).toList()
    ..sort((a, b) {
      final da = distanceKm(latitude, longitude, a.latitude!, a.longitude!);
      final db = distanceKm(latitude, longitude, b.latitude!, b.longitude!);
      return da.compareTo(db);
    });
  if (ranked.length <= limit) return ranked;
  return ranked.sublist(0, limit);
}
