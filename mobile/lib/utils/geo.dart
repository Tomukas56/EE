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

/// Show € on pins only at street zoom; farther out = colour only.
const pricePinMinZoom = 16.0;

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

/// Fold LT/LV/EE/PL letters so "Raciu" matches "Račių" and "c" matches "č".
String foldSearchText(String input) {
  final lower = input.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    out.write(_foldSearchRune(rune));
  }
  return out.toString();
}

String _foldSearchRune(int rune) {
  switch (rune) {
    case 0x0105: // ą
    case 0x0101: // ā
    case 0x00E4: // ä
      return 'a';
    case 0x010D: // č
    case 0x0107: // ć
      return 'c';
    case 0x0119: // ę
    case 0x0117: // ė
    case 0x0113: // ē
      return 'e';
    case 0x0123: // ģ
      return 'g';
    case 0x012F: // į
    case 0x012B: // ī
      return 'i';
    case 0x0137: // ķ
      return 'k';
    case 0x013C: // ļ
    case 0x0142: // ł
      return 'l';
    case 0x0146: // ņ
    case 0x0144: // ń
      return 'n';
    case 0x00F6: // ö
    case 0x00F5: // õ
    case 0x00F3: // ó
      return 'o';
    case 0x0161: // š
    case 0x015B: // ś
      return 's';
    case 0x0173: // ų
    case 0x016B: // ū
    case 0x00FC: // ü
      return 'u';
    case 0x017E: // ž
    case 0x017A: // ź
    case 0x017C: // ż
      return 'z';
    default:
      return String.fromCharCode(rune);
  }
}

bool stationMatchesQuery(Station station, String query) {
  final q = foldSearchText(query.trim());
  if (q.isEmpty) return false;
  final hay = foldSearchText(
    [
      station.name,
      station.address,
      station.operatorName ?? '',
      station.countryCode ?? '',
    ].join(' '),
  );
  if (hay.contains(q)) return true;
  if (q.length >= 4) {
    final stem = q.substring(0, q.length - 1);
    if (hay.contains(stem)) return true;
  }
  return hay.split(RegExp(r'[^a-z0-9]+')).any((word) => word.startsWith(q));
}

List<Station> stationsMatchingQuery(
  List<Station> stations,
  String query, {
  int limit = 20,
}) {
  final q = foldSearchText(query.trim());
  if (q.length < 2) return const [];
  final hits = stations.where(hasCoordinates).where((station) {
    return stationMatchesQuery(station, query);
  }).toList();
  int score(Station station) {
    final name = foldSearchText(station.name);
    final address = foldSearchText(station.address);
    if (name.startsWith(q) || address.startsWith(q)) return 0;
    if (name.contains(q)) return 1;
    if (address.contains(q)) return 2;
    return 3;
  }

  hits.sort((a, b) => score(a).compareTo(score(b)));
  if (hits.length <= limit) return hits;
  return hits.sublist(0, limit);
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
