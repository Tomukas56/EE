import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/map_provider.dart';

/// Dynamic tile layer based on selected map provider.
class MapTileLayer extends StatelessWidget {
  final MapProvider provider;

  const MapTileLayer({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    String urlTemplate;
    int maxNativeZoom;

    switch (provider) {
      case MapProvider.googleMaps:
        // Google Maps tiles via flutter_map (fallback for non-Google SDK)
        urlTemplate = 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
        maxNativeZoom = 20;
        break;
      case MapProvider.mapbox:
        // Mapbox requires API key in URL - placeholder for now
        urlTemplate =
            'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=YOUR_MAPBOX_TOKEN';
        maxNativeZoom = 19;
        break;
      case MapProvider.mapTiler:
        // MapTiler Basic style - requires API key
        urlTemplate =
            'https://api.maptiler.com/maps/basic/256/{z}/{x}/{y}.png?key=YOUR_MAPTILER_KEY';
        maxNativeZoom = 19;
        break;
      case MapProvider.openStreetMap:
      default:
        // OSM default
        urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
        maxNativeZoom = 19;
        break;
    }

    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: 'com.eniwhere.energy',
      maxNativeZoom: maxNativeZoom,
    );
  }
}
