/// Processors and sources linked from Terms and Privacy (open in the browser).
class ThirdPartyService {
  const ThirdPartyService({
    required this.name,
    required this.role,
    required this.termsUrl,
    required this.privacyUrl,
  });

  final String name;
  final String role;
  final String termsUrl;
  final String privacyUrl;
}

class ThirdPartyServices {
  static const title = 'Third-party services';
  static const subtitle = 'Independent platforms the app talks to';

  static const intro =
      'Energy Eniwhere uses these services. They are not EE. Read their terms and privacy notices. '
      'EE does not control how they process data once you use map tiles, Google Sign-In, or a trip geocoder.';

  static const items = <ThirdPartyService>[
    ThirdPartyService(
      name: 'Google Sign-In / Firebase Authentication',
      role: 'Account (id, name, email, photo). Required to open the app after you accept the terms.',
      termsUrl: 'https://firebase.google.com/terms',
      privacyUrl: 'https://policies.google.com/privacy',
    ),
    ThirdPartyService(
      name: 'Google Maps Platform',
      role: 'Map tiles, pins, and (when the key allows) Directions for trip distance.',
      termsUrl: 'https://cloud.google.com/maps-platform/terms',
      privacyUrl: 'https://policies.google.com/privacy',
    ),
    ThirdPartyService(
      name: 'Open Charge Map',
      role: 'Public charging-station locations for LT, LV, EE, PL. Occupancy is not live.',
      termsUrl: 'https://openchargemap.org/site/about/terms',
      privacyUrl: 'https://openchargemap.org/site/about/privacy',
    ),
    ThirdPartyService(
      name: 'OpenStreetMap Nominatim',
      role: 'Trip geocoding fallback if Google Directions is unavailable.',
      termsUrl: 'https://operations.osmfoundation.org/policies/nominatim/',
      privacyUrl: 'https://wiki.osmfoundation.org/wiki/Privacy_Policy',
    ),
    ThirdPartyService(
      name: 'Device operating system',
      role: 'Location permission, network, and (later) wallet sheets. You control this in system settings.',
      termsUrl: 'https://www.google.com/intl/en/policies/terms/',
      privacyUrl: 'https://policies.google.com/privacy',
    ),
    ThirdPartyService(
      name: 'Stripe (not live in this build)',
      role: 'Future card / wallet payments. No PAN in the EE app. Secret key is empty in the lab.',
      termsUrl: 'https://stripe.com/legal/ssa',
      privacyUrl: 'https://stripe.com/privacy',
    ),
  ];
}
