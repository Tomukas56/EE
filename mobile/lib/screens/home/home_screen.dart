import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stations_provider.dart';
import '../../providers/vehicle_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _MenuItem? _submenu;

  List<_MenuItem> _rootItems(BuildContext context, {required bool limited}) {
    void lockedTap() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Skip mode: only the map works this time. Sign in from Account to accept the Terms.',
          ),
        ),
      );
    }

    return [
      _MenuItem(
        title: 'Stations',
        subtitle: limited
            ? 'Map only (Skip)'
            : 'Map · Nearest · List · Mark new',
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
            locked: limited,
            onTap: limited
                ? lockedTap
                : () => context.pushNamed(
                      'map',
                      queryParameters: {'nearest': '1'},
                    ),
          ),
          _MenuItem(
            title: 'Station list',
            subtitle: 'Search by name or operator',
            icon: Icons.list_alt,
            gradient: AppColors.accentGradient,
            locked: limited,
            onTap: limited ? lockedTap : () => context.pushNamed('list'),
          ),
          _MenuItem(
            title: 'Mark a new station',
            subtitle: 'Hidden until the owner confirms',
            icon: Icons.add_location_alt,
            gradient: const LinearGradient(
              colors: [Color(0xFF00C48C), Color(0xFF0066FF)],
            ),
            locked: limited,
            onTap: limited ? lockedTap : () => context.pushNamed('mark-station'),
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
        locked: limited,
        onTap: lockedTap,
        children: limited
            ? null
            : [
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
            subtitle: ref.watch(vehicleProvider)?.label ??
                'Battery, range, connector',
            icon: Icons.directions_car,
            gradient: const LinearGradient(
              colors: [Color(0xFF0066FF), Color(0xFF00D9C0)],
            ),
            onTap: () => context.pushNamed('vehicle-registration'),
          ),
        ],
      ),
      _MenuItem(
        title: 'Payments',
        subtitle: 'Sessions · History',
        icon: Icons.payments,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
        ),
        locked: limited,
        onTap: lockedTap,
        children: limited
            ? null
            : [
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
        subtitle: limited
            ? 'Legal · Sign in'
            : 'Profile · Legal · Owner · Sign out',
        icon: Icons.person,
        gradient: const LinearGradient(
          colors: [Color(0xFF3A3A3C), Color(0xFF636366)],
        ),
        children: [
          _MenuItem(
            title: limited ? 'Not signed in' : 'Signed in',
            subtitle: limited
                ? 'Skip — map only this time'
                : (ref.read(sessionProvider)?.label ?? 'This device'),
            icon: Icons.badge_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFF3A3A3C), Color(0xFF636366)],
            ),
          ),
          _MenuItem(
            title: 'Legal & privacy',
            subtitle: limited ? 'Read the Terms' : 'Terms and privacy',
            icon: Icons.gavel,
            gradient: const LinearGradient(
              colors: [Color(0xFF0066FF), Color(0xFF00C48C)],
            ),
            onTap: () => context.pushNamed('legal'),
          ),
          if (!limited)
            _MenuItem(
              title: 'Owner review',
              subtitle: 'Inbox: confirm crowd-marked stations before they go on the public map',
              icon: Icons.verified_user,
              gradient: const LinearGradient(
                colors: [Color(0xFF0066FF), Color(0xFF7B61FF)],
              ),
              onTap: () => context.pushNamed('owner-review'),
            ),
          _MenuItem(
            title: limited ? 'Sign in' : 'Sign out',
            subtitle: limited
                ? 'Accept the Terms and continue with Google'
                : 'End this session and close the app',
            icon: limited ? Icons.login : Icons.logout,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF3B30), Color(0xFFFF6B35)],
            ),
            onTap: () async {
              final closeApp = !limited;
              await ref.read(sessionProvider.notifier).signOut();
              if (closeApp) {
                await SystemNavigator.pop();
              }
            },
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
    final limited = user?.limitedAccess == true;
    final items = _submenu?.children ?? _rootItems(context, limited: limited);
    final inSubmenu = _submenu != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F3A),
      body: ColoredBox(
        color: const Color(0xFF0B1F3A),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MenuHeader(
                userLabel: user?.label ?? 'Account',
                photoUrl: user?.photoUrl,
                stationCount: stationCount,
                submenuTitle: _submenu?.title,
                onBack: inSubmenu ? () => setState(() => _submenu = null) : null,
              ),
              if (limited && !inSubmenu)
                Material(
                  color: const Color(0xFFFFB800),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Text(
                      'Skip mode — ${user?.label ?? 'map only'}. '
                      'Only Map of stations works. Sign out to accept the Terms.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              Expanded(
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
            ],
          ),
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
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final List<_MenuItem>? children;
  final VoidCallback? onTap;
  final bool locked;
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
    return Padding(
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
    return _DashboardCard(item: item, onTap: () => onOpen(item));
  }

  @override
  Widget build(BuildContext context) {
    final tiles = items.map(_tile).toList();
    final n = tiles.length;

    Widget row(List<Widget> cells) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final cell in cells) Expanded(child: cell),
        ],
      );
    }

    Widget column(List<Widget> cells) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final cell in cells) Expanded(child: cell),
        ],
      );
    }

    if (n <= 1) {
      return tiles.first;
    }

    if (n == 2) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = constraints.maxWidth >= constraints.maxHeight;
          return sideBySide ? row(tiles) : column(tiles);
        },
      );
    }

    if (n == 3) {
      return column([
        row([tiles[0], tiles[1]]),
        tiles[2],
      ]);
    }

    return column([
      row([tiles[0], tiles[1]]),
      row([
        tiles[2],
        if (n > 3) tiles[3],
      ]),
    ]);
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.item, required this.onTap});

  final _MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(gradient: item.gradient),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 80, color: Colors.white),
                  const SizedBox(height: 14),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 16,
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
    if (item.locked) {
      card = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: card,
      );
      card = Stack(
        children: [
          Positioned.fill(child: card),
          const Positioned(
            top: 12,
            right: 12,
            child: Icon(Icons.lock, color: Colors.white70, size: 22),
          ),
        ],
      );
    }
    return SizedBox.expand(child: card);
  }
}
