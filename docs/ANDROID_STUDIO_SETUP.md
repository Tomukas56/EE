# Android Studio Installation Guide

## Step 1: Download
1. Visit: https://developer.android.com/studio
2. Click **"Download Android Studio"**
3. Accept terms and conditions
4. Download will start (~1GB file)

## Step 2: Install
1. Run the downloaded `.exe` file
2. Click **"Next"** on welcome screen
3. Select components:
   - ✅ Android Studio
   - ✅ Android Virtual Device (for emulator)
4. Click **"Next"**
5. Choose installation location (default is fine)
6. Click **"Install"**
7. Wait ~5-10 minutes for installation

## Step 3: First Run Setup
1. Launch Android Studio
2. Choose **"Standard"** setup
3. Select UI theme (Light or Darcula)
4. Click **"Next"**
5. Verify settings and click **"Finish"**
6. Wait for SDK components to download (~2-3 GB)

## Step 4: Configure Flutter
```bash
flutter doctor --android-licenses
# Accept all licenses by typing 'y'
```

## Step 5: Build APK
```bash
cd mobile
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`

---

## Total Time: ~15-20 minutes
- Download: 3-5 min
- Install: 5-7 min  
- Setup: 5-8 min
