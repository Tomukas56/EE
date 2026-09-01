# Lab demo notes (historical)

Early lab snapshot. This is not a production-readiness claim. Current setup is in `README.md`.

## Backend API — live lab data

The backend API returns **7 stations**:

```json
1. Ignitis Charging Hub - Vilnius Center (1/2 available)
2. Elinta Fast Charge - Kaunas (2/2 available)
3. Maxima Shopping Center Charger (1/2 available)
4. Tesla Supercharger - Vilnius (2/3 available)
5. Ignitis Green Energy Hub (2/2 available)
6. Elinta Downtown Kaunas (1/1 available)
7. LIDL Parking Charger (0/1 available - OUT OF ORDER)
```

---

## Flutter app UI

### List screen
![Flutter List Screen](C:/Users/lapinskas.to/.gemini/antigravity/brain/e79a631c-9070-4f6d-b6cc-0938761ee85a/flutter_list_screen_1765190942912.png)

**Features:**
- Search bar (name / address)
- Station cards with live lab data
- Available/Total badge (green when available > 0)
- Tap a card to open the detail screen

---

### Detail screen
![Flutter Detail Screen](C:/Users/lapinskas.to/.gemini/antigravity/brain/e79a631c-9070-4f6d-b6cc-0938761ee85a/flutter_detail_screen_1765190961883.png)

**Features:**
- Full station description
- Contacts (phone, website — tappable)
- All connectors with status badges
- Navigate button (opens Google Maps)

---

## How to run the Flutter app

### Fastest path (about 1 minute)

1. **Turn on Developer Mode** (Windows):
```powershell
start ms-settings:developers
```
- Set Developer Mode → ON
- Wait until it finishes (~30 sec)

2. **Run Flutter**:
```bash
cd mobile
flutter run -d chrome
```

3. Chrome opens the same UI as the screenshots.

---

## Other options

### Android emulator (if you have one):
```bash
flutter run
```

### Windows desktop:
```bash
flutter run -d windows
```

### Build an APK:
```bash
flutter build apk
# APK: build/app/outputs/flutter-apk/app-release.apk
```

---

## What this snapshot covered

| Component | Status | Evidence |
|-------------|----------|----------|
| **Backend API** | Running | `curl localhost:3000/api/stations` returns JSON |
| **Database** | Running | 7 stations, 13 connectors |
| **Flutter code** | Ready to run | Files and dependencies present |
| **Flutter runtime** | Needs a target | Developer Mode or Android |

---

## Bottom line

This file describes an early lab check, not store or production status.

**Options at the time:**
- (A) Enable Developer Mode and run in Chrome
- (B) Use an Android emulator
- (C) Build an APK and test on a phone
