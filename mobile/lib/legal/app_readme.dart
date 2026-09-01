/// In-app README: what Energy Eniwhere is and how to use it.
class AppReadme {
  static const title = 'README';
  static const subtitle = 'What this app is and how to use it';

  static const sections = <({String heading, String body})>[
    (
      heading: 'What it is',
      body:
          'Energy Eniwhere is one app for EV drivers in Lithuania, Latvia, Estonia, and Poland. Instead of juggling operator apps (Ignitis, Elinta, Tesla, and others), you find columns here, plan a route with charging, and later start a session and pay.',
    ),
    (
      heading: 'What you need',
      body:
          '1) An Android phone / tablet or an iPhone.\n'
          '2) A Google account — the app will not open without it.\n'
          '3) Internet (for the station list and the map).\n'
          '4) Location permission if you want the nearest column.\n'
          '5) The same Wi-Fi as this computer if you are testing against the local API.',
    ),
    (
      heading: 'How to sign in',
      body:
          'On this first screen, read the Agreement and this README, tick that you agree, then tap Continue with Google. After a successful sign-in you get the root menu. Sign out from Account.',
    ),
    (
      heading: 'Root menu',
      body:
          'Four tiles fill the home screen. Open a tile for its submenu:\n'
          '• Stations — Map, Nearest, List, Mark a new station (published only after the owner confirms the physical location).\n'
          '• Trip — Trip with charging, My vehicle.\n'
          '• History — Charging history, Payments.\n'
          '• Account — who is signed in, Legal & privacy (terms, notice, third parties, delete my data), Owner review, Sign out.\n'
          'On arrival the app asks if the station is working and if connectors are free (Yes / No / Dismiss).\n'
          'Use the back arrow to return to the root menu.',
    ),
    (
      heading: 'Map',
      body:
          'Google Maps shows the stations. Blue pins are columns; orange is the one you selected. Search is at the top. Go opens turn-by-turn navigation. Map tiles need internet.',
    ),
    (
      heading: 'Good to know',
      body:
          'EE does not operate the columns. Occupancy may be unknown. Prices and session start depend on the operator and will be connected over time. The app is for drivers, not for station owners.',
    ),
  ];
}
