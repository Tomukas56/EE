/// Service rules shown on the sign-in screen. Edit here when the legal text changes.
class ServiceAgreement {
  static const title = 'Agreement';
  static const subtitle = 'Rules under which we provide the service';

  static const sections = <({String heading, String body})>[
    (
      heading: '1. Who we are',
      body:
          'Energy Eniwhere (EE) is an electric-vehicle charging aggregator. We are not a charge-point operator (CPO) and we do not own or run charging hardware. The app helps you find stations in Lithuania, plan trips with charging stops, and (when enabled) start a session and pay in one place.',
    ),
    (
      heading: '2. Scope of the service',
      body:
          'We currently provide station search on the map and in a list, nearest-column search using device location, a vehicle profile, and a trip sketch. Session control, live occupancy, and payments will be rolled out over time. Features marked as upcoming are not guaranteed.',
    ),
    (
      heading: '3. Account',
      body:
          'You must sign in with a Google account (Android or iPhone) to use the app. You are responsible for keeping that account secure. Using someone else’s account or bypassing sign-in is not allowed.',
    ),
    (
      heading: '4. Data and location',
      body:
          'We use your Google account id, name, email, and photo for the session. Location permission is used only to show nearby stations — you may refuse it, in which case nearest-column will not work. Station data comes from public and partner sources (including Open Charge Map) and may be incomplete.',
    ),
    (
      heading: '5. Stations, price, and occupancy',
      body:
          'We show location, connector types, and other static information. Occupancy and price may not match what you find on site. Check the operator’s terms before you drive. EE is not liable for a column that is occupied, out of order, or otherwise unavailable.',
    ),
    (
      heading: '6. Payments and charging',
      body:
          'When payments are enabled, energy price and fees depend on the station operator. EE may charge a service fee if it is shown to you before the session. Disputes about kWh and price should be raised with the operator first.',
    ),
    (
      heading: '7. Your obligations',
      body:
          'Use the app lawfully, do not damage stations or inconvenience other drivers, and do not occupy a bay longer than needed. Incorrect vehicle data (connector, battery, range) can produce a wrong route — that is your responsibility.',
    ),
    (
      heading: '8. Limits of liability',
      body:
          'The service is provided “as is”. EE is not liable for loss caused by incorrect map data, GPS error, network failure, or an operator’s fault. This does not affect rights that cannot be limited under Lithuanian and EU consumer law.',
    ),
    (
      heading: '9. Crowd reports',
      body:
          'You may mark a station that is missing from the map. It is published only after the app owner confirms the physical location. When you arrive, the app may ask whether the station is working and whether connectors are free. Answers are Yes, No, or Dismiss. Reports are user observations, not live operator data.',
    ),
    (
      heading: '10. Standards we follow',
      body:
          'EE designs and operates the service to the standards listed in the Product Requirements Document (docs/PRD.md), in particular: GDPR / Lithuanian BDAR for personal data; the ePrivacy rules for location and device identifiers; PSD2 Strong Customer Authentication and PCI DSS (via a licensed payment provider) when payments are enabled; OWASP MASVS / Mobile Top 10 for the mobile app; TLS for data in transit; Google and Apple store and identity policies; and OCPI security controls when we connect to charge-point operators. We do not claim a completed formal certification (ISO 27001, PCI ROC, or similar) until an independent audit has been completed. Where a control is not yet implemented, the PRD gap table is the honest status.',
    ),
    (
      heading: '11. Third-party services',
      body:
          'The app uses independent third-party services. They process data under their own terms, which you should also read. Current processors and sources include: Google Sign-In and Firebase (account); Google Maps Platform (map and navigation); Open Charge Map (public station locations); the device operating system (location, network); and, when payments are enabled, Stripe and the phone wallet (Apple Pay / Google Pay) so that card numbers are not stored in the EE app. Station operators (CPOs) remain responsible for the column, energy, and their own prices. EE is not those operators and is not those platforms.',
    ),
    (
      heading: '12. Changes',
      body:
          'We may update these rules. The new version will appear on this screen. Continuing to use the app after an update means you accept the new edition.',
    ),
    (
      heading: '13. Contact',
      body:
          'Questions about the service and this agreement: Energy Eniwhere, Lithuania. By continuing with Google you confirm that you have read this Agreement and the README.',
    ),
  ];
}
