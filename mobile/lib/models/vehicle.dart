class Vehicle {
  final String id;
  final String make;
  final String model;
  final double batteryCapacityKWh;
  final double maxRangeKm;
  final String connectorType;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.batteryCapacityKWh,
    required this.maxRangeKm,
    required this.connectorType,
  });
}
