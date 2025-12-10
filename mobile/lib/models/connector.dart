enum ConnectorType {
  CCS,
  CHAdeMO,
  TYPE2,
  TYPE1;

  static ConnectorType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CCS':
        return ConnectorType.CCS;
      case 'CHADEMO':
        return ConnectorType.CHAdeMO;
      case 'TYPE2':
        return ConnectorType.TYPE2;
      case 'TYPE1':
        return ConnectorType.TYPE1;
      default:
        return ConnectorType.TYPE2;
    }
  }

  String get displayName {
    switch (this) {
      case ConnectorType.CCS:
        return 'CCS';
      case ConnectorType.CHAdeMO:
        return 'CHAdeMO';
      case ConnectorType.TYPE2:
        return 'Type 2';
      case ConnectorType.TYPE1:
        return 'Type 1';
    }
  }
}

enum ConnectorStatus {
  AVAILABLE,
  OCCUPIED,
  CHARGING,
  OUTOFORDER,
  UNKNOWN;

  static ConnectorStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'AVAILABLE':
        return ConnectorStatus.AVAILABLE;
      case 'OCCUPIED':
        return ConnectorStatus.OCCUPIED;
      case 'CHARGING':
        return ConnectorStatus.CHARGING;
      case 'OUTOFORDER':
        return ConnectorStatus.OUTOFORDER;
      default:
        return ConnectorStatus.UNKNOWN;
    }
  }

  String get displayName {
    switch (this) {
      case ConnectorStatus.AVAILABLE:
        return 'Available';
      case ConnectorStatus.OCCUPIED:
        return 'Occupied';
      case ConnectorStatus.CHARGING:
        return 'Charging';
      case ConnectorStatus.OUTOFORDER:
        return 'Out of Order';
      case ConnectorStatus.UNKNOWN:
        return 'Unknown';
    }
  }
}

class Connector {
  final String id;
  final String evseId;
  final ConnectorType type;
  final double maxPowerKw;
  final ConnectorStatus status;
  final String? tariff;

  Connector({
    required this.id,
    required this.evseId,
    required this.type,
    required this.maxPowerKw,
    required this.status,
    this.tariff,
  });

  factory Connector.fromJson(Map<String, dynamic> json) {
    return Connector(
      id: json['id'] as String,
      evseId: json['evse_id'] as String,
      type: ConnectorType.fromString(json['type'] as String),
      maxPowerKw: (json['max_power_kw'] as num).toDouble(),
      status: ConnectorStatus.fromString(json['status'] as String),
      tariff: json['tariff'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'evse_id': evseId,
      'type': type.name,
      'max_power_kw': maxPowerKw,
      'status': status.name,
      'tariff': tariff,
    };
  }
}
