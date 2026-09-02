import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/list_screen.dart';
import '../screens/station_detail_screen.dart';
import '../screens/history/charging_history_screen.dart';
import '../screens/history/payment_history_screen.dart';
import '../screens/route/route_planner_screen.dart';
import '../screens/vehicle/vehicle_registration_screen.dart';
import '../screens/stations/mark_station_screen.dart';
import '../screens/stations/owner_review_screen.dart';
import '../screens/account/legal_account_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (previous, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;
      final user = ref.read(sessionProvider);
      final loggedIn = user != null;
      final onWelcome = loc == '/welcome';
      if (!loggedIn && !onWelcome) return '/welcome';
      if (loggedIn && onWelcome) return '/home';
      if (user?.limitedAccess == true) {
        const locked = {
          '/vehicle-registration',
          '/route-planner',
          '/charging-history',
          '/payment-history',
          '/mark-station',
          '/owner-review',
          '/list',
        };
        if (locked.contains(loc)) return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => SplashScreen(
          onFinished: () {
            final user = ref.read(sessionProvider);
            final signedIn = user != null && !user.limitedAccess;
            context.go(signedIn ? '/home' : '/welcome');
          },
        ),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/vehicle-registration',
        name: 'vehicle-registration',
        builder: (context, state) => const VehicleRegistrationScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'map',
        builder: (context, state) => MapScreen(
          focusNearest: state.uri.queryParameters['nearest'] == '1',
        ),
      ),
      GoRoute(
        path: '/list',
        name: 'list',
        builder: (context, state) => const ListScreen(),
      ),
      GoRoute(
        path: '/station/:id',
        name: 'station-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StationDetailScreen(stationId: id);
        },
      ),
      GoRoute(
        path: '/charging-history',
        name: 'charging-history',
        builder: (context, state) => const ChargingHistoryScreen(),
      ),
      GoRoute(
        path: '/payment-history',
        name: 'payment-history',
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: '/route-planner',
        name: 'route-planner',
        builder: (context, state) => const RoutePlannerScreen(),
      ),
      GoRoute(
        path: '/mark-station',
        name: 'mark-station',
        builder: (context, state) => const MarkStationScreen(),
      ),
      GoRoute(
        path: '/legal',
        name: 'legal',
        builder: (context, state) => const LegalAccountScreen(),
      ),
      GoRoute(
        path: '/owner-review',
        name: 'owner-review',
        builder: (context, state) => const OwnerReviewScreen(),
      ),
    ],
  );
});
