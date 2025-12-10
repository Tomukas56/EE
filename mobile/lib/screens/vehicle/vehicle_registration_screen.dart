import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/vehicle.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _capacityController = TextEditingController();
  final _rangeController = TextEditingController();
  String _selectedConnector = 'CCS2';

  final List<String> _connectorTypes = ['CCS2', 'Type 2', 'CHAdeMO', 'Tesla'];

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _capacityController.dispose();
    _rangeController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Create vehicle object (Mock save)
      final vehicle = Vehicle(
        id: 'v1',
        make: _makeController.text,
        model: _modelController.text,
        batteryCapacityKWh: double.parse(_capacityController.text),
        maxRangeKm: double.parse(_rangeController.text),
        connectorType: _selectedConnector,
      );

      // Show success and navigate to Home
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle ${vehicle.make} ${vehicle.model} saved!'),
          backgroundColor: AppColors.successGreen,
        ),
      );

      // Navigate to Home after delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) context.goNamed('home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Setup'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Your EV',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'To calculate smart routes, we need your car details.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Make
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

                // Model
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

                // Battery Capacity
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
                    if (double.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Max Range
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
                    if (double.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Connector Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedConnector,
                  decoration: const InputDecoration(
                    labelText: 'Connector Type',
                    prefixIcon: Icon(Icons.electrical_services),
                  ),
                  items: _connectorTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedConnector = value!;
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Save & Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
