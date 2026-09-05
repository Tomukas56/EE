import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/vehicle_provider.dart';
import 'routes/app_router.dart';
import 'services/auth_service.dart';
import 'widgets/phone_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.ensureFirebase();
  final saved = await AuthService.readSavedUser();
  final savedVehicle = await VehicleNotifier.readSaved();
  debugPrint(
    saved == null
        ? 'EE start: no saved account — splash/welcome'
        : 'EE start: restored ${saved.id}, skip welcome',
  );
  debugPrint(
    savedVehicle == null
        ? 'EE start: no saved vehicle'
        : 'EE start: vehicle ${savedVehicle.label}',
  );

  runApp(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith((ref) {
          return SessionNotifier(ref.watch(authServiceProvider), saved);
        }),
        vehicleProvider.overrideWith((ref) {
          return VehicleNotifier(initial: savedVehicle);
        }),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Energy Eniwhere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(AppTheme.lightTheme.textTheme),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(AppTheme.darkTheme.textTheme),
      ),
      themeMode: ThemeMode.system,
      builder: (context, child) =>
          PhoneShell(child: child ?? const SizedBox.shrink()),
      routerConfig: router,
    );
  }
}
