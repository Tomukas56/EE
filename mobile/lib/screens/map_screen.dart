import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../models/station.dart';
import '../providers/auth_provider.dart';
import '../providers/stations_provider.dart';
import '../services/location_service.dart';
import '../utils/geo.dart';
import '../widgets/arrival_check_sheet.dart';
import '../widgets/map_filter_rail.dart';
import '../widgets/osm_tile_layer.dart';
import '../widgets/price_map_pin.dart';

class MapScreen extends ConsumerStatefulWidget {
  final bool focusNearest;

  const MapScreen({super.key, this.focusNearest = false});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Station> _searchHits = const [];
  gmaps.GoogleMapController? _googleMap;
  final Set<gmaps.Marker> _markers = {};
  List<Station> _pins = const [];
  bool _didCenterOnDevice = false;
  bool _locateDone = false;
  double _zoom = nearbyZoom;
  double? _cameraLat;
  double? _cameraLng;
  DevicePosition? _me;
  final Set<String> _promptedArrival = {};
  bool _useGoogleMap = AppConfig.useGoogleMaps;
  final PricePinCache _pinCache = PricePinCache();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_locateOnOpen);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool _googleFallbackArmed = false;

  void _armGoogleFallback() {
    if (_googleFallbackArmed || !AppConfig.useGoogleMaps) return;
    _googleFallbackArmed = true;
    Future<void>.delayed(const Duration(seconds: 20), () {
      if (!mounted || _googleMap != null) return;
      setState(() => _useGoogleMap = false);
    });
  }

  List<Station> _mappable(List<Station> stations) {
    return stations.where(hasCoordinates).toList();
  }

  List<Station> _nearbyPins(List<Station> stations) {
    final lat = _cameraLat ?? _me?.latitude;
    final lng = _cameraLng ?? _me?.longitude;
    if (lat == null || lng == null) return const [];
    return stationsWithin(
      stations,
      lat,
      lng,
      radiusKm: radiusKmForZoom(_zoom),
    );
  }

  Future<void> _locateOnOpen() async {
    try {
      final position =
          await ref.read(locationServiceProvider).getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _me = position;
        _cameraLat = position.latitude;
        _cameraLng = position.longitude;
        _zoom = nearbyZoom;
        _locateDone = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraLat = vilniusLat;
        _cameraLng = vilniusLng;
        _zoom = nearbyZoom;
        _locateDone = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $error')),
      );
    }
  }

  Future<void> _nudgeZoom(double delta) async {
    final next = (_zoom + delta).clamp(nearbyMinZoom, nearbyMaxZoom);
    if ((next - _zoom).abs() < 0.05) return;
    _zoom = next;
    if (_useGoogleMap && _googleMap != null) {
      await _googleMap?.animateCamera(gmaps.CameraUpdate.zoomTo(next));
    } else {
      final lat = _cameraLat ?? _me?.latitude ?? vilniusLat;
      final lng = _cameraLng ?? _me?.longitude ?? vilniusLng;
      _mapController.move(LatLng(lat, lng), next);
    }
    if (mounted) setState(() {});
  }

  Future<void> _moveCamera(double lat, double lng, double zoom) async {
    _zoom = zoom;
    _cameraLat = lat;
    _cameraLng = lng;
    if (_useGoogleMap && _googleMap != null) {
      await _googleMap?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(lat, lng), zoom),
      );
    } else {
      _mapController.move(LatLng(lat, lng), zoom);
    }
  }

  void _selectStation(Station station, {bool moveCamera = true}) {
    ref.read(destinationStationProvider.notifier).state = station;
    if (moveCamera) {
      _moveCamera(station.latitude!, station.longitude!, nearbyZoom);
    }
    if (_useGoogleMap) {
      _refreshGoogleMarkers(_pins);
    }
  }

  void _selectNearestTo(double lat, double lng, List<Station> stations) {
    final station = nearestStation(stations, lat, lng);
    if (station == null) {
      _clearDestination();
      return;
    }
    final km = distanceKm(lat, lng, station.latitude!, station.longitude!);
    final maxKm = (40 / pow(2, _zoom - 6)).clamp(0.2, 45);
    if (km > maxKm) {
      _clearDestination();
      return;
    }
    _selectStation(station, moveCamera: false);
  }

  void _clearDestination() {
    if (ref.read(destinationStationProvider) == null) return;
    ref.read(destinationStationProvider.notifier).state = null;
    if (_useGoogleMap) {
      _refreshGoogleMarkers(_pins);
    }
  }

  Future<void> _goToMyLocation({bool thenNearest = false}) async {
    try {
      final position = await ref.read(locationServiceProvider).getCurrentPosition();
      setState(() => _me = position);
      await _moveCamera(position.latitude, position.longitude, nearbyZoom);

      if (thenNearest) {
        final filtered = ref.read(filteredStationsProvider).value ?? [];
        final stations = _mappable(filtered);
        final station = nearestStation(stations, position.latitude, position.longitude);
        if (station != null) _selectStation(station);
      }
      _maybePromptArrival(ref.read(destinationStationProvider));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $error')),
      );
    }
  }

  void _pickSearchHit(Station station) {
    _searchFocus.unfocus();
    _searchController.text = station.name;
    setState(() => _searchHits = const []);
    _selectStation(station);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() => _searchHits = const []);
  }

  void _dismissKeyboard() {
    if (_searchFocus.hasFocus) _searchFocus.unfocus();
  }

  void _applySearch(List<Station> stations) {
    _dismissKeyboard();
    final hits = stationsMatchingQuery(stations, _searchController.text);
    setState(() => _searchHits = hits);
    if (_searchController.text.trim().length < 2) {
      return;
    }
    if (hits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No station matched that search')),
      );
      return;
    }
    if (hits.length == 1) {
      _pickSearchHit(hits.first);
    }
  }

  Future<void> _openDirections(Station station) async {
    final dest = '${station.latitude},${station.longitude}';
    final origin = _me != null ? '${_me!.latitude},${_me!.longitude}' : null;
    final url = Uri.parse(
      origin == null
          ? 'https://www.google.com/maps/dir/?api=1&destination=$dest'
          : 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _maybePromptArrival(Station? destination) {
    if (ref.read(sessionProvider)?.limitedAccess == true) return;
    if (destination == null || _me == null || !hasCoordinates(destination)) {
      return;
    }
    if (_promptedArrival.contains(destination.id)) return;
    final km = distanceKm(
      _me!.latitude,
      _me!.longitude,
      destination.latitude!,
      destination.longitude!,
    );
    if (km > 0.12) return;
    _promptedArrival.add(destination.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reportArrival(destination);
    });
  }

  Future<void> _reportArrival(Station station) async {
    final result = await showArrivalCheckSheet(
      context,
      stationName: station.name,
    );
    if (result == null || !mounted) return;
    if (ref.read(sessionProvider)?.limitedAccess == true) return;
    final user = ref.read(sessionProvider);
    try {
      await ref.read(apiServiceProvider).sendCheckIn(
            stationId: station.id,
            working: result.workingApi,
            freeConnectors: result.freeConnectorsApi,
            reporterId: user?.id ?? user?.email,
            latitude: _me?.latitude,
            longitude: _me?.longitude,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks. Report saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save report: $error')),
      );
    }
  }

  Future<void> _refreshGoogleMarkers(List<Station> pins) async {
    _pins = pins;
    final selected = ref.read(destinationStationProvider);
    var visible = _nearbyPins(pins);
    if (visible.length > 40) {
      visible = stationsNear(
        visible,
        _cameraLat ?? _me?.latitude ?? vilniusLat,
        _cameraLng ?? _me?.longitude ?? vilniusLng,
        limit: 40,
      );
    }
    if (selected != null &&
        hasCoordinates(selected) &&
        !visible.any((station) => station.id == selected.id)) {
      visible = [...visible, selected];
    }
    if (!mounted) return;
    final showPrice = _zoom >= pricePinMinZoom;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final next = <gmaps.Marker>{};
    for (final station in visible) {
      final icon = await _pinCache.icon(
        pixelRatio: dpr,
        selected: selected?.id == station.id,
        live: station.hasLiveOccupancy,
        available: station.availableConnectors > 0,
        priceLabel: showPrice ? station.tariffPinLabel : null,
      );
      if (!mounted) return;
      next.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId(station.id),
          position: gmaps.LatLng(station.latitude!, station.longitude!),
          infoWindow: const gmaps.InfoWindow(),
          consumeTapEvents: true,
          icon: icon,
          anchor: const Offset(0.5, 1),
          onTap: () => _selectStation(station, moveCamera: false),
        ),
      );
    }
    final sameIds = next.length == _markers.length &&
        next.every((marker) => _markers.any((m) => m.markerId == marker.markerId && m.icon == marker.icon));
    if (sameIds) return;
    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(next);
    });
  }

  Widget _buildBasemap(List<Station> pins) {
    final centerLat = _cameraLat ?? _me?.latitude ?? vilniusLat;
    final centerLng = _cameraLng ?? _me?.longitude ?? vilniusLng;
    if (_useGoogleMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _armGoogleFallback());
      return gmaps.GoogleMap(
        key: const ValueKey('ee-google-map'),
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(centerLat, centerLng),
          zoom: nearbyZoom,
        ),
        minMaxZoomPreference: const gmaps.MinMaxZoomPreference(
          nearbyMinZoom,
          nearbyMaxZoom,
        ),
        markers: Set<gmaps.Marker>.of(_markers),
        circles: {
          if (_me != null)
            gmaps.Circle(
              circleId: const gmaps.CircleId('nearby'),
              center: gmaps.LatLng(_me!.latitude, _me!.longitude),
              radius: radiusKmForZoom(_zoom) * 1000,
              fillColor: const Color(0x220066FF),
              strokeColor: const Color(0xFF0066FF),
              strokeWidth: 1,
            ),
        },
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {
          _googleMap = controller;
          _refreshGoogleMarkers(pins);
        },
        onTap: (latLng) {
          _dismissKeyboard();
          _selectNearestTo(latLng.latitude, latLng.longitude, pins);
        },
        onCameraMove: (position) {
          _zoom = position.zoom;
          _cameraLat = position.target.latitude;
          _cameraLng = position.target.longitude;
        },
        onCameraIdle: () {
          if (mounted) setState(() {});
          _refreshGoogleMarkers(pins);
        },
      );
    }

    final destination = ref.watch(destinationStationProvider);
    final osmPins = _nearbyPins(pins);
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: nearbyZoom,
        minZoom: nearbyMinZoom,
        maxZoom: nearbyMaxZoom,
        onPositionChanged: (camera, hasGesture) {
          _zoom = camera.zoom;
          _cameraLat = camera.center.latitude;
          _cameraLng = camera.center.longitude;
          if (!hasGesture && mounted) setState(() {});
        },
        onTap: (tap, latlng) {
          _dismissKeyboard();
          _selectNearestTo(latlng.latitude, latlng.longitude, pins);
        },
      ),
      children: [
        const OsmTileLayer(),
        if (_me != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(_me!.latitude, _me!.longitude),
                radius: radiusKmForZoom(_zoom) * 1000,
                useRadiusInMeter: true,
                color: const Color(0x220066FF),
                borderStrokeWidth: 1,
                borderColor: const Color(0xFF0066FF),
              ),
            ],
          ),
        CircleLayer(
          circles: [
            for (final station in osmPins)
              CircleMarker(
                point: LatLng(station.latitude!, station.longitude!),
                radius: destination?.id == station.id ? 10 : 5,
                color: destination?.id == station.id
                    ? const Color(0xFFFF6B35)
                    : station.hasLiveOccupancy &&
                            station.availableConnectors > 0
                        ? const Color(0xFF2EAD4B)
                        : station.hasLiveOccupancy
                            ? const Color(0xFFE53935)
                            : const Color(0xFF0066FF).withValues(alpha: 0.85),
                borderStrokeWidth: destination?.id == station.id ? 3 : 1,
                borderColor: Colors.white,
              ),
          ],
        ),
        if (_zoom >= pricePinMinZoom)
          MarkerLayer(
            markers: [
              for (final station in osmPins)
                if (station.tariffPinLabel != null)
                  Marker(
                    point: LatLng(station.latitude!, station.longitude!),
                    width: 56,
                    height: 22,
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          station.tariffPinLabel!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        if (_me != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_me!.latitude, _me!.longitude),
                width: 24,
                height: 24,
                child: const Icon(Icons.my_location, color: Color(0xFF00C48C)),
              ),
            ],
          ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution('© OpenStreetMap'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(filteredStationsProvider);
    final destination = ref.watch(destinationStationProvider);
    final limited = ref.watch(sessionProvider)?.limitedAccess == true;

    if (!limited &&
        widget.focusNearest &&
        _locateDone &&
        !_didCenterOnDevice &&
        stationsAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_didCenterOnDevice || !mounted) return;
        _didCenterOnDevice = true;
        _goToMyLocation(thenNearest: true);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          !_locateDone
              ? 'Finding you…'
              : stationsAsync.maybeWhen(
                  data: (stations) {
                    final n = _nearbyPins(stations).length;
                    return '${formatRadiusKm(radiusKmForZoom(_zoom))} ($n)';
                  },
                  orElse: () => 'Choose a station',
                ),
        ),
        actions: [
          if (!limited)
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => context.pushNamed('list'),
              tooltip: 'List View',
            ),
        ],
      ),
      body: !_locateDone
          ? const Center(child: CircularProgressIndicator())
          : stationsAsync.when(
        data: (stations) {
          final allPins = stations.where(hasCoordinates).toList();
          if (_useGoogleMap && _googleMap != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _refreshGoogleMarkers(allPins);
            });
          }
          final query = _searchController.text.trim();
          final showHits = query.length >= 2;
          return Stack(
            children: [
              _buildBasemap(allPins),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                      color: Colors.white,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 16,
                        ),
                        cursorColor: const Color(0xFF0066FF),
                        decoration: InputDecoration(
                          hintText: 'Search city, street, or station…',
                          hintStyle: const TextStyle(color: Color(0xFF3A3A3C)),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF111111),
                          ),
                          suffixIcon: query.isEmpty
                              ? IconButton(
                                  tooltip: 'Search',
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                    color: Color(0xFF111111),
                                  ),
                                  onPressed: () => _applySearch(allPins),
                                )
                              : IconButton(
                                  tooltip: 'Clear',
                                  icon: const Icon(
                                    Icons.close,
                                    color: Color(0xFF111111),
                                  ),
                                  onPressed: _clearSearch,
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onTapOutside: (_) => _dismissKeyboard(),
                        onChanged: (_) {
                          setState(() {
                            _searchHits = stationsMatchingQuery(
                              allPins,
                              _searchController.text,
                            );
                          });
                        },
                        onSubmitted: (_) => _applySearch(allPins),
                      ),
                    ),
                    if (showHits) ...[
                      const SizedBox(height: 6),
                      Material(
                        color: Colors.white,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: _searchHits.isEmpty
                              ? const ListTile(
                                  dense: true,
                                  title: Text('No stations match that search'),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _searchHits.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final station = _searchHits[index];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.ev_station,
                                        color: Color(0xFF0066FF),
                                      ),
                                      title: Text(
                                        station.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF111111),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        station.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF3A3A3C),
                                        ),
                                      ),
                                      onTap: () => _pickSearchHit(station),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (destination != null)
                _StationPeekCard(
                  key: ValueKey(destination.id),
                  station: destination,
                  distanceKm: _me == null
                      ? null
                      : distanceKm(
                          _me!.latitude,
                          _me!.longitude,
                          destination.latitude!,
                          destination.longitude!,
                        ),
                  onClose: _clearDestination,
                  onDetails: () => context.pushNamed(
                    'station-detail',
                    pathParameters: {'id': destination.id},
                  ),
                  onNavigate: () => _openDirections(destination),
                  onArrived: limited ? null : () => _reportArrival(destination),
                ),
              Positioned(
                right: 16,
                bottom: destination != null ? 168 : 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!showHits) ...[
                      const MapFilterRail(),
                      const SizedBox(height: 12),
                    ],
                    _MapZoomControls(
                      radiusLabel: formatRadiusKm(radiusKmForZoom(_zoom)),
                      canZoomIn: _zoom < nearbyMaxZoom - 0.05,
                      canZoomOut: _zoom > nearbyMinZoom + 0.05,
                      onZoomIn: () => _nudgeZoom(nearbyZoomStep),
                      onZoomOut: () => _nudgeZoom(-nearbyZoomStep),
                      showLocation: true,
                      showNearest: !limited,
                      onNearest: () => _goToMyLocation(thenNearest: true),
                      onMyLocation: () => _goToMyLocation(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(stationsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapZoomControls extends StatelessWidget {
  final String radiusLabel;
  final bool canZoomIn;
  final bool canZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final bool showLocation;
  final bool showNearest;
  final VoidCallback onNearest;
  final VoidCallback onMyLocation;

  const _MapZoomControls({
    required this.radiusLabel,
    required this.canZoomIn,
    required this.canZoomOut,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.showLocation,
    this.showNearest = true,
    required this.onNearest,
    required this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'zoom-in',
          tooltip: 'Zoom in',
          onPressed: canZoomIn ? onZoomIn : null,
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              radiusLabel,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        FloatingActionButton.small(
          heroTag: 'zoom-out',
          tooltip: 'Zoom out',
          onPressed: canZoomOut ? onZoomOut : null,
          child: const Icon(Icons.remove),
        ),
        if (showLocation) ...[
          const SizedBox(height: 12),
          if (showNearest) ...[
            FloatingActionButton.small(
              heroTag: 'nearest',
              backgroundColor: const Color(0xFF00C48C),
              onPressed: onNearest,
              tooltip: 'Nearest station',
              child: const Icon(Icons.near_me),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: 'me',
            onPressed: onMyLocation,
            tooltip: 'My location',
            child: const Icon(Icons.my_location),
          ),
        ],
      ],
    );
  }
}

class _StationPeekCard extends StatefulWidget {
  final Station station;
  final double? distanceKm;
  final VoidCallback onClose;
  final VoidCallback onDetails;
  final VoidCallback onNavigate;
  final VoidCallback? onArrived;

  const _StationPeekCard({
    super.key,
    required this.station,
    required this.distanceKm,
    required this.onClose,
    required this.onDetails,
    required this.onNavigate,
    this.onArrived,
  });

  @override
  State<_StationPeekCard> createState() => _StationPeekCardState();
}

class _StationPeekCardState extends State<_StationPeekCard> {
  double _drag = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy <= 0 && _drag <= 0) return;
    setState(() => _drag = (_drag + details.delta.dy).clamp(0, 280));
  }

  void _onDragEnd(DragEndDetails details) {
    final fling = details.primaryVelocity ?? 0;
    if (_drag > 56 || fling > 450) {
      widget.onClose();
      return;
    }
    setState(() => _drag = 0);
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: Offset(0, _drag),
        child: GestureDetector(
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: Material(
            color: Colors.white,
            elevation: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
              child: DefaultTextStyle(
                style: const TextStyle(color: Color(0xFF111111), fontSize: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: widget.onClose,
                          tooltip: 'Close',
                          icon: const Icon(Icons.close, color: Color(0xFF111111)),
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD0D7E2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    Text(
                      station.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF3A3A3C)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (station.countryCode != null)
                          _PeekChip(station.countryCode!),
                        if (station.operatorName != null)
                          _PeekChip(station.operatorName!),
                        if (station.hasLiveOccupancy)
                          _PeekChip(
                            '${station.availableConnectors}/${station.connectorCount} free',
                          )
                        else
                          _PeekChip('${station.connectorCount} connectors'),
                        if (station.tariff != null) _PeekChip(station.tariff!),
                        if (widget.distanceKm != null)
                          _PeekChip(
                            '${widget.distanceKm!.toStringAsFixed(1)} km',
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onDetails,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF111111),
                              side: const BorderSide(color: Color(0xFF111111)),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Details'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onNavigate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066FF),
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.directions, size: 18),
                            label: const Text('Go'),
                          ),
                        ),
                        if (widget.onArrived != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: "I've arrived",
                            onPressed: widget.onArrived,
                            icon: const Icon(Icons.flag_circle_outlined),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeekChip extends StatelessWidget {
  final String label;
  const _PeekChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6FF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF111111)),
      ),
    );
  }
}
