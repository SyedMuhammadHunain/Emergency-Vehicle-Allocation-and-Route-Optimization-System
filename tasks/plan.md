# Implementation Plan: ResQ Production-Ready Stabilization & Teammate Requirements Execution

## Overview
Implement all 15 requirements to transition ResQ from a prototype to a production-ready emergency response application: strict Pakistani phone number format and validation (`03XXXXXXXXX`), citizen tracking map fixes, universal zoom controls across all 6 maps, removal of prototype text and demo credentials/role switchers, real citizen emergency reporting and My Reports retrieval, genuine citizen profile data with zero fake medical/emergency entries, functional push and location permissions, admin-created driver authentication, clean admin user lists, backend consistency across all 12 flows, and complete verification (`flutter analyze`, `flutter test`, `flutter build web`). All existing UI styling, themes, colors, layouts, typography, and navigation will be strictly preserved.

## Architecture Decisions
- **UI Preservation Constraint**: No visual redesigns, color changes, layout restructuring, or navigation modifications. All modifications are surgical logic corrections, UI removals/additions of specific elements requested, and data bindings.
- **Pakistani Contact Validation**: Enforce format `03XXXXXXXXX` (exactly 11 digits, starting with `03`, digits-only input) in `RegisterScreen`. On success, redirect to `LoginScreen` for credential authentication instead of auto-logging in.
- **Universal Map Zoom Architecture**: Implement a reusable `MapZoomControls` overlay component utilizing `MapController.move()` to support responsive Zoom In (+) and Zoom Out (-) across all 6 `FlutterMap` instances.
- **Permission Management**: Utilize existing `permission_handler` and `geolocator` packages to query and request real system permissions for Push Notifications and Location, with status reflection and settings redirects.
- **Data Binding & Privacy**: Bind `SessionService` and profile components to actual user attributes (name, email, phone). Default medical details and emergency contacts to empty states; permit user editing and saving without injecting fictional data.
- **Scoped My Reports**: Filter incident reports strictly by the logged-in citizen's unique identifier, with immediate reload upon submission and navigation.
- **Driver Auth & Staff Provisioning**: Restrict driver authentication to valid accounts provisioned through Admin management (`/api/users/` or `createStaffAccount`), eliminating role-switching bypasses and demo credentials.

## Task List

### Phase 1: Authentication & Account Creation Hardening
- [x] Task 1: Contact number format (`03XXXXXXXXX`) and strict validation on Citizen Registration Screen
- [x] Task 2: Remove Demo Mode Credentials, auto-fill chips, and demo role switcher from Login Screen & App Bar
- [x] Task 3: Driver Authentication restriction to Admin-created accounts & session state hardening

### Checkpoint: Authentication & Registration Verified
- [x] Registration rejects invalid numbers and accepts only `03XXXXXXXXX` (11 digits)
- [x] Successful registration navigates to Login Screen, allowing login with new credentials
- [x] Login screen contains no demo credential chips or demo switcher; driver login requires Admin-created account

### Phase 2: Citizen Profile & Device Permissions
- [x] Task 4: Citizen Profile real data binding and empty medical/emergency contacts (zero fake data, profile editing)
- [x] Task 5: Functional Push Notification and Location permissions on Citizen Profile using `permission_handler` and `geolocator`
- [x] Task 6: Remove "Frontend Prototype" labels from Citizen Profile and Report Emergency screens

### Checkpoint: Citizen Profile & Permissions Functional
- [x] Citizen Profile displays actual registered name, email, and contact number
- [x] Medical ID and emergency contacts show empty states unless entered and saved by user
- [x] Push notification and location permission tiles reflect real device status and handle requests/denials
- [x] "Frontend Prototype" labels removed from Citizen screens

### Phase 3: Citizen Reports & Live Tracking Map
- [x] Task 7: Citizen Emergency submission & My Reports screen (fetch by current citizen ID, real-time update, loading/empty states)
- [ ] Task 8: Citizen Live Tracking Map fixes (real emergency location, assigned vehicle & route, loading/unavailable states, no fake animation)
- [ ] Task 9: Universal Map Zoom Controls (+/-) added to all 6 FlutterMap screens

### Checkpoint: Citizen Reporting, Tracking & Maps Operational
- [x] Submitted emergencies immediately appear in the reporting citizen's My Reports list
- [x] My Reports displays only reports belonging to currently logged-in citizen, with proper empty/loading states
- [ ] Citizen Tracking Map displays correct emergency location, assigned vehicle, real route, and unavailable state when no live tracking exists
- [ ] All 6 map screens have working zoom in (+) and zoom out (-) controls

### Phase 4: Admin Management & Profile Technical Cleanups
- [ ] Task 10: Remove prototype and technical architecture labels from Dispatcher, Driver, and Admin profiles
- [ ] Task 11: Admin Staff and User Management: remove hardcoded Demo Citizen, bind live backend/registered users, enable driver account creation
- [ ] Task 12: Backend API and Data Consistency: verify endpoints (`ApiService` <-> Django REST API) across all 12 operational flows

### Checkpoint: Admin Management & Backend Verification Complete
- [ ] Dispatcher, Driver, and Admin profiles have all prototype/architecture labels removed
- [ ] Admin panel shows genuine registered citizens and staff without hardcoded "Demo Citizen"
- [ ] Admin can create driver accounts that successfully authenticate
- [ ] All 12 backend flows verified against Django REST endpoints with proper error handling

### Phase 5: Code Quality & Full Build/Test Verification
- [ ] Task 13: Code quality check, type safety, `dart format lib`, `flutter analyze`, and unit/widget test suite execution (`flutter test`)
- [ ] Task 14: Web build verification (`flutter build web`) and compilation audit
- [ ] Task 15: Final comprehensive completion report covering all 15 requirements

### Checkpoint: Final Release Ready
- [ ] `flutter analyze` passes with zero issues
- [ ] `flutter test` executes cleanly
- [ ] `flutter build web` compiles successfully
- [ ] All 15 teammate requirements satisfied and documented

## Risks and Mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| Existing tests rely on `kPredefinedDemoAccounts` or demo login chips | High | Update test cases to register or authenticate accounts explicitly without breaking test assertions |
| Web environment restrictions on mobile permissions (push/location) | Medium | Gracefully handle web browser permission status and avoid unsupported permission API crashes |
| Map controller zoom calls when map is not yet mounted | Low | Check controller readiness and clamp zoom levels between minZoom (3.0) and maxZoom (18.0) |
| Backend offline in local developer environment | Medium | ApiService maintains graceful fallback to MockRepository while logging clear backend status |

## Open Questions
- None. Requirements and scope confirmed.
