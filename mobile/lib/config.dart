import 'package:flutter/foundation.dart';

/// Backend URL. Override at run time:
/// `flutter run --dart-define=API_BASE=http://192.168.1.228:3000`
///
/// Defaults: Chrome → localhost; physical Android (tablet/phone) → this Mac's
/// LAN IP (same Wi‑Fi). Android emulator would need `10.0.2.2` via API_BASE.
class AppConfig {
  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyBIRsy06b1BVuurVK09ZYVikw43HgDF4s0',
  );

  /// Google Maps when a Cloud Maps key is present (default key or dart-define).
  static bool get useGoogleMaps => googleMapsApiKey.isNotEmpty;

  static const _fromDefine = String.fromEnvironment('API_BASE');

  /// Host machine on this LAN — used by a USB-connected tablet/phone.
  static const lanApi = 'http://192.168.1.228:3000';

  static String get apiBase {
    if (_fromDefine.isNotEmpty) return _fromDefine;
    if (kIsWeb) return 'http://localhost:3000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return lanApi;
      default:
        return 'http://localhost:3000';
    }
  }
}
