import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (results) {
      return results.isNotEmpty &&
          !results.every((r) => r == ConnectivityResult.none);
    },
    loading: () => true, // Assume online while checking
    error: (error, stack) => true, // Assume online on error
  );
});
