import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';

const _vehicleKey = 'ee.vehicle.profile';

class VehicleNotifier extends StateNotifier<Vehicle?> {
  VehicleNotifier({Vehicle? initial}) : super(initial) {
    if (initial == null) {
      _load();
    }
  }

  static Future<Vehicle?> readSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vehicleKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Vehicle.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final vehicle = await readSaved();
    if (vehicle != null) state = vehicle;
  }

  Future<void> save(Vehicle vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehicleKey, jsonEncode(vehicle.toJson()));
    state = vehicle;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vehicleKey);
    state = null;
  }
}

final vehicleProvider = StateNotifierProvider<VehicleNotifier, Vehicle?>((ref) {
  return VehicleNotifier();
});
