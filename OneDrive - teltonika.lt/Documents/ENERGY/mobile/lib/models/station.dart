import 'connector.dart';

class Station {
  final String id;
  final String name;
  final String? operatorName;
  final String address;
  final double? latitude;
  final double? longitude;
  final bool isPublic;
  final int connectorCount;
  final int availableConnectors;

  Station({
    required this.id,
    required this.name,
    this.operatorName,
    required this.address,
    this.latitude,
    this.longitude,
    required this.isPublic,
    required this.connectorCount,
    required this.availableConnectors,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      operatorName: json['operator_name'] as String?,
      address: json['address'] as String,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      isPublic: json['is_public'] as bool? ?? true,
      connectorCount: json['connector_count'] as int? ?? 0,
      availableConnectors: json['available_connectors'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'operator_name': operatorName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_public': isPublic,
      'connector_count': connectorCount,
      'available_connectors': availableConnectors,
    };
  }
}

class StationDetail extends Station {
  final String? website;
  final String? phone;
  final String? openingHours;
  final List<Connector> connectors;

  StationDetail({
    required super.id,
    required super.name,
    super.operatorName,
    required super.address,
    super.latitude,
    super.longitude,
    required super.isPublic,
    required super.connectorCount,
    required super.availableConnectors,
    this.website,
    this.phone,
    this.openingHours,
    required this.connectors,
  });

  factory StationDetail.fromJson(Map<String, dynamic> json) {
    return StationDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      operatorName: json['operator_name'] as String?,
      address: json['address'] as String,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      isPublic: json['is_public'] as bool? ?? true,
      connectorCount: (json['connectors'] as List?)?.length ?? 0,
      availableConnectors:
          (json['connectors'] as List?)
              ?.where((c) => c['status'] == 'AVAILABLE')
              .length ??
          0,
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      openingHours: json['opening_hours'] as String?,
      connectors:
          (json['connectors'] as List<dynamic>?)
              ?.map((c) => Connector.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'website': website,
      'phone': phone,
      'opening_hours': openingHours,
      'connectors': connectors.map((c) => c.toJson()).toList(),
    };
  }
}
