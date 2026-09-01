import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/charging_session.dart';
import '../models/station.dart';

class ApiService {
  String? _resolvedBase;
  static const _jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  String get baseUrl => _resolvedBase ?? AppConfig.apiBase;

  List<String> get _candidates {
    final seen = <String>{};
    final list = <String>[];
    void add(String url) {
      if (seen.add(url)) list.add(url);
    }

    add(AppConfig.apiBase);
    if (!kIsWeb) {
      add('http://127.0.0.1:3000');
      add(AppConfig.lanApi);
    }
    return list;
  }

  Future<String> _liveBase() async {
    if (_resolvedBase != null) return _resolvedBase!;
    Object? lastError;
    for (final base in _candidates) {
      try {
        final response = await http
            .get(
              Uri.parse('$base/api/stations'),
              headers: _jsonHeaders,
            )
            .timeout(const Duration(seconds: 4));
        final body = response.body.trimLeft();
        if (response.statusCode == 200 && body.startsWith('[')) {
          _resolvedBase = base;
          return base;
        }
      } catch (error) {
        lastError = error;
      }
    }
    throw Exception(
      'Cannot reach the Energy Eniwhere API. '
      'Tried ${_candidates.join(', ')}. $lastError',
    );
  }

  Future<List<Station>> getStations() async {
    final base = await _liveBase();
    final response = await http.get(
      Uri.parse('$base/api/stations'),
      headers: _jsonHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load stations: ${response.statusCode}');
    }
    final body = response.body.trimLeft();
    if (!body.startsWith('[')) {
      throw Exception('API did not return station JSON from $base');
    }
    final jsonList = json.decode(response.body) as List<dynamic>;
    return jsonList
        .map((row) => Station.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChargingSession>> getSessions(String reporterId, {String? status}) async {
    final base = await _liveBase();
    final uri = Uri.parse('$base/api/sessions').replace(
      queryParameters: {
        'reporterId': reporterId,
        if (status != null) 'status': status,
      },
    );
    final response = await http.get(uri, headers: _jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('Failed to load sessions: ${response.statusCode}');
    }
    final jsonList = json.decode(response.body) as List<dynamic>;
    return jsonList
        .map((row) => ChargingSession.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<ChargingSession> startSession({
    required String stationId,
    required String reporterId,
    String? connectorType,
  }) async {
    final base = await _liveBase();
    final response = await http.post(
      Uri.parse('$base/api/sessions'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'station_id': stationId,
        'reporter_id': reporterId,
        'connector_type': connectorType,
      }),
    );
    if (response.statusCode == 409) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final existing = body['session'];
      if (existing is Map<String, dynamic>) {
        return ChargingSession.fromJson(existing);
      }
      throw Exception(body['error'] ?? 'Session already open');
    }
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Could not start session (${response.statusCode})');
    }
    return ChargingSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ChargingSession> stopSession(String id) async {
    final base = await _liveBase();
    final response = await http.post(
      Uri.parse('$base/api/sessions/$id/stop'),
      headers: _jsonHeaders,
      body: '{}',
    );
    if (response.statusCode != 200) {
      throw Exception('Could not stop session (${response.statusCode})');
    }
    return ChargingSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<StationDetail> getStationDetail(String id) async {
    final base = await _liveBase();
    final response = await http.get(
      Uri.parse('$base/api/stations/$id'),
      headers: _jsonHeaders,
    );
    if (response.statusCode == 404) {
      throw Exception('Station not found');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to load station: ${response.statusCode}');
    }
    return StationDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<bool> checkHealth() async {
    try {
      await _liveBase();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> submitStation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? operatorName,
    String? connectorNote,
    String? submittedBy,
  }) async {
    final base = await _liveBase();
    final response = await http.post(
      Uri.parse('$base/api/crowd/submissions'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'operator_name': operatorName,
        'connector_note': connectorNote,
        'submitted_by': submittedBy,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Could not save station (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listSubmissions(String ownerPin) async {
    final base = await _liveBase();
    final response = await http.get(
      Uri.parse('$base/api/crowd/submissions?status=PENDING'),
      headers: {
        ..._jsonHeaders,
        'X-Owner-Pin': ownerPin,
      },
    );
    if (response.statusCode == 403) {
      throw Exception('Wrong owner PIN');
    }
    if (response.statusCode != 200) {
      throw Exception('Could not load submissions (${response.statusCode})');
    }
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<void> confirmSubmission(String ownerPin, String id) async {
    final base = await _liveBase();
    final response = await http.post(
      Uri.parse('$base/api/crowd/submissions/$id/confirm'),
      headers: {
        ..._jsonHeaders,
        'X-Owner-Pin': ownerPin,
      },
      body: '{}',
    );
    if (response.statusCode != 200) {
      throw Exception('Could not confirm (${response.statusCode})');
    }
  }

  Future<void> rejectSubmission(String ownerPin, String id) async {
    final base = await _liveBase();
    final response = await http.post(
      Uri.parse('$base/api/crowd/submissions/$id/reject'),
      headers: {
        ..._jsonHeaders,
        'X-Owner-Pin': ownerPin,
      },
      body: '{}',
    );
    if (response.statusCode != 200) {
      throw Exception('Could not reject (${response.statusCode})');
    }
  }

  Future<void> sendCheckIn({
    required String stationId,
    required String working,
    required String freeConnectors,
    String? reporterId,
    double? latitude,
    double? longitude,
  }) async {
    final base = await _liveBase();
    final response = await http.post(
      Uri.parse('$base/api/crowd/check-in'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'station_id': stationId,
        'working': working,
        'free_connectors': freeConnectors,
        'reporter_id': reporterId,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Could not send report (${response.statusCode})');
    }
  }
}
