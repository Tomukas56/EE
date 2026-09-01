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

  String get label => '$make $model';

  String get filterType {
    switch (connectorType) {
      case 'CCS2':
      case 'CCS':
        return 'CCS';
      case 'CHAdeMO':
        return 'CHAdeMO';
      case 'Tesla':
        return 'CCS';
      default:
        return 'TYPE2';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'make': make,
        'model': model,
        'batteryCapacityKWh': batteryCapacityKWh,
        'maxRangeKm': maxRangeKm,
        'connectorType': connectorType,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String? ?? 'v1',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      batteryCapacityKWh: (json['batteryCapacityKWh'] as num?)?.toDouble() ?? 0,
      maxRangeKm: (json['maxRangeKm'] as num?)?.toDouble() ?? 0,
      connectorType: json['connectorType'] as String? ?? 'CCS2',
    );
  }
}
