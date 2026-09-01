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
import '../widgets/country_filter_bar.dart';
import '../widgets/station_filter_bar.dart';

class MapScreen extends ConsumerStatefulWidget {
  final bool focusNearest;

  const MapScreen({super.key, this.focusNearest = false});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_locateOnOpen);
    if (AppConfig.useGoogleMaps) {
      Future<void>.delayed(const Duration(seconds: 6), () {
        if (!mounted || _googleMap != null) return;
        setState(() => _useGoogleMap = false);
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
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

  void _applySearch(List<Station> stations) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return;
    final match = stations.where(hasCoordinates).where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.address.toLowerCase().contains(q) ||
          (s.operatorName?.toLowerCase().contains(q) ?? false);
    }).firstOrNull;
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No station matched that search')),
      );
      return;
    }
    _selectStation(match);
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
    final next = <gmaps.Marker>{
      for (final station in visible)
        gmaps.Marker(
          markerId: gmaps.MarkerId(station.id),
          position: gmaps.LatLng(station.latitude!, station.longitude!),
          infoWindow: const gmaps.InfoWindow(),
          consumeTapEvents: true,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            selected?.id == station.id
                ? gmaps.BitmapDescriptor.hueOrange
                : gmaps.BitmapDescriptor.hueAzure,
          ),
          onTap: () => _selectStation(station, moveCamera: false),
        ),
    };
    final sameIds = next.length == _markers.length &&
        next.every((marker) => _markers.any((m) => m.markerId == marker.markerId && m.icon == marker.icon));
    if (sameIds) return;
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
      return gmaps.GoogleMap(
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
        onTap: (latLng) => _selectNearestTo(
          latLng.latitude,
          latLng.longitude,
          pins,
        ),
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
        onTap: (tap, latlng) => _selectNearestTo(
          latlng.latitude,
          latlng.longitude,
          pins,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          userAgentPackageName: 'lt.energyeniwhere.mobile',
          retinaMode: true,
        ),
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
                    : const Color(0xFF0066FF).withValues(alpha: 0.85),
                borderStrokeWidth: destination?.id == station.id ? 3 : 1,
                borderColor: Colors.white,
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
            TextSourceAttribution('© OpenStreetMap, © CARTO'),
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
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 16,
                        ),
                        cursorColor: const Color(0xFF0066FF),
                        decoration: InputDecoration(
                          hintText: 'Search station or address…',
                          hintStyle: const TextStyle(color: Color(0xFF3A3A3C)),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF111111),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF111111),
                            ),
                            onPressed: () => _applySearch(allPins),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onSubmitted: (_) => _applySearch(allPins),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CountryFilterBar(compact: true),
                              SizedBox(height: 6),
                              StationFilterBar(compact: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MapZoomControls(
                          radiusLabel: formatRadiusKm(radiusKmForZoom(_zoom)),
                          canZoomIn: _zoom < nearbyMaxZoom - 0.05,
                          canZoomOut: _zoom > nearbyMinZoom + 0.05,
                          onZoomIn: () => _nudgeZoom(nearbyZoomStep),
                          onZoomOut: () => _nudgeZoom(-nearbyZoomStep),
                          showLocation: false,
                          onNearest: () {},
                          onMyLocation: () {},
                        ),
                      ],
                    ),
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
                child: _MapZoomControls(
                  radiusLabel: formatRadiusKm(radiusKmForZoom(_zoom)),
                  canZoomIn: _zoom < nearbyMaxZoom - 0.05,
                  canZoomOut: _zoom > nearbyMinZoom + 0.05,
                  onZoomIn: () => _nudgeZoom(nearbyZoomStep),
                  onZoomOut: () => _nudgeZoom(-nearbyZoomStep),
                  showLocation: destination == null,
                  zoomButtons: false,
                  showNearest: !limited,
                  onNearest: () => _goToMyLocation(thenNearest: true),
                  onMyLocation: () => _goToMyLocation(),
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
  final bool zoomButtons;
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
    this.zoomButtons = true,
    this.showNearest = true,
    required this.onNearest,
    required this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (zoomButtons) ...[
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
        ],
        if (showLocation) ...[
          if (zoomButtons) const SizedBox(height: 12),
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
                        _PeekChip('${station.connectorCount} connectors'),
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
