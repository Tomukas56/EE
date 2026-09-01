import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';

const _vehicleKey = 'ee.vehicle.profile';

class VehicleNotifier extends StateNotifier<Vehicle?> {
  VehicleNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vehicleKey);
    if (raw == null || raw.isEmpty) return;
    try {
      state = Vehicle.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> save(Vehicle vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehicleKey, jsonEncode(vehicle.toJson()));
    state = vehicle;
  }
}

final vehicleProvider = StateNotifierProvider<VehicleNotifier, Vehicle?>((ref) {
  return VehicleNotifier();
});
