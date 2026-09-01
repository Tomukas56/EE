import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/station.dart';
import '../models/vehicle.dart';
import '../utils/geo.dart';

class PlannedRoute {
  final double distanceKm;
  final Duration duration;
  final Station? chargingStop;
  final double energyKwh;
  final double estimatedCostEur;
  final String summary;
  final bool usedGoogleDirections;

  PlannedRoute({
    required this.distanceKm,
    required this.duration,
    required this.chargingStop,
    required this.energyKwh,
    required this.estimatedCostEur,
    required this.summary,
    required this.usedGoogleDirections,
  });
}

class RouteService {
  static const _labEurPerKwh = 0.32;

  Future<PlannedRoute> plan({
    required String origin,
    required String destination,
    required List<Station> stations,
    Vehicle? vehicle,
  }) async {
    final start = origin.trim();
    final end = destination.trim();
    if (start.isEmpty || end.isEmpty) {
      throw Exception('Enter start and destination');
    }

    var usedGoogle = false;
    var distanceKm = 0.0;
    var duration = Duration.zero;
    var midLat = 0.0;
    var midLng = 0.0;

    final directions = await _googleDirections(start, end);
    if (directions != null) {
      usedGoogle = true;
      distanceKm = directions.distanceKm;
      duration = directions.duration;
      midLat = directions.midLat;
      midLng = directions.midLng;
    } else {
      final from = await _nominatim(start);
      final to = await _nominatim(end);
      if (from == null || to == null) {
        throw Exception('Could not find those places');
      }
      final straight = distanceKmBetween(from.lat, from.lng, to.lat, to.lng);
      distanceKm = straight * 1.3;
      duration = Duration(minutes: (distanceKm / 80 * 60).round().clamp(1, 24 * 60));
      midLat = (from.lat + to.lat) / 2;
      midLng = (from.lng + to.lng) / 2;
    }

    final rangeKm = vehicle?.maxRangeKm ?? 300;
    final usableKm = rangeKm * 0.8;
    Station? stop;
    if (distanceKm > usableKm) {
      final type = vehicle?.filterType;
      final candidates = stations.where((station) {
        if (!hasCoordinates(station)) return false;
        if (type == null || station.connectorTypes.isEmpty) return true;
        return station.connectorTypes.contains(type);
      }).toList();
      stop = nearestStation(candidates, midLat, midLng);
    }

    final energy = vehicle == null || vehicle.maxRangeKm <= 0
        ? distanceKm * 0.18
        : (distanceKm / vehicle.maxRangeKm) * vehicle.batteryCapacityKWh;
    final cost = energy * _labEurPerKwh;
    final summary = stop == null
        ? 'Within estimated range — no charging stop needed'
        : 'Suggested stop: ${stop.name}';

    return PlannedRoute(
      distanceKm: distanceKm,
      duration: duration,
      chargingStop: stop,
      energyKwh: energy,
      estimatedCostEur: cost,
      summary: summary,
      usedGoogleDirections: usedGoogle,
    );
  }

  Future<({double distanceKm, Duration duration, double midLat, double midLng})?>
      _googleDirections(String origin, String destination) async {
    final key = AppConfig.googleMapsApiKey;
    if (key.isEmpty) return null;
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
        'origin': origin,
        'destination': destination,
        'key': key,
        'region': 'lt',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['status'] != 'OK') return null;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final legs = (routes.first as Map<String, dynamic>)['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) return null;
      final leg = legs.first as Map<String, dynamic>;
      final meters = (leg['distance'] as Map<String, dynamic>)['value'] as num;
      final seconds = (leg['duration'] as Map<String, dynamic>)['value'] as num;
      final start = leg['start_location'] as Map<String, dynamic>;
      final end = leg['end_location'] as Map<String, dynamic>;
      return (
        distanceKm: meters.toDouble() / 1000,
        duration: Duration(seconds: seconds.round()),
        midLat: ((start['lat'] as num) + (end['lat'] as num)) / 2,
        midLng: ((start['lng'] as num) + (end['lng'] as num)) / 2,
      );
    } catch (_) {
      return null;
    }
  }

  Future<({double lat, double lng})?> _nominatim(String query) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '1',
      });
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'EnergyEniwhere/1.0 (lab)'},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isEmpty) return null;
      final row = list.first as Map<String, dynamic>;
      return (
        lat: double.parse(row['lat'] as String),
        lng: double.parse(row['lon'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

double distanceKmBetween(double lat1, double lon1, double lat2, double lon2) {
  return distanceKm(lat1, lon1, lat2, lon2);
}
