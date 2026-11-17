# Spec: Mobile APK Map Display & Network Permissions Fix

## Objective
Fix blank map rendering in Android mobile APK builds. Ensure OpenStreetMap raster tiles load reliably across all application roles (Citizen, Dispatcher, Driver) in release APK builds on real Android devices and emulators. Add necessary Android network and location permissions, ensure cleartext HTTP support for local API communication during development/testing, and standardize `userAgentPackageName` across all map tile layers.

## Tech Stack
- **Framework**: Flutter 3.44.x (Dart 3.12.x)
- **Mapping Package**: `flutter_map` ^8.3.2 with `latlong2` ^0.10.1
- **Platform**: Android (minSdk: 21, targetSdk: 34+, namespace: `com.resq.resq`)
- **Location & Permissions**: `geolocator` ^14.1.2, `permission_handler` 12.0.1
- **Tile Provider**: OpenStreetMap (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`)

## Commands
```bash
# Code analysis
flutter analyze

# Unit & widget tests
flutter test

# Clean build artifacts
flutter clean
flutter pub get

# Build debug APK (verifies debug build integrity)
flutter build apk --debug

# Build release APK (verifies release manifest merge and tile network access)
flutter build apk --release

# Inspect merged Android manifest in generated release APK
# (Verifies android.permission.INTERNET is present in release manifest)
./gradlew app:processReleaseMainManifest --dry-run
```

## Project Structure
```text
android/app/src/main/
├── AndroidManifest.xml          # Add INTERNET, location, network state permissions & cleartext flag
lib/
├── core/
│   └── constants/
│       └── app_constants.dart   # App constants, tile user agent, coordinate anchors
├── features/
│   ├── citizen/screens/
│   │   ├── emergency_detail_screen.dart # TileLayer userAgent standardization
│   │   ├── live_tracking_screen.dart    # TileLayer userAgent standardization
│   │   └── report_emergency_screen.dart # TileLayer userAgent standardization
│   ├── dispatcher/screens/
│   │   └── dispatcher_map_screen.dart   # TileLayer userAgent standardization
│   ├── driver/screens/
│   │   └── driver_navigation_screen.dart# TileLayer userAgent standardization
│   └── map/screens/
│       └── map_screen.dart              # TileLayer userAgent standardization
└── test/
    └── map_tile_config_test.dart        # Unit verification for map configs and constants
```

## Code Style
Code must adhere strictly to repository lint rules (`flutter_lints`). Keep widget tree declarative and configure `TileLayer` with consistent parameters:

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: AppConstants.packageName, // 'com.resq.resq'
  maxZoom: 18,
  panBuffer: 1,
  tileProvider: NetworkTileProvider(),
  errorTileCallback: (tile, error, stackTrace) {
    debugPrint('Map tile loading error at ${tile.coordinates}: $error');
  },
)
```

## Testing Strategy
1. **Manifest Verification**:
   - Inspect `android/app/src/main/AndroidManifest.xml` to ensure:
     - `android.permission.INTERNET` is present.
     - `android.permission.ACCESS_FINE_LOCATION` and `android.permission.ACCESS_COARSE_LOCATION` are present.
     - `android.permission.ACCESS_NETWORK_STATE` is present.
     - `android:usesCleartextTraffic="true"` is added to `<application>` to support local backend connections.
2. **Flutter Code Health**:
   - Run `flutter analyze` ensuring 0 diagnostics/warnings.
   - Run `flutter test` ensuring existing test suite passes.
3. **APK Release Build Check**:
   - Run `flutter build apk --release` to ensure release APK compiles cleanly with merged manifest.

## Boundaries
- **Always**:
  - Keep `android.permission.INTERNET` in `android/app/src/main/AndroidManifest.xml` so release builds have network access.
  - Set a valid, uniform `userAgentPackageName` complying with OpenStreetMap tile usage policy.
  - Keep offline fallback behavior in mock repositories intact.
- **Ask first**:
  - Changing tile providers (e.g. Mapbox, Google Maps, CartoDB).
  - Adding persistent tile caching libraries or native map SDK dependencies.
- **Never**:
  - Remove existing screen routing or map controls.
  - Check in release signing keystores or secrets.
  - Modify backend code or unrelated frontend flows.

## Success Criteria
- [ ] `android/app/src/main/AndroidManifest.xml` contains `android.permission.INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, and `ACCESS_NETWORK_STATE`.
- [ ] `android:usesCleartextTraffic="true"` configured in `<application>` element.
- [ ] `userAgentPackageName` standardized to `com.resq.resq` across all 6 map screen occurrences.
- [ ] `flutter analyze` reports 0 issues.
- [ ] `flutter build apk --release` completes successfully with code 0.
- [ ] Release APK allows OpenStreetMap tile downloads when executed on target devices.

## Open Questions
1. Do you need offline tile caching (e.g. `flutter_map_cache` / SQLite tile storage) for areas with zero connectivity, or is online OSM tile streaming with network fallback sufficient?
2. Are you using a custom tile server / proxy in production, or standard public OpenStreetMap tiles (`https://tile.openstreetmap.org/`)?
