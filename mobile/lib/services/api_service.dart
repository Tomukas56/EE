import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';

class ApiService {
  // TODO: Change to your backend IP for physical device testing
  // For emulator: use 10.0.2.2 (Android) or localhost (iOS)
  static const String baseUrl = 'http://localhost:3000';

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
}
