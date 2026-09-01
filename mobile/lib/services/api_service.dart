import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/station.dart';

class ApiService {
  String get baseUrl => AppConfig.apiBase;

  Future<List<Station>> getStations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/stations'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Station.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load stations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stations: $e');
    }
  }

  Future<StationDetail> getStationDetail(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/stations/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return StationDetail.fromJson(json);
      } else if (response.statusCode == 404) {
        throw Exception('Station not found');
      } else {
        throw Exception('Failed to load station: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching station detail: $e');
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      return response.statusCode == 200;
    } catch (e) {
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
    final response = await http.post(
      Uri.parse('$baseUrl/api/crowd/submissions'),
      headers: {'Content-Type': 'application/json'},
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
    final response = await http.get(
      Uri.parse('$baseUrl/api/crowd/submissions?status=PENDING'),
      headers: {
        'Content-Type': 'application/json',
        'X-Owner-Pin': ownerPin,
      },
    );
    if (response.statusCode == 403) {
      throw Exception('Wrong owner PIN');
    }
    if (response.statusCode != 200) {
      throw Exception('Could not load submissions (${response.statusCode})');
    }
    return (jsonDecode(response.body) as List)
        .cast<Map<String, dynamic>>();
  }

  Future<void> confirmSubmission(String ownerPin, String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/crowd/submissions/$id/confirm'),
      headers: {
        'Content-Type': 'application/json',
        'X-Owner-Pin': ownerPin,
      },
      body: '{}',
    );
    if (response.statusCode != 200) {
      throw Exception('Could not confirm (${response.statusCode})');
    }
  }

  Future<void> rejectSubmission(String ownerPin, String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/crowd/submissions/$id/reject'),
      headers: {
        'Content-Type': 'application/json',
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
    final response = await http.post(
      Uri.parse('$baseUrl/api/crowd/check-in'),
      headers: {'Content-Type': 'application/json'},
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
