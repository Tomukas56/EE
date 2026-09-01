import 'dart:math';
import '../models/station.dart';

const vilniusLat = 54.6872;
const vilniusLng = 25.2797;

/// Camera covering Lithuania, Latvia, Estonia, and Poland (list / search only).
const regionLat = 54.4;
const regionLng = 21.5;
const regionZoom = 5.5;

/// Map opens on the device, not the whole country — keeps marker RAM low.
const nearbyRadiusKm = 0.3;
const nearbyZoom = 17.0;
const nearbyMinZoom = 14.0;
const nearbyMaxZoom = 19.0;
const nearbyMinRadiusKm = 0.1;
const nearbyMaxRadiusKm = 2.4;
const nearbyZoomStep = 1.0;

/// Viewing radius grows when zooming out (300 m at zoom 17).
double radiusKmForZoom(double zoom) {
  final km = nearbyRadiusKm * pow(2, nearbyZoom - zoom);
  return km.clamp(nearbyMinRadiusKm, nearbyMaxRadiusKm);
}

String formatRadiusKm(double km) {
  final meters = (km * 1000).round();
  if (meters < 1000) return '$meters m';
  final kmShown = meters / 1000;
  if (kmShown == kmShown.roundToDouble()) {
    return '${kmShown.toStringAsFixed(0)} km';
  }
  return '${kmShown.toStringAsFixed(1)} km';
}

const countryFilters = <({String code, String label})>[
  (code: 'ALL', label: 'All'),
  (code: 'LT', label: 'LT'),
  (code: 'LV', label: 'LV'),
  (code: 'EE', label: 'EE'),
  (code: 'PL', label: 'PL'),
];

({double lat, double lng, double zoom}) cameraForCountry(String code) {
  switch (code) {
    case 'LT':
      return (lat: 55.3, lng: 24.0, zoom: 7.0);
    case 'LV':
      return (lat: 56.88, lng: 24.6, zoom: 7.0);
    case 'EE':
      return (lat: 58.6, lng: 25.0, zoom: 7.0);
    case 'PL':
      return (lat: 52.1, lng: 19.4, zoom: 5.8);
    default:
      return (lat: regionLat, lng: regionLng, zoom: regionZoom);
  }
}

bool matchesCountryFilter(Station station, String countryCode) {
  if (countryCode == 'ALL') return true;
  return station.countryCode == countryCode;
}

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

List<Station> stationsWithin(
  List<Station> stations,
  double latitude,
  double longitude, {
  double radiusKm = nearbyRadiusKm,
}) {
  return stations
      .where(hasCoordinates)
      .where(
        (station) =>
            distanceKm(
              latitude,
              longitude,
              station.latitude!,
              station.longitude!,
            ) <=
            radiusKm,
      )
      .toList();
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
