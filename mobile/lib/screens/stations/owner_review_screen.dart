import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../providers/stations_provider.dart';
import '../../services/api_service.dart';

class OwnerReviewScreen extends ConsumerStatefulWidget {
  const OwnerReviewScreen({super.key});

  @override
  ConsumerState<OwnerReviewScreen> createState() => _OwnerReviewScreenState();
}

class _OwnerReviewScreenState extends ConsumerState<OwnerReviewScreen> {
  static const _pinKey = 'ee.owner.pin';
  final _pin = TextEditingController();
  String? _savedPin;
  List<Map<String, dynamic>> _rows = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final pin = prefs.getString(_pinKey);
      if (!mounted) return;
      if (pin != null && pin.isNotEmpty) {
        setState(() => _savedPin = pin);
        _load(pin);
      }
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final pin = _pin.text.trim();
    if (pin.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await ref.read(apiServiceProvider).listSubmissions(pin);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, pin);
      if (!mounted) return;
      setState(() {
        _savedPin = pin;
        _rows = rows;
      });
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load(String pin) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await ref.read(apiServiceProvider).listSubmissions(pin);
      if (!mounted) return;
      setState(() => _rows = rows);
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm(String id) async {
    final pin = _savedPin;
    if (pin == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiServiceProvider).confirmSubmission(pin, id);
      ref.invalidate(stationsProvider);
      await _load(pin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location confirmed. Station is on the map.')),
      );
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(String id) async {
    final pin = _savedPin;
    if (pin == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiServiceProvider).rejectSubmission(pin, id);
      await _load(pin);
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner review')),
      body: _savedPin == null ? _pinGate() : _inbox(),
    );
  }

  Widget _pinGate() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Only the app owner can confirm a physical location. Enter the owner PIN.',
            style: TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Owner PIN',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _unlock(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFFF3B30))),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : _unlock,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_busy ? 'Checking…' : 'Unlock'),
          ),
        ],
      ),
    );
  }

  Widget _inbox() {
    if (_busy && _rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rows.isEmpty) {
      return Center(
        child: Text(_error ?? 'No pending stations.'),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(_savedPin!),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final row = _rows[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row['name'] as String? ?? 'Station',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(row['address'] as String? ?? ''),
                  if (row['operator_name'] != null)
                    Text('Operator: ${row['operator_name']}'),
                  if (row['connector_note'] != null)
                    Text('Connectors: ${row['connector_note']}'),
                  Text(
                    '${row['latitude']}, ${row['longitude']}',
                    style: const TextStyle(color: Color(0xFF3A3A3C), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _reject(row['id'] as String),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _busy
                              ? null
                              : () => _confirm(row['id'] as String),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C48C),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Confirm location'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
