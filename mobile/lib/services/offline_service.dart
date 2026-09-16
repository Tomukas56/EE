import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/station.dart';
import 'api_service.dart';

/// Offline station cache. Stores downloaded regional data in local SQLite.
/// PRD §2.7: Manual download only, no auto-refresh, unencrypted (public data).
class OfflineService {
  Database? _db;
  final ApiService _apiService;

  OfflineService(this._apiService);

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'offline_stations.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_station (
            id TEXT PRIMARY KEY,
            external_id TEXT,
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            country_code TEXT,
            operator_name TEXT,
            max_power_kw REAL,
            tariff_eur REAL,
            available_connectors INTEGER,
            total_connectors INTEGER,
            has_live_occupancy INTEGER,
            source TEXT,
            last_synced_at TEXT,
            synced_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_connector (
            id TEXT PRIMARY KEY,
            station_id TEXT NOT NULL,
            connector_type TEXT NOT NULL,
            power_kw REAL,
            FOREIGN KEY (station_id) REFERENCES cached_station(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_metadata (
            country_code TEXT PRIMARY KEY,
            synced_at TEXT NOT NULL,
            station_count INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  /// Download and cache stations for a region.
  Future<void> downloadCountry(String countryCode) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();

    // Fetch from API
    final stations = await _apiService.getStations(
      country: countryCode == 'ALL' ? null : countryCode,
      limit: 99999,
    );

    await db.transaction((txn) async {
      // Delete old data for this country
      if (countryCode == 'ALL') {
        await txn.delete('cached_station');
        await txn.delete('cached_connector');
        await txn.delete('sync_metadata');
      } else {
        await txn.delete(
          'cached_station',
          where: 'country_code = ?',
          whereArgs: [countryCode],
        );
        await txn.delete('sync_metadata',
            where: 'country_code = ?', whereArgs: [countryCode]);
      }

      // Insert stations
      for (final station in stations) {
        await txn.insert('cached_station', {
          'id': station.id,
          'external_id': null,
          'name': station.name,
          'address': station.address,
          'latitude': station.latitude,
          'longitude': station.longitude,
          'country_code': station.countryCode,
          'operator_name': station.operatorName,
          'max_power_kw': station.maxPowerKw,
          'tariff_eur': station.tariffEur,
          'available_connectors': station.availableConnectors,
          'total_connectors': station.connectorCount,
          'has_live_occupancy': station.hasLiveOccupancy ? 1 : 0,
          'source': station.source,
          'last_synced_at': station.lastSyncedAt?.toIso8601String(),
          'synced_at': now,
        });

        for (final type in station.connectorTypes) {
          await txn.insert('cached_connector', {
            'id': '${station.id}_$type',
            'station_id': station.id,
            'connector_type': type,
            'power_kw': station.maxPowerKw,
          });
        }
      }

      // Update metadata
      await txn.insert(
        'sync_metadata',
        {
          'country_code': countryCode,
          'synced_at': now,
          'station_count': stations.length,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// Load cached stations for a country (or all).
  Future<List<Station>> getCachedStations([String? countryCode]) async {
    final db = await database;
    final where = countryCode == null || countryCode == 'ALL'
        ? null
        : 'country_code = ?';
    final whereArgs = where == null ? null : [countryCode];

    final rows = await db.query(
      'cached_station',
      where: where,
      whereArgs: whereArgs,
    );

    final stations = <Station>[];
    for (final row in rows) {
      final connectorRows = await db.query(
        'cached_connector',
        where: 'station_id = ?',
        whereArgs: [row['id']],
      );
      final types =
          connectorRows.map((r) => r['connector_type'] as String).toList();

      final tariffEur = (row['tariff_eur'] as num?)?.toDouble();
      stations.add(Station(
        id: row['id'] as String,
        name: row['name'] as String,
        address: row['address'] as String,
        latitude: row['latitude'] as double,
        longitude: row['longitude'] as double,
        countryCode: row['country_code'] as String?,
        operatorName: row['operator_name'] as String?,
        isPublic: true,
        connectorCount: (row['total_connectors'] as int?) ?? types.length,
        availableConnectors: (row['available_connectors'] as int?) ?? 0,
        connectorTypes: types,
        maxPowerKw: (row['max_power_kw'] as num?)?.toDouble() ?? 0,
        tariff: tariffEur != null ? '€${tariffEur.toStringAsFixed(2)}/kWh' : null,
        source: row['source'] as String?,
        lastSyncedAt: row['last_synced_at'] != null
            ? DateTime.tryParse(row['last_synced_at'] as String)
            : null,
      ));
    }

    return stations;
  }

  /// Check if a country has cached data.
  Future<SyncMetadata?> getSyncMetadata(String countryCode) async {
    final db = await database;
    final rows = await db.query(
      'sync_metadata',
      where: 'country_code = ?',
      whereArgs: [countryCode],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return SyncMetadata(
      countryCode: row['country_code'] as String,
      syncedAt: DateTime.parse(row['synced_at'] as String),
      stationCount: row['station_count'] as int,
    );
  }

  /// Get all downloaded regions.
  Future<List<SyncMetadata>> getAllSyncMetadata() async {
    final db = await database;
    final rows = await db.query('sync_metadata');
    return rows.map((row) {
      return SyncMetadata(
        countryCode: row['country_code'] as String,
        syncedAt: DateTime.parse(row['synced_at'] as String),
        stationCount: row['station_count'] as int,
      );
    }).toList();
  }

  /// Delete cached data for a country.
  Future<void> deleteCountry(String countryCode) async {
    final db = await database;
    await db.transaction((txn) async {
      if (countryCode == 'ALL') {
        await txn.delete('cached_station');
        await txn.delete('cached_connector');
        await txn.delete('sync_metadata');
      } else {
        await txn.delete(
          'cached_station',
          where: 'country_code = ?',
          whereArgs: [countryCode],
        );
        await txn.delete(
          'sync_metadata',
          where: 'country_code = ?',
          whereArgs: [countryCode],
        );
      }
    });
  }

  /// Clear all cached data (for testing / full reset).
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('cached_station');
    await db.delete('cached_connector');
    await db.delete('sync_metadata');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

class SyncMetadata {
  final String countryCode;
  final DateTime syncedAt;
  final int stationCount;

  SyncMetadata({
    required this.countryCode,
    required this.syncedAt,
    required this.stationCount,
  });

  Duration get age => DateTime.now().toUtc().difference(syncedAt);
  bool get isStale => age.inHours > 24;
  bool get needsRefreshWarning => age.inDays >= 7;
}
