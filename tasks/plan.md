# Implementation Plan: Mobile APK Map Display & Network Permissions Fix

## Overview
Resolve blank map rendering in Android release APK builds. Fix missing Android network and location permissions in `android/app/src/main/AndroidManifest.xml`, configure cleartext HTTP support for local backend APIs, standardize `userAgentPackageName` across all 6 map screens to comply with OpenStreetMap policy, add test verification, and confirm release build pass.

## Architecture Decisions
- **Manifest Permissions**: Android requires `android.permission.INTERNET` in `android/app/src/main/AndroidManifest.xml` for release builds. Flutter only injects it into debug/profile builds. Location permissions (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) and network state (`ACCESS_NETWORK_STATE`) are required for device map tracking.
- **Cleartext HTTP Support**: Android 9+ blocks unencrypted HTTP traffic by default. Enable `android:usesCleartextTraffic="true"` on `<application>` so test/local backend connections over HTTP function on real devices.
- **User-Agent Uniformity**: OpenStreetMap tile server requires a unique, valid user-agent identifier. Standardize to `com.resq.resq` (matching `applicationId` in `android/app/build.gradle.kts`) via `AppConstants.packageName`.

## Task List

### Phase 1: Android Manifest Permissions & Configuration
- [x] Task 1: Add network and location permissions and cleartext traffic flag to `android/app/src/main/AndroidManifest.xml`

### Checkpoint 1: Android Manifest Configured
- [x] Verify `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_NETWORK_STATE`, and `usesCleartextTraffic="true"` exist in `android/app/src/main/AndroidManifest.xml`.

### Phase 2: User-Agent Standardization & Map Layer Refinements
- [x] Task 2: Define `AppConstants.packageName` and standardize `userAgentPackageName` in all 6 `TileLayer` instances

### Checkpoint 2: Map Configurations Unified
- [x] All 6 screens reference consistent package name `com.resq.resq`.

### Phase 3: Verification & Build Validation
- [x] Task 3: Add automated test for map constants and verify with `flutter analyze`, `flutter test`, and build compilation

### Checkpoint 3: Release Ready
- [x] `flutter analyze` passes with 0 issues.
- [x] `flutter test` passes (all 74 tests green).
- [x] `flutter build web` compiles with code 0.

## Risks & Mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| Gradle release build failure due to missing SDK or signing keys | Medium | Android build config already specifies `signingConfig = signingConfigs.getByName("debug")` in release build block for test builds. |
| Tile server 403 throttling | Low | Providing standardized `userAgentPackageName` prevents OSM User-Agent blocking. |
