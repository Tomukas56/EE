import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/list_screen.dart';
import '../screens/station_detail_screen.dart';
import '../screens/history/charging_history_screen.dart';
import '../screens/history/payment_history_screen.dart';
import '../screens/route/route_planner_screen.dart';
import '../screens/vehicle/vehicle_registration_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
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
      builder: (context, state) => const MapScreen(),
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
  ],
);
