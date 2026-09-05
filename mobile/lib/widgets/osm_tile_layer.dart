import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Raster tiles that do not need a third-party key.
/// Carto Voyager now watermarks "API KEY REQUIRED" — do not use cartocdn.
class OsmTileLayer extends StatelessWidget {
  const OsmTileLayer({super.key});

  static const urlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: 'com.eniwhere.energy',
      maxNativeZoom: 19,
    );
  }
}
