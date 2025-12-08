import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/map_screen.dart';
import '../screens/list_screen.dart';
import '../screens/station_detail_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
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
  ],
);
