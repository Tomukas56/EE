import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/station.dart';
import '../models/vehicle.dart';
import '../utils/geo.dart';

class RoutePoint {
  const RoutePoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

class PlannedRoute {
  final double distanceKm;
  final Duration duration;
  final Station? chargingStop;
  final double energyKwh;
  final double estimatedCostEur;
  final String summary;
  final bool usedGoogleDirections;
  final RoutePoint origin;
  final RoutePoint destination;
  final List<RoutePoint> path;

  PlannedRoute({
    required this.distanceKm,
    required this.duration,
    required this.chargingStop,
    required this.energyKwh,
    required this.estimatedCostEur,
    required this.summary,
    required this.usedGoogleDirections,
    required this.origin,
    required this.destination,
    required this.path,
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
    late RoutePoint from;
    late RoutePoint to;
    var path = <RoutePoint>[];

    final directions = await _googleDirections(start, end);
    if (directions != null) {
      usedGoogle = true;
      distanceKm = directions.distanceKm;
      duration = directions.duration;
      from = directions.origin;
      to = directions.destination;
      path = directions.path;
    } else {
      final nominatimFrom = await _nominatim(start);
      final nominatimTo = await _nominatim(end);
      if (nominatimFrom == null || nominatimTo == null) {
        throw Exception('Could not find those places');
      }
      from = RoutePoint(nominatimFrom.lat, nominatimFrom.lng);
      to = RoutePoint(nominatimTo.lat, nominatimTo.lng);
      final straight = distanceKmBetween(from.lat, from.lng, to.lat, to.lng);
      distanceKm = straight * 1.3;
      duration = Duration(minutes: (distanceKm / 80 * 60).round().clamp(1, 24 * 60));
      path = [from, to];
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
      final mid = path.length >= 2
          ? path[path.length ~/ 2]
          : RoutePoint((from.lat + to.lat) / 2, (from.lng + to.lng) / 2);
      stop = nearestStation(candidates, mid.lat, mid.lng);
    }

    if (stop != null && hasCoordinates(stop)) {
      path = _insertStop(path, RoutePoint(stop.latitude!, stop.longitude!));
    }

    final energy = vehicle == null || vehicle.maxRangeKm <= 0
        ? distanceKm * 0.18
        : (distanceKm / vehicle.maxRangeKm) * vehicle.batteryCapacityKWh;
    final cost = energy * _labEurPerKwh;
    final summary = stop == null
        ? 'Within estimated range — no charging stop needed'
        : 'Suggested stop: ${stop.name}. Tap Navigate to open driving directions.';

    return PlannedRoute(
      distanceKm: distanceKm,
      duration: duration,
      chargingStop: stop,
      energyKwh: energy,
      estimatedCostEur: cost,
      summary: summary,
      usedGoogleDirections: usedGoogle,
      origin: from,
      destination: to,
      path: path,
    );
  }

  List<RoutePoint> _insertStop(List<RoutePoint> path, RoutePoint stop) {
    if (path.length < 2) return [...path, stop];
    var bestIndex = 1;
    var best = double.infinity;
    for (var i = 1; i < path.length; i++) {
      final d = distanceKmBetween(path[i].lat, path[i].lng, stop.lat, stop.lng);
      if (d < best) {
        best = d;
        bestIndex = i;
      }
    }
    return [...path.sublist(0, bestIndex), stop, ...path.sublist(bestIndex)];
  }

  Future<
      ({
        double distanceKm,
        Duration duration,
        RoutePoint origin,
        RoutePoint destination,
        List<RoutePoint> path,
      })?> _googleDirections(String origin, String destination) async {
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
      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) return null;
      final firstLeg = legs.first as Map<String, dynamic>;
      final lastLeg = legs.last as Map<String, dynamic>;
      var meters = 0.0;
      var seconds = 0.0;
      for (final raw in legs) {
        final leg = raw as Map<String, dynamic>;
        meters += ((leg['distance'] as Map<String, dynamic>)['value'] as num)
            .toDouble();
        seconds += ((leg['duration'] as Map<String, dynamic>)['value'] as num)
            .toDouble();
      }
      final start = firstLeg['start_location'] as Map<String, dynamic>;
      final end = lastLeg['end_location'] as Map<String, dynamic>;
      final originPoint = RoutePoint(
        (start['lat'] as num).toDouble(),
        (start['lng'] as num).toDouble(),
      );
      final destPoint = RoutePoint(
        (end['lat'] as num).toDouble(),
        (end['lng'] as num).toDouble(),
      );
      final encoded =
          (route['overview_polyline'] as Map<String, dynamic>?)?['points']
              as String?;
      var path = encoded == null || encoded.isEmpty
          ? <RoutePoint>[originPoint, destPoint]
          : decodePolyline(encoded);
      if (path.length > 200) {
        final step = (path.length / 200).ceil();
        final sampled = <RoutePoint>[
          for (var i = 0; i < path.length; i += step) path[i],
        ];
        final last = path.last;
        if (sampled.last.lat != last.lat || sampled.last.lng != last.lng) {
          sampled.add(last);
        }
        path = sampled;
      }
      return (
        distanceKm: meters / 1000,
        duration: Duration(seconds: seconds.round()),
        origin: originPoint,
        destination: destPoint,
        path: path,
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

List<RoutePoint> decodePolyline(String encoded) {
  final points = <RoutePoint>[];
  var index = 0;
  var lat = 0;
  var lng = 0;
  while (index < encoded.length) {
    var shift = 0;
    var result = 0;
    int b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dLat;
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dLng;
    points.add(RoutePoint(lat / 1e5, lng / 1e5));
  }
  return points;
}
