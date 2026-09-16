/// Available map tile providers for the app.
enum MapProvider {
  googleMaps('Google Maps', 'High quality, requires API key'),
  openStreetMap('OpenStreetMap', 'Free, community-driven, no key needed'),
  mapbox('Mapbox', 'Modern styles, requires free API key'),
  mapTiler('MapTiler', 'OSM-based with custom styles');

  const MapProvider(this.label, this.description);

  final String label;
  final String description;

  /// User-friendly display text.
  String get displayName => label;

  /// Short explanation for settings screen.
  String get info => description;

  /// Whether this provider requires an API key to function.
  bool get requiresApiKey => this != openStreetMap;
}
