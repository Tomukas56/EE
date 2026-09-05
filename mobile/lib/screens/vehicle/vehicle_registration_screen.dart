import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';

class VehicleRegistrationScreen extends ConsumerStatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  ConsumerState<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState
    extends ConsumerState<VehicleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _capacityController = TextEditingController();
  final _rangeController = TextEditingController();
  String _selectedConnector = 'CCS2';
  bool _hydrated = false;
  bool _showForm = true;

  final List<String> _connectorTypes = ['CCS2', 'Type 2', 'CHAdeMO', 'Tesla'];

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _capacityController.dispose();
    _rangeController.dispose();
    super.dispose();
  }

  void _fill(Vehicle saved) {
    _makeController.text = saved.make;
    _modelController.text = saved.model;
    _capacityController.text = saved.batteryCapacityKWh.toStringAsFixed(0);
    _rangeController.text = saved.maxRangeKm.toStringAsFixed(0);
    if (_connectorTypes.contains(saved.connectorType)) {
      _selectedConnector = saved.connectorType;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final vehicle = Vehicle(
      id: 'v1',
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      batteryCapacityKWh: double.parse(_capacityController.text),
      maxRangeKm: double.parse(_rangeController.text),
      connectorType: _selectedConnector,
    );
    await ref.read(vehicleProvider.notifier).save(vehicle);
    if (!mounted) return;
    setState(() => _showForm = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${vehicle.label} is active on this device'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(vehicleProvider);
    if (!_hydrated && saved != null) {
      _hydrated = true;
      _showForm = false;
      _fill(saved);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Setup'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your EV',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                saved == null
                    ? 'Saved on this device. Trip range, energy and plug stops use this car.'
                    : 'Trip planner and charging stops use this active vehicle.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (saved != null) ...[
                const SizedBox(height: 20),
                _ActiveVehicleCard(vehicle: saved),
              ],
              if (_showForm) ...[
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _makeController,
                        decoration: const InputDecoration(
                          labelText: 'Make',
                          hintText: 'e.g. Tesla, Nissan',
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter make'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          hintText: 'e.g. Model 3, Leaf',
                          prefixIcon: Icon(Icons.model_training),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter model'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Battery Capacity (kWh)',
                          hintText: 'e.g. 75',
                          prefixIcon: Icon(Icons.battery_charging_full),
                          suffixText: 'kWh',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _rangeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Range (WLTP)',
                          hintText: 'e.g. 500',
                          prefixIcon: Icon(Icons.map),
                          suffixText: 'km',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedConnector,
                        decoration: const InputDecoration(
                          labelText: 'Connector Type',
                          prefixIcon: Icon(Icons.electrical_services),
                        ),
                        items: _connectorTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedConnector = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Save & Continue'),
                      ),
                    ],
                  ),
                ),
              ] else if (saved != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => setState(() => _showForm = true),
                  child: const Text('Edit vehicle'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.goNamed('home'),
                  child: const Text('Continue'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveVehicleCard extends StatelessWidget {
  const _ActiveVehicleCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.successGreen, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: AppColors.successGreen, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vehicle.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.specsLine,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Used for trip range, energy (kWh) and compatible charging stops.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
