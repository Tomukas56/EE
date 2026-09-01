class ChargingSession {
  final String id;
  final String stationId;
  final String stationName;
  final String connectorType;
  final DateTime startTime;
  final DateTime? endTime;
  final double energyKwh;
  final double costEur;
  final String status; // charging | completed
  final String paymentMethod;

  ChargingSession({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.connectorType,
    required this.startTime,
    this.endTime,
    required this.energyKwh,
    required this.costEur,
    required this.status,
    this.paymentMethod = '',
  });

  bool get isOpen => status == 'charging';

  factory ChargingSession.fromJson(Map<String, dynamic> json) {
    return ChargingSession(
      id: json['id'] as String? ?? '',
      stationId: json['station_id'] as String? ?? '',
      stationName: json['station_name'] as String? ?? '',
      connectorType: json['connector_type'] as String? ?? 'TYPE2',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      energyKwh: (json['energy_kwh'] as num?)?.toDouble() ?? 0,
      costEur: (json['cost_eur'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'charging',
      paymentMethod: json['payment_method'] as String? ?? '',
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get formattedDuration {
    final dur = duration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
