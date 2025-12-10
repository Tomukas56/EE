class ChargingSession {
  final String id;
  final String stationId;
  final String stationName;
  final String connectorType;
  final DateTime startTime;
  final DateTime? endTime;
  final double energyKwh;
  final double costEur;
  final String status; // 'active', 'completed', 'failed'

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
  });

  factory ChargingSession.fromJson(Map<String, dynamic> json) {
    return ChargingSession(
      id: json['id'],
      stationId: json['station_id'],
      stationName: json['station_name'],
      connectorType: json['connector_type'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      energyKwh: (json['energy_kwh'] as num).toDouble(),
      costEur: (json['cost_eur'] as num).toDouble(),
      status: json['status'],
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
