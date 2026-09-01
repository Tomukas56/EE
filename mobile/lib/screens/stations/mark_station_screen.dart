import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../config.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stations_provider.dart';
import '../../services/api_service.dart';
import '../../utils/geo.dart';

/// Driver marks a new charging station. It stays off the map until the owner confirms.
class MarkStationScreen extends ConsumerStatefulWidget {
  const MarkStationScreen({super.key});

  @override
  ConsumerState<MarkStationScreen> createState() => _MarkStationScreenState();
}

class _MarkStationScreenState extends ConsumerState<MarkStationScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _operator = TextEditingController();
  final _connectors = TextEditingController();
  gmaps.LatLng _pin = const gmaps.LatLng(vilniusLat, vilniusLng);
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(locationServiceProvider).getCurrentPosition().then((position) {
      if (!mounted) return;
      setState(() {
        _pin = gmaps.LatLng(position.latitude, position.longitude);
      });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _operator.dispose();
    _connectors.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      setState(() => _error = 'Name and address are required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = ref.read(sessionProvider);
      await ref.read(apiServiceProvider).submitStation(
            name: _name.text.trim(),
            address: _address.text.trim(),
            operatorName: _operator.text.trim().isEmpty
                ? null
                : _operator.text.trim(),
            latitude: _pin.latitude,
            longitude: _pin.longitude,
            connectorNote: _connectors.text.trim().isEmpty
                ? null
                : _connectors.text.trim(),
            submittedBy: user?.id ?? user?.email ?? 'device',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Saved. It will appear on the map after the app owner confirms the physical location.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark a new station')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Drop a pin on the physical column. The station is hidden from the map until the app owner confirms that location.',
            style: TextStyle(fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AppConfig.useGoogleMaps
                  ? gmaps.GoogleMap(
                      initialCameraPosition: gmaps.CameraPosition(
                        target: _pin,
                        zoom: 16,
                      ),
                      markers: {
                        gmaps.Marker(
                          markerId: const gmaps.MarkerId('new'),
                          position: _pin,
                          draggable: true,
                          onDragEnd: (value) => setState(() => _pin = value),
                        ),
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      onTap: (value) => setState(() => _pin = value),
                    )
                  : Container(
                      color: const Color(0xFFE8E8ED),
                      alignment: Alignment.center,
                      child: Text(
                        '${_pin.latitude.toStringAsFixed(5)}, ${_pin.longitude.toStringAsFixed(5)}',
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_pin.latitude.toStringAsFixed(6)}, ${_pin.longitude.toStringAsFixed(6)}',
            style: const TextStyle(color: Color(0xFF3A3A3C), fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Station name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _operator,
            decoration: const InputDecoration(
              labelText: 'Operator (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _connectors,
            decoration: const InputDecoration(
              labelText: 'Connectors (e.g. CCS2 150 kW, Type 2)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFFF3B30))),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(_busy ? 'Sending…' : 'Submit for owner confirmation'),
          ),
        ],
      ),
    );
  }
}
