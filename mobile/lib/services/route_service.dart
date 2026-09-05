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
      final geocodedFrom = await _geocode(start);
      final geocodedTo = await _geocode(end);
      if (geocodedFrom == null || geocodedTo == null) {
        throw Exception(
          'Could not find "${geocodedFrom == null ? origin : destination}". '
          'Try a city name such as Vilnius or Riga.',
        );
      }
      from = geocodedFrom;
      to = geocodedTo;
      final osrm = await _osrmRoute(from, to);
      if (osrm != null) {
        distanceKm = osrm.distanceKm;
        duration = osrm.duration;
        path = osrm.path;
      } else {
        final straight = distanceKmBetween(from.lat, from.lng, to.lat, to.lng);
        distanceKm = straight * 1.3;
        duration = Duration(
          minutes: (distanceKm / 80 * 60).round().clamp(1, 24 * 60),
        );
        path = [from, to];
      }
    }

    final rangeKm = vehicle?.maxRangeKm ?? 300;
    final usableKm = rangeKm * 0.8;
    Station? stop;
    if (distanceKm > usableKm) {
      final candidates = stations.where((station) {
        if (!hasCoordinates(station)) return false;
        if (vehicle == null) return true;
        return vehicle.matchesStationPlugs(station.connectorTypes);
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
        ? vehicle == null
            ? 'Within estimated 300 km default range — no charging stop needed'
            : 'Within ${vehicle.label} range (${rangeKm.toStringAsFixed(0)} km) — no charging stop needed'
        : 'Suggested ${vehicle?.connectorType ?? ''} stop: ${stop.name}. Tap Navigate.';

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

  static const _httpHeaders = {
    'User-Agent': 'EnergyEniwhere/1.0 (com.eniwhere.energy; lab)',
    'Accept': 'application/json',
  };

  static const _labPlaces = <String, RoutePoint>{
    'vilnius': RoutePoint(54.6872, 25.2797),
    'kaunas': RoutePoint(54.8985, 23.9036),
    'klaipeda': RoutePoint(55.7033, 21.1443),
    'siauliai': RoutePoint(55.9349, 23.3137),
    'panevezys': RoutePoint(55.7374, 24.3703),
    'riga': RoutePoint(56.9496, 24.1052),
    'ryga': RoutePoint(56.9496, 24.1052),
    'liepaja': RoutePoint(56.5047, 21.0108),
    'daugavpils': RoutePoint(55.8747, 26.5362),
    'tallinn': RoutePoint(59.4370, 24.7536),
    'talinas': RoutePoint(59.4370, 24.7536),
    'tartu': RoutePoint(58.3780, 26.7290),
    'parnu': RoutePoint(58.3859, 24.4971),
    'warsaw': RoutePoint(52.2297, 21.0122),
    'varsuva': RoutePoint(52.2297, 21.0122),
    'krakow': RoutePoint(50.0647, 19.9450),
    'gdansk': RoutePoint(54.3520, 18.6466),
  };

  RoutePoint? _labPlace(String query) {
    final folded = foldSearchText(query.trim());
    if (folded.isEmpty) return null;
    final primary = folded.split(RegExp(r'[,/]')).first.trim();
    final exact = _labPlaces[primary] ?? _labPlaces[folded];
    if (exact != null) return exact;
    for (final entry in _labPlaces.entries) {
      if (primary.startsWith(entry.key) ||
          (entry.key.startsWith(primary) && primary.length >= 3)) {
        return entry.value;
      }
    }
    return null;
  }

  Future<RoutePoint?> _geocode(String query) async {
    final local = _labPlace(query);
    if (local != null) return local;
    return await _nominatim(query) ?? await _photon(query);
  }

  Future<
      ({
        double distanceKm,
        Duration duration,
        List<RoutePoint> path,
      })?> _osrmRoute(RoutePoint from, RoutePoint to) async {
    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/${from.lng},${from.lat};${to.lng},${to.lat}',
        {
          'overview': 'simplified',
          'geometries': 'polyline',
        },
      );
      final response = await http
          .get(uri, headers: _httpHeaders)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['code'] != 'Ok') return null;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final encoded = route['geometry'] as String?;
      final meters = (route['distance'] as num?)?.toDouble() ?? 0;
      final seconds = (route['duration'] as num?)?.toDouble() ?? 0;
      final path = encoded == null || encoded.isEmpty
          ? <RoutePoint>[from, to]
          : decodePolyline(encoded);
      return (
        distanceKm: meters / 1000,
        duration: Duration(seconds: seconds.round().clamp(1, 24 * 3600).toInt()),
        path: path,
      );
    } catch (_) {
      return null;
    }
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

  Future<RoutePoint?> _nominatim(String query) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'lt,lv,ee,pl',
      });
      final response = await http
          .get(uri, headers: _httpHeaders)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isEmpty) return null;
      final row = list.first as Map<String, dynamic>;
      return RoutePoint(
        double.parse(row['lat'] as String),
        double.parse(row['lon'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<RoutePoint?> _photon(String query) async {
    try {
      final uri = Uri.https('photon.komoot.io', '/api', {
        'q': query,
        'limit': '1',
      });
      final response = await http
          .get(uri, headers: _httpHeaders)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final features = body['features'] as List<dynamic>?;
      if (features == null || features.isEmpty) return null;
      final geometry = (features.first as Map<String, dynamic>)['geometry']
          as Map<String, dynamic>?;
      final coords = geometry?['coordinates'] as List<dynamic>?;
      if (coords == null || coords.length < 2) return null;
      return RoutePoint(
        (coords[1] as num).toDouble(),
        (coords[0] as num).toDouble(),
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
