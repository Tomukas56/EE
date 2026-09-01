/// Terms of use shown on welcome and under Account → Legal.
class ServiceAgreement {
  static const title = 'Terms of use';
  static const subtitle = 'Rules for using the Energy Eniwhere app';

  static const sections = <({String heading, String body})>[
    (
      heading: '1. Who we are',
      body:
          'Energy Eniwhere (EE) is an electric-vehicle charging aggregator based in Lithuania. '
          'We are not a charge-point operator (CPO) and we do not own or run charging hardware. '
          'The app helps you find stations in Lithuania, Latvia, Estonia, and Poland, plan a trip with charging, '
          'mark missing sites, and (in this lab build) record a local session estimate.',
    ),
    (
      heading: '2. What the app does now',
      body:
          'Station search on the map and in a list, nearest search if you allow location, a vehicle profile on this device, '
          'a trip sketch (Google Directions or Nominatim), crowd marking of missing stations (published only after the owner confirms), '
          'arrival Yes/No/Dismiss, and a laboratory start/stop session (time × station kW × €0.32/kWh). '
          'Live occupancy, operator start of charge, and Stripe payments are not enabled. Features marked upcoming are not guaranteed.',
    ),
    (
      heading: '3. Account and eligibility',
      body:
          'You must accept these Terms, the Privacy notice, and the README, then sign in with Google. '
          'You must be old enough to drive / use a charging service in your country. '
          'Keep your Google account secure. Do not use someone else’s account, scrape the API, or bypass sign-in in a store build.',
    ),
    (
      heading: '4. Your obligations (app rules)',
      body:
          'Use the app lawfully. Do not damage stations, block bays longer than needed, or harass other drivers.\n'
          'Do not submit false crowd reports or fake stations.\n'
          'Vehicle data (connector, battery, range) is your responsibility; a wrong profile can produce a wrong trip sketch.\n'
          'Do not attempt to access the owner inbox without authorisation. The lab owner PIN is not an identity system.\n'
          'Do not use the lab HTTP API from the public internet as if it were production.',
    ),
    (
      heading: '5. Stations, price, occupancy',
      body:
          'We show location, connector types, and other static information from Open Charge Map and confirmed crowd marks. '
          'Occupancy is UNKNOWN unless you or others report it. Price on site is the operator’s. '
          'EE is not liable for a column that is occupied, broken, or missing. Check the operator before you drive.',
    ),
    (
      heading: '6. Lab sessions and payments',
      body:
          'Start/Stop in this build writes a local estimate only. It is not a CPO session and not a payment. '
          'When payments are enabled, energy price and fees depend on the operator; EE may show a service fee before you confirm. '
          'Card numbers will not be stored in the EE app (Stripe / Apple Pay / Google Pay). Disputes about kWh belong with the operator first.',
    ),
    (
      heading: '7. Third-party services',
      body:
          'The app calls independent services. They process data under their own terms. Open the URLs from Account → Legal → Third-party services, or here:\n'
          '• Google privacy: https://policies.google.com/privacy\n'
          '• Google Maps terms: https://cloud.google.com/maps-platform/terms\n'
          '• Firebase terms: https://firebase.google.com/terms\n'
          '• Open Charge Map terms: https://openchargemap.org/site/about/terms\n'
          '• Open Charge Map privacy: https://openchargemap.org/site/about/privacy\n'
          '• Nominatim policy: https://operations.osmfoundation.org/policies/nominatim/\n'
          '• OSM privacy: https://wiki.osmfoundation.org/wiki/Privacy_Policy\n'
          '• Stripe privacy (future payments): https://stripe.com/privacy\n'
          'Station operators remain responsible for the hardware, energy, and their prices. EE is not those operators.',
    ),
    (
      heading: '8. Privacy and deletion',
      body:
          'Personal data is described in the Privacy notice. You can erase this device and your lab server rows from Account → Legal → Delete all my data. '
          'Published map POIs stay; your submitter id is anonymised.',
    ),
    (
      heading: '9. Limits of liability',
      body:
          'The service is provided “as is”. EE is not liable for loss caused by incorrect map data, GPS error, network failure, or an operator’s fault. '
          'This does not affect rights that cannot be limited under Lithuanian and EU consumer law.',
    ),
    (
      heading: '10. Intellectual property',
      body:
          'The EE name, app UI, and our original text belong to Energy Eniwhere. Map tiles, OCM data, and fonts remain with their owners under their licences.',
    ),
    (
      heading: '11. Standards (honest status)',
      body:
          'We design toward GDPR/BDAR, ePrivacy for location, CRA for the app as a product with digital elements, and (when payments exist) PSD2/PCI via a licensed provider. '
          'We do not claim ISO 27001, PCI ROC, CRA CE marking, or a completed DPIA. The Security & Compliance register is the gap list. This lab build is not a Play/App Store product.',
    ),
    (
      heading: '12. Changes and contact',
      body:
          'We may update these Terms. The new version appears on this screen and under Account → Legal. '
          'Continuing to use the app after an update means you accept the new edition. '
          'Contact: Energy Eniwhere, Lithuania, via Account in the app.',
    ),
  ];
}
