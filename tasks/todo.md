# Task List: Mobile APK Map Display & Network Permissions Fix

## Task 1: Add network and location permissions and cleartext traffic flag to AndroidManifest.xml

**Description:** In `android/app/src/main/AndroidManifest.xml`, add the missing permissions required for OpenStreetMap tile downloading and GPS location tracking in release APKs: `android.permission.INTERNET`, `android.permission.ACCESS_FINE_LOCATION`, `android.permission.ACCESS_COARSE_LOCATION`, and `android.permission.ACCESS_NETWORK_STATE`. Add `android:usesCleartextTraffic="true"` inside the `<application>` tag to allow HTTP network communication with backend servers during development/testing.

**Acceptance criteria:**
- [x] `android.permission.INTERNET` declared in `android/app/src/main/AndroidManifest.xml`
- [x] `android.permission.ACCESS_FINE_LOCATION` and `android.permission.ACCESS_COARSE_LOCATION` declared
- [x] `android.permission.ACCESS_NETWORK_STATE` declared
- [x] `android:usesCleartextTraffic="true"` attribute added to `<application>`

**Verification:**
- [x] Inspect `android/app/src/main/AndroidManifest.xml` to verify correct XML placement
- [x] Automated test verification (`test/map_apk_permissions_test.dart`)

**Dependencies:** None

**Files likely touched:**
- `android/app/src/main/AndroidManifest.xml`

**Estimated scope:** Small: 1 file

---

## Task 2: Define AppConstants.packageName and standardize userAgentPackageName across all TileLayers

**Description:** In `lib/core/constants/app_constants.dart`, add `static const String packageName = 'com.resq.resq';`. In all 6 map screens (`map_screen.dart`, `dispatcher_map_screen.dart`, `live_tracking_screen.dart`, `emergency_detail_screen.dart`, `report_emergency_screen.dart`, and `driver_navigation_screen.dart`), replace hardcoded/varying userAgentPackageName strings with `AppConstants.packageName`.

**Acceptance criteria:**
- [x] `AppConstants.packageName` constant defined as `'com.resq.resq'`
- [x] All 6 `TileLayer` instances reference `AppConstants.packageName`
- [x] No hardcoded `'com.resq.resq_app'` or `'com.resq.emergency.app'` strings remain in `lib/`

**Verification:**
- [x] `grep -rn "userAgentPackageName" lib/` confirms all screens use `AppConstants.packageName`
- [x] `flutter analyze` clean (0 issues)

**Dependencies:** Task 1

**Files likely touched:**
- `lib/core/constants/app_constants.dart`
- `lib/features/map/screens/map_screen.dart`
- `lib/features/dispatcher/screens/dispatcher_map_screen.dart`
- `lib/features/citizen/screens/emergency_detail_screen.dart`
- `lib/features/citizen/screens/live_tracking_screen.dart`
- `lib/features/citizen/screens/report_emergency_screen.dart`
- `lib/features/driver/screens/driver_navigation_screen.dart`

**Estimated scope:** Medium: 7 files

---

## Task 3: Automated tests and release build verification

**Description:** Create test verification in `test/map_apk_permissions_test.dart` to verify `AppConstants.packageName` and tile layer configurations. Run `flutter analyze`, `flutter test`, and `flutter build` to verify compilation and release packaging.

**Acceptance criteria:**
- [x] New test file `test/map_apk_permissions_test.dart` passes
- [x] `flutter analyze` reports 0 issues
- [x] `flutter test` completes with 100% pass rate (74/74 tests passing)
- [x] Web build (`flutter build web`) compiles cleanly

**Verification:**
- [x] `flutter test test/map_apk_permissions_test.dart` passes
- [x] `flutter analyze` reports "No issues found!"
- [x] `flutter test` reports "All tests passed!" (74/74)
- [x] `flutter build web` compiles with code 0

**Dependencies:** Task 1, Task 2

**Files likely touched:**
- `test/map_apk_permissions_test.dart`

**Estimated scope:** Small: 1 file
