import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stations_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _MenuItem? _submenu;

  List<_MenuItem> _rootItems(BuildContext context) {
    return [
      _MenuItem(
        title: 'Stations',
        subtitle: 'Map · Nearest · List · Mark new',
        icon: Icons.ev_station,
        gradient: AppColors.primaryGradient,
        children: [
          _MenuItem(
            title: 'Map of stations',
            subtitle: 'All columns on the map',
            icon: Icons.map,
            gradient: AppColors.primaryGradient,
            onTap: () => context.pushNamed('map'),
          ),
          _MenuItem(
            title: 'Nearest column',
            subtitle: 'Closest to you',
            icon: Icons.near_me,
            gradient: const LinearGradient(
              colors: [Color(0xFF00C48C), Color(0xFF00D9A0)],
            ),
            onTap: () => context.pushNamed(
              'map',
              queryParameters: {'nearest': '1'},
            ),
          ),
          _MenuItem(
            title: 'Station list',
            subtitle: 'Search by name or operator',
            icon: Icons.list_alt,
            gradient: AppColors.accentGradient,
            onTap: () => context.pushNamed('list'),
          ),
          _MenuItem(
            title: 'Mark a new station',
            subtitle: 'Hidden until the owner confirms',
            icon: Icons.add_location_alt,
            gradient: const LinearGradient(
              colors: [Color(0xFF00C48C), Color(0xFF0066FF)],
            ),
            onTap: () => context.pushNamed('mark-station'),
          ),
        ],
      ),
      _MenuItem(
        title: 'Trip',
        subtitle: 'Route · Vehicle',
        icon: Icons.route,
        gradient: const LinearGradient(
          colors: [Color(0xFF7B61FF), Color(0xFF9B7FFF)],
        ),
        children: [
          _MenuItem(
            title: 'Trip with charging',
            subtitle: 'Route with a charging stop',
            icon: Icons.alt_route,
            gradient: const LinearGradient(
              colors: [Color(0xFF7B61FF), Color(0xFF9B7FFF)],
            ),
            onTap: () => context.pushNamed('route-planner'),
          ),
          _MenuItem(
            title: 'My vehicle',
            subtitle: 'Battery, range, connector',
            icon: Icons.directions_car,
            gradient: const LinearGradient(
              colors: [Color(0xFF0066FF), Color(0xFF00D9C0)],
            ),
            onTap: () => context.pushNamed('vehicle-registration'),
          ),
        ],
      ),
      _MenuItem(
        title: 'History',
        subtitle: 'Sessions · Payments',
        icon: Icons.history,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
        ),
        children: [
          _MenuItem(
            title: 'Charging history',
            subtitle: 'Past sessions',
            icon: Icons.ev_station_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
            ),
            onTap: () => context.pushNamed('charging-history'),
          ),
          _MenuItem(
            title: 'Payments',
            subtitle: 'Receipts and fees',
            icon: Icons.payment,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB800), Color(0xFFFFC933)],
            ),
            onTap: () => context.pushNamed('payment-history'),
          ),
        ],
      ),
      _MenuItem(
        title: 'Account',
        subtitle: 'Profile · Owner · Sign out',
        icon: Icons.person,
        gradient: const LinearGradient(
          colors: [Color(0xFF3A3A3C), Color(0xFF636366)],
        ),
        children: [
          _MenuItem(
            title: 'Signed in',
            subtitle: ref.read(sessionProvider)?.label ?? 'This device',
            icon: Icons.badge_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFF3A3A3C), Color(0xFF636366)],
            ),
          ),
          _MenuItem(
            title: 'Owner review',
            subtitle: 'Confirm a physical location',
            icon: Icons.verified_user,
            gradient: const LinearGradient(
              colors: [Color(0xFF0066FF), Color(0xFF7B61FF)],
            ),
            onTap: () => context.pushNamed('owner-review'),
          ),
          _MenuItem(
            title: 'Sign out',
            subtitle: 'Return to the Agreement',
            icon: Icons.logout,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF3B30), Color(0xFFFF6B35)],
            ),
            onTap: () => ref.read(sessionProvider.notifier).signOut(),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    final stationsAsync = ref.watch(stationsProvider);
    final stationCount = stationsAsync.maybeWhen(
      data: (stations) => '${stations.length}',
      orElse: () => '…',
    );
    final items = _submenu?.children ?? _rootItems(context);
    final inSubmenu = _submenu != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _MenuHeader(
              userLabel: user?.label ?? 'Account',
              photoUrl: user?.photoUrl,
              stationCount: stationCount,
              submenuTitle: _submenu?.title,
              onBack: inSubmenu ? () => setState(() => _submenu = null) : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: _FillMenu(
                  items: items,
                  onOpen: (item) {
                    if (item.children != null) {
                      setState(() => _submenu = item);
                    } else if (item.onTap != null) {
                      item.onTap!();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.children,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final List<_MenuItem>? children;
  final VoidCallback? onTap;
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({
    required this.userLabel,
    required this.stationCount,
    this.photoUrl,
    this.submenuTitle,
    this.onBack,
  });

  final String userLabel;
  final String stationCount;
  final String? photoUrl;
  final String? submenuTitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            )
          else
            CircleAvatar(
              radius: 22,
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submenuTitle ?? 'Menu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  submenuTitle == null
                      ? '$stationCount stations · $userLabel'
                      : 'Choose an option',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays tiles so they fill the window. No leftover empty cells.
class _FillMenu extends StatelessWidget {
  const _FillMenu({required this.items, required this.onOpen});

  final List<_MenuItem> items;
  final ValueChanged<_MenuItem> onOpen;

  Widget _tile(_MenuItem item) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: _DashboardCard(item: item, onTap: () => onOpen(item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = items.map(_tile).toList();
    final n = tiles.length;

    if (n <= 1) {
      return tiles.first;
    }

    if (n == 2) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = constraints.maxWidth >= constraints.maxHeight;
          if (sideBySide) {
            return Row(
              children: [
                Expanded(child: tiles[0]),
                Expanded(child: tiles[1]),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: tiles[0]),
              Expanded(child: tiles[1]),
            ],
          );
        },
      );
    }

    if (n == 3) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: tiles[0]),
                Expanded(child: tiles[1]),
              ],
            ),
          ),
          Expanded(child: tiles[2]),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: tiles[0]),
              Expanded(child: tiles[1]),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: tiles[2]),
              if (n > 3) Expanded(child: tiles[3]),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.item, required this.onTap});

  final _MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: item.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 52, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
