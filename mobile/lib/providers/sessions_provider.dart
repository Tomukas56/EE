import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/charging_session.dart';
import 'auth_provider.dart';
import 'stations_provider.dart';

String labReporterId(AppUser? user) {
  if (user == null) return 'lab-device';
  if (user.id.isNotEmpty) return user.id;
  if (user.email.isNotEmpty) return user.email;
  return 'lab-device';
}

final chargingHistoryProvider = FutureProvider<List<ChargingSession>>((ref) async {
  final user = ref.watch(sessionProvider);
  return ref.watch(apiServiceProvider).getSessions(labReporterId(user));
});

final openSessionProvider = Provider<ChargingSession?>((ref) {
  final sessions = ref.watch(chargingHistoryProvider).value;
  if (sessions == null) return null;
  for (final session in sessions) {
    if (session.isOpen) return session;
  }
  return null;
});
