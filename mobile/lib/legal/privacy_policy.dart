/// GDPR / BDAR privacy notice shown in the app. Lab-honest: no DPO, no RoPA yet.
class PrivacyPolicy {
  static const title = 'Privacy notice';
  static const subtitle = 'What we collect, why, and how you delete it';
  static const version = '2026-09-01';
  static const controller = 'Energy Eniwhere (EE), Lithuania';

  static const sections = <({String heading, String body})>[
    (
      heading: '1. Who is responsible',
      body:
          'The controller of personal data in this app is Energy Eniwhere (EE), Lithuania. '
          'This is a laboratory product, not a store listing. We do not yet have a named Data Protection Officer. '
          'Questions: use Account → Legal in the app. This notice is the Art. 13/14 information for the current build.',
    ),
    (
      heading: '2. What we process',
      body:
          'Google account id, display name, email, and photo (if Google provides them) — to keep you signed in on this device.\n'
          'Device location — only if you allow it in the OS, to show nearby stations, arrival reports, and trip start.\n'
          'Vehicle profile (make, model, battery, range, connector) — stored only on this device.\n'
          'Crowd reports: stations you mark (name, address, coordinates, optional note) and arrival answers (working / free connectors), tagged with your reporter id.\n'
          'Lab charging sessions: station, start/stop time, estimated kWh and euro amount. This is not a CPO meter and not a Stripe charge.\n'
          'Owner PIN, if you typed it — stored on this device to review submissions.\n'
          'We do not collect payment card numbers. Stripe is not live in this build.',
    ),
    (
      heading: '3. Why (legal bases)',
      body:
          'Contract (GDPR Art. 6(1)(b)): sign-in, station list, trip sketch, lab session history, crowd reports you choose to send.\n'
          'Consent (Art. 6(1)(a) and ePrivacy): device location. You may refuse; nearest-column and map-around-me then do not work.\n'
          'Legitimate interest (Art. 6(1)(f)): keeping the public map accurate after the owner confirms a user-marked site; security of the lab API.\n'
          'We do not sell personal data. We do not use it for advertising profiles.',
    ),
    (
      heading: '4. Where it is stored',
      body:
          'On this device: session, agreement tick, vehicle, owner PIN (SharedPreferences — not a hardware Keystore yet).\n'
          'On the EE lab server (PostgreSQL on the development machine / later hosting): crowd submissions, check-ins, charging sessions, keyed by reporter id (Google id, email, or “lab-device”).\n'
          'Station catalogue from Open Charge Map is not your personal data.\n'
          'This lab API may use HTTP on the local network. Production must use HTTPS.',
    ),
    (
      heading: '5. Recipients and processors',
      body:
          'Independent services process data under their own policies (open them from Account → Legal → Third-party services):\n'
          'Google Sign-In / Firebase Authentication; Google Maps Platform and Directions; Open Charge Map; OpenStreetMap Nominatim (trip fallback); the device OS. '
          'When payments are enabled later: Stripe and Apple Pay / Google Pay. Station operators (CPOs) are not EE and are not processors for the column itself.',
    ),
    (
      heading: '6. How long we keep it',
      body:
          'Device data: until you sign out, uninstall, or use Delete all my data.\n'
          'Server rows for your reporter id: until you delete them (or we close this lab database).\n'
          'A user-marked station that the owner already published stays on the public map as a POI; we anonymise your submitter id. We do not keep your name on that POI.',
    ),
    (
      heading: '7. Your rights',
      body:
          'Access, rectification, erasure, restriction, objection, and data portability under GDPR/BDAR. '
          'Erasure in this build: Account → Legal → Delete all my data. That wipes this device and asks the lab API to delete sessions, check-ins, and your unmarked submissions.\n'
          'This lab API is not JWT-locked: deletion is keyed by the reporter id the app sends. That is a known gap until production auth exists.\n'
          'You may complain to the Lithuanian State Data Protection Inspectorate (VDAT).',
    ),
    (
      heading: '8. Children',
      body:
          'The app is for drivers. It is not directed at children under 16.',
    ),
    (
      heading: '9. Changes',
      body:
          'We may update this notice. The new edition appears on the welcome screen and under Account → Legal. '
          'Continuing after an update means you have seen the new text. Last updated: $version.',
    ),
  ];
}
