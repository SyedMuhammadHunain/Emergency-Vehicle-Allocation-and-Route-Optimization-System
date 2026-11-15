# Task List: ResQ Production-Ready Stabilization

## Task 1: Contact number format (03XXXXXXXXX) and strict validation on Citizen Registration Screen

**Description:** In `lib/features/auth/screens/register_screen.dart`, enforce the Pakistani mobile number format `03XXXXXXXXX` (exactly 11 digits, beginning with `03`, digits-only input). Provide `03XXXXXXXXX` as the field hint. Reject inputs that do not meet the criteria with clear inline validation errors, prevent submission on invalid input, save the account on success, and return the user to `LoginScreen` for credential authentication without auto-navigating to the dashboard.

**Acceptance criteria:**
- [x] Phone field has hint text `03XXXXXXXXX` and clear format explanation
- [x] Input permits digits only (`FilteringTextInputFormatter.digitsOnly`) and limits length to 11
- [x] Validator strictly enforces exactly 11 digits and starts with `03`
- [x] Account creation blocked when validation fails; no success message shown on failure
- [x] On successful registration, account is saved in repository/backend and user is returned to `/login`
- [x] Newly registered account can immediately log in on `LoginScreen`

**Verification:**
- [x] Unit/Widget test verifying phone format validation and redirection to login (`test/registration_phone_test.dart` and `test/widget_test.dart`)
- [x] Manual test in widget environment: entering `03001234567` succeeds and navigates to `/login`; invalid formats (e.g., `04123456789`, `12345`) show inline errors

**Dependencies:** None

**Files likely touched:**
- `lib/features/auth/screens/register_screen.dart`
- `test/auth_test.dart`

**Estimated scope:** Small: 1-2 files

---

## Task 2: Remove Demo Mode Credentials, auto-fill chips, and demo role switcher from Login Screen & App Bar

**Description:** In `lib/features/auth/screens/login_screen.dart`, remove the visible "DEMO MODE CREDENTIALS" container, remove all demo email/password credential chips, and eliminate auto-fill on click. In `lib/core/widgets/brand/resq_app_bar.dart`, remove the demo role switcher pill and modal sheet trigger that allowed switching roles arbitrarily. Preserve existing login form aesthetics, layout, and normal credential authentication for all genuine roles.

**Acceptance criteria:**
- [x] "DEMO MODE CREDENTIALS" container and role chips removed from Login Screen
- [x] Clicking to auto-fill demo credentials completely eliminated
- [x] Demo role switcher pill and `_showRoleSwitcherSheet` removed/disabled from `ResQAppBar`
- [x] Login screen retains clean responsive layout, form styling, and error handling
- [x] Normal authentication works with registered credentials

**Verification:**
- [x] `flutter analyze` clean
- [x] Widget test verifying login screen elements render without demo credentials container (`test/login_cleanup_test.dart`)
- [x] Valid credentials log in properly; invalid credentials display standard authentication error

**Dependencies:** None

**Files likely touched:**
- `lib/features/auth/screens/login_screen.dart`
- `lib/core/widgets/brand/resq_app_bar.dart`

**Estimated scope:** Small: 1-2 files

---

## Task 3: Driver Authentication restriction to Admin-created accounts & session state hardening

**Description:** Ensure Driver login is restricted to valid driver accounts provisioned by the Administrator. Remove demo driver credentials, disallow arbitrary role switching into Driver mode, and verify the driver role upon authentication. Ensure `SessionService` persists user phone number and driver metadata across app sessions.

**Acceptance criteria:**
- [x] Driver accounts can only authenticate with valid credentials provisioned by Admin
- [x] No arbitrary role switcher allows entering Driver dashboard
- [x] `SessionService` properly tracks `userPhone` and account details alongside `role`, `userName`, and `userEmail`
- [x] Non-driver accounts attempting to authenticate as driver or accessing restricted driver views are handled safely

**Verification:**
- [x] Test verifying that only accounts with `role: 'driver'` created by Admin can access driver views (`test/driver_auth_test.dart`)
- [x] `flutter analyze` clean

**Dependencies:** Task 1, Task 2

**Files likely touched:**
- `lib/core/services/session_service.dart`
- `lib/core/mock/mock_repository.dart`
- `lib/features/auth/screens/login_screen.dart`

**Estimated scope:** Small: 2-3 files

---

## Checkpoint: Authentication & Registration Verified
- [x] Pakistani phone validation rejects invalid numbers and accepts only `03XXXXXXXXX`
- [x] Successful registration navigates to Login Screen, allowing login with new credentials
- [x] Login screen contains no demo credential chips or demo switcher; driver login requires Admin-created account

---

## Task 4: Citizen Profile real data binding and empty medical/emergency contacts

**Description:** In `lib/features/citizen/screens/citizen_profile_screen.dart`, bind the user identity card to actual registered data (`session.userName`, `session.userEmail`, `session.userPhone`). Remove hardcoded demo email, demo phone, and demo badge. In Medical ID & Emergency Contacts, eliminate all hardcoded/fictional demo data (blood type, allergies, contacts, preferred hospital). Default unentered fields to empty/not-provided states. Provide interactive dialogs to allow citizens to input, edit, and save their actual medical details and emergency contacts.

**Acceptance criteria:**
- [x] Citizen profile displays actual registered name, email, and phone number
- [x] No hardcoded `'citizen@resq.gov.pk · +92 300 1234567'` or `'VERIFIED CITIZEN (DEMO)'`
- [x] Medical ID and Emergency Contact fields default to empty/unspecified when not entered
- [x] User can edit and save medical details and emergency contacts; saved data persists and displays on return
- [x] Zero fictional demo medical data injected

**Verification:**
- [x] Widget test verifying empty initial medical state and proper binding of registered user data (`test/citizen_profile_test.dart`)
- [x] Test updating medical details and verifying persistent display (`test/citizen_profile_test.dart`)

**Dependencies:** Task 3

**Files likely touched:**
- `lib/features/citizen/screens/citizen_profile_screen.dart`
- `lib/core/services/session_service.dart`
- `lib/data/models/user_profile_model.dart`
- `lib/core/mock/mock_repository.dart`

**Estimated scope:** Medium: 3-4 files

---

## Task 5: Functional Push Notification and Location permissions on Citizen Profile

**Description:** Make the "Push Notifications" and "Location Permission" options in `lib/features/citizen/screens/citizen_profile_screen.dart` fully functional using `permission_handler` and `geolocator`. Query current permission status on mount, allow user to toggle/request permissions on tap, reflect real status in UI (granted, denied, permanently denied), and open app settings when permanently denied or explain clearly when unsupported.

**Acceptance criteria:**
- [x] "Push Notifications" tile is clickable, requests permission, and reflects true system status
- [x] Switch does not show "Enabled" unless notifications are genuinely granted
- [x] "Location Permission" tile is clickable, triggers device location permission request via `geolocator`/`permission_handler`, and reflects real status
- [x] Handles denied and permanently denied states with helpful messages and `openAppSettings()`
- [x] Gracefully handles web/desktop environments without throwing unhandled platform exceptions

**Verification:**
- [x] Widget test checking permission state resolution (`test/citizen_permissions_test.dart`)
- [x] Platform permission checks pass without crashes on Linux / web

**Dependencies:** Task 4

**Files likely touched:**
- `lib/features/citizen/screens/citizen_profile_screen.dart`
- `lib/core/services/location_service.dart`

**Estimated scope:** Small: 1-2 files

---

## Task 6: Remove "Frontend Prototype" labels from Citizen Profile and Report Emergency screens

**Description:** Remove the label `Frontend Prototype v1.0.0 (Phase 2)` from `lib/features/citizen/screens/citizen_profile_screen.dart` and `⚠️ ResQ Frontend Prototype · Simulated Karachi Dispatch Queue` from `lib/features/citizen/screens/report_emergency_screen.dart`. Clean any other prototype disclaimer labels at the end of citizen/user pages while strictly preserving titles, descriptions, and functional UI content.

**Acceptance criteria:**
- [x] `Frontend Prototype` text completely removed from Citizen Profile screen
- [x] `Frontend Prototype` text completely removed from Report Emergency screen
- [x] No remaining `Frontend Prototype` labels on citizen/user screens
- [x] Useful info, app version, and surrounding UI preserved intact

**Verification:**
- [x] `grep -rn "Frontend Prototype" lib/features/citizen/` returns zero occurrences
- [x] `flutter analyze` clean

**Dependencies:** None

**Files likely touched:**
- `lib/features/citizen/screens/citizen_profile_screen.dart`
- `lib/features/citizen/screens/report_emergency_screen.dart`

**Estimated scope:** Small: 1-2 files

---

## Checkpoint: Citizen Profile & Permissions Functional
- [x] Citizen Profile displays actual registered name, email, and contact number
- [x] Medical ID and emergency contacts show empty states unless entered and saved by user
- [x] Push notification and location permission tiles reflect real device status and handle requests/denials
- [x] "Frontend Prototype" labels removed from Citizen screens

---

## Task 7: Citizen Emergency submission & My Reports screen

**Description:** Fix the complete emergency reporting and retrieval flow for Citizens. In `lib/features/citizen/screens/report_emergency_screen.dart` and `lib/features/citizen/screens/my_reports_screen.dart`, ensure that when a citizen reports an emergency, it is stored with their user ID. In `MyReportsScreen`, filter reports strictly to the logged-in citizen (`reportedByUserId == session.userId` or matching email/account). Automatically refresh the list when `MyReportsScreen` is opened. Provide proper loading, empty, and error states without hardcoding sample reports for unrelated citizens.

**Acceptance criteria:**
- [x] Emergency reported by a citizen is saved to backend / `MockRepository` linked to that citizen's ID
- [x] `MyReportsScreen` displays only reports belonging to currently authenticated citizen
- [x] Newly submitted reports appear immediately without needing to log out and log in again
- [x] Displays emergency details: title/category, status, description, location label, reported date
- [x] Empty state rendered when the citizen has no reports; no unrelated demo emergencies shown
- [x] Pull-to-refresh or reload triggers fresh data fetch

**Verification:**
- [x] Integration/Widget test: Citizen registers -> submits emergency -> navigates to My Reports -> emergency is listed; switch user -> My Reports is empty or shows only that user's reports (`test/citizen_reports_test.dart`)
- [x] `flutter test test/citizen_module_test.dart` passes

**Dependencies:** Task 1, Task 4

**Files likely touched:**
- `lib/features/citizen/screens/my_reports_screen.dart`
- `lib/features/citizen/screens/report_emergency_screen.dart`
- `lib/core/mock/mock_repository.dart`
- `lib/core/services/api_service.dart`

**Estimated scope:** Medium: 3-4 files

---

## Task 8: Citizen Live Tracking Map fixes

**Description:** In `lib/features/citizen/screens/live_tracking_screen.dart`, fix tracking map display. Display the reported emergency location marker accurately. When an assigned emergency vehicle exists with real location/route, display the vehicle marker and route polyline. If no vehicle is assigned or real tracking data is unavailable, clearly display an appropriate unavailable/pending dispatch state instead of pretending live GPS movement with fake waypoints. Fetch tracking updates from backend / repository integration.

**Acceptance criteria:**
- [x] Map displays reported emergency location correctly
- [x] Assigned vehicle and real route shown only when an actual assignment exists
- [x] If tracking data is unavailable or vehicle not yet dispatched, show clear pending/unavailable status banner instead of fake animated movement
- [x] Handles loading, error, and unavailable states properly
- [x] Existing map styling and card layout strictly preserved

**Verification:**
- [x] Widget test for `LiveTrackingScreen` with assigned vehicle and with unassigned emergency (`test/map_tracking_and_zoom_test.dart`)
- [x] `flutter analyze` clean

**Dependencies:** Task 7

**Files likely touched:**
- `lib/features/citizen/screens/live_tracking_screen.dart`
- `lib/features/citizen/screens/emergency_detail_screen.dart`

**Estimated scope:** Small: 1-2 files

---

## Task 9: Universal Map Zoom Controls (+/-) added to all 6 FlutterMap screens

**Description:** Build a reusable, non-intrusive `MapZoomControls` widget providing working Zoom In (+) and Zoom Out (-) buttons. Integrate it across all 6 map screens in the project: `LiveTrackingScreen`, `EmergencyDetailScreen`, `ReportEmergencyScreen`, `DispatcherMapScreen`, `DriverNavigationScreen`, and `MapScreen`. Ensure buttons actually change zoom level on `MapController` within limits (3.0 to 18.0) and preserve all existing markers, routes, and layout styling.

**Acceptance criteria:**
- [x] Reusable `MapZoomControls` widget created in `lib/core/widgets/map/`
- [x] Zoom In (+) increases zoom level smoothly via `MapController.move`
- [x] Zoom Out (-) decreases zoom level smoothly via `MapController.move`
- [x] Integrated into all 6 map screens:
  - `LiveTrackingScreen`
  - `EmergencyDetailScreen`
  - `ReportEmergencyScreen`
  - `DispatcherMapScreen`
  - `DriverNavigationScreen`
  - `MapScreen`
- [x] Map markers, polylines, and responsive styling completely preserved
- [x] Zero decorative non-functional zoom buttons

**Verification:**
- [x] Widget test verifying zoom controls trigger `move()` on `MapController` (`test/map_tracking_and_zoom_test.dart`)
- [x] `flutter analyze` passes

**Dependencies:** Task 8

**Files likely touched:**
- `lib/core/widgets/map/map_zoom_controls.dart`
- `lib/features/citizen/screens/live_tracking_screen.dart`
- `lib/features/citizen/screens/emergency_detail_screen.dart`
- `lib/features/citizen/screens/report_emergency_screen.dart`
- `lib/features/dispatcher/screens/dispatcher_map_screen.dart`
- `lib/features/driver/screens/driver_navigation_screen.dart`
- `lib/features/map/screens/map_screen.dart`

**Estimated scope:** Medium: 5-7 files

---

## Checkpoint: Citizen Reporting, Tracking & Maps Operational
- [x] Submitted emergencies immediately appear in the reporting citizen's My Reports list
- [x] My Reports displays only reports belonging to currently logged-in citizen, with proper empty/loading states
- [x] Citizen Tracking Map displays correct emergency location, assigned vehicle, real route, and unavailable state when no live tracking exists
- [x] All 6 map screens have working zoom in (+) and zoom out (-) controls

---

## Task 10: Remove prototype and technical architecture labels from Dispatcher, Driver, and Admin profiles

**Description:** Clean technical architecture labels from profiles:
- In `lib/features/dispatcher/screens/dispatcher_profile_screen.dart`: remove `Prototype Architecture` tile and `(Demo Prototype)` footer text.
- In `lib/features/driver/screens/driver_profile_screen.dart`: remove `Prototype Driver Engine` tile and `(Demo Prototype)` footer text.
- In `lib/features/admin/screens/admin_profile_screen.dart`: remove `Django REST Framework Client` tile, `Session Cryptography` row, and `(Demo Prototype)` footer text.
Preserve all functional profile settings, theme pickers, identity details, and sign out capabilities.

**Acceptance criteria:**
- [x] Dispatcher profile has `Prototype Architecture` and prototype wording removed
- [x] Driver profile has `Prototype Driver Engine` and prototype wording removed
- [x] Admin profile has `Django REST Framework` tile and `Session Cryptography` row removed
- [x] All three profiles retain legitimate account management and settings without layout distortion

**Verification:**
- [x] `grep -rnE "Prototype Architecture|Prototype Driver Engine|Session Cryptography" lib/` returns 0 hits
- [x] `flutter analyze` clean

**Dependencies:** None

**Files likely touched:**
- `lib/features/dispatcher/screens/dispatcher_profile_screen.dart`
- `lib/features/driver/screens/driver_profile_screen.dart`
- `lib/features/admin/screens/admin_profile_screen.dart`

**Estimated scope:** Small: 3 files

---

## Task 11: Admin Staff and User Management: remove hardcoded Demo Citizen, bind live backend/registered users, enable driver account creation

**Description:** In `lib/features/admin/screens/admin_staff_screen.dart`, remove the hardcoded "Demo Citizen" entry from Staff and Users lists. Show genuine users fetched from backend / repository. When a new citizen registers, they must appear in Admin Users. When Admin creates a new Driver or Dispatcher via `Provision Staff`, save the account via backend / repository so the newly created driver can log in using their email and password. Ensure list refreshes cleanly.

**Acceptance criteria:**
- [x] Hardcoded "Demo Citizen" (`USR-CIT-001`) removed from Admin Users/Staff list
- [x] Real registered citizens appear in Admin Users list
- [x] Admin can provision a new Driver with full name, email, phone, and initial password
- [x] Newly provisioned driver account is persisted and can authenticate on login
- [x] User list refreshes dynamically

**Verification:**
- [x] Integration test: Admin creates driver -> Driver logs in -> auth succeeds (`test/admin_users_cleanup_test.dart`)
- [x] `flutter test` passes

**Dependencies:** Task 1, Task 2, Task 3

**Files likely touched:**
- `lib/features/admin/screens/admin_staff_screen.dart`
- `lib/core/mock/mock_repository.dart`
- `lib/core/mock/demo_data.dart`
- `lib/core/services/api_service.dart`

**Estimated scope:** Medium: 3-4 files

---

## Task 12: Backend API and Data Consistency: verify endpoints across all 12 operational flows

**Description:** Inspect and update `lib/core/services/api_service.dart` to support all 12 required flows:
1. Citizen registration (`POST /api/auth/register/`) and login (`POST /api/auth/login/`)
2. Citizen profile retrieval (`GET /api/auth/me/`) and updates (`PATCH /api/auth/me/`)
3. Citizen emergency submission (`POST /api/emergencies/`)
4. Citizen My Reports retrieval (`GET /api/emergencies/?reported_by=...`)
5. Citizen tracking information retrieval (`GET /api/emergencies/<id>/`, `/api/vehicles/<id>/`, `/api/route/`)
6. Push notification permission handling
7. Location permission handling
8. Admin-created driver registration (`POST /api/users/`)
9. Driver authentication (`POST /api/auth/login/`)
10. Admin user and staff listing (`GET /api/users/`)
11. Dispatcher emergency and vehicle information (`GET /api/emergencies/`, `GET /api/vehicles/`)
12. Existing vehicle assignment and emergency management (`POST /api/allocate/`, `POST /api/assignments/`)
Keep repository and service architecture intact; ensure error handling doesn't silently swallow API errors.

**Acceptance criteria:**
- [x] All 12 flows mapped cleanly in `ApiService` with proper request/response contracts matching Django backend
- [x] Error messages surfaced to UI rather than silently suppressed
- [x] Graceful fallback maintained when backend server is offline during development/testing
- [x] No fake local data replaces genuine backend data when connected

**Verification:**
- [x] `test/api_service_test.dart` passes and tests all 12 operational flows
- [x] `flutter analyze` clean

**Dependencies:** Task 7, Task 8, Task 11

**Files likely touched:**
- `lib/core/services/api_service.dart`
- `test/api_service_test.dart`

**Estimated scope:** Medium: 2-3 files

---

## Checkpoint: Admin Management & Backend Verification Complete
- [ ] Dispatcher, Driver, and Admin profiles have all prototype/architecture labels removed
- [ ] Admin panel shows genuine registered citizens and staff without hardcoded "Demo Citizen"
- [ ] Admin can create driver accounts that successfully authenticate
- [ ] All 12 backend flows verified against Django REST endpoints with proper error handling

---

## Task 13: Code quality check, type safety, dart format lib, flutter analyze, and unit/widget test suite execution

**Description:** Audit entire `lib/` directory for compilation errors, undefined methods/variables, incorrect imports, type mismatches, and broken API response parsers. Run `dart format lib`, `flutter analyze`, and `flutter test`. Fix any regressions introduced by changes.

**Acceptance criteria:**
- [ ] `dart format lib` formats all Dart code consistently
- [ ] `flutter analyze` outputs `No issues found!` with 0 errors, 0 warnings
- [ ] `flutter test` executes all test files and passes 100%

**Verification:**
- [ ] `dart format --output=none --set-exit-if-changed lib` returns 0
- [ ] `flutter analyze` returns 0
- [ ] `flutter test` returns 0

**Dependencies:** Tasks 1-12

**Files likely touched:**
- Entire `lib/` and `test/` suites as needed

**Estimated scope:** Medium: 3-5 files

---

## Task 14: Web build verification and compilation audit

**Description:** Run `flutter build web` to ensure clean production compilation on web target without missing platform assets, broken web packages, or tree-shaking issues.

**Acceptance criteria:**
- [ ] `flutter build web` compiles with exit code 0
- [ ] Output artifacts created in `build/web/`
- [ ] Zero unhandled compile-time errors or web target incompatibilities

**Verification:**
- [ ] Command check: `flutter build web` completes with exit code 0

**Dependencies:** Task 13

**Files likely touched:** None (build verification)

**Estimated scope:** Small: 1 file

---

## Task 15: Final comprehensive completion report covering all 15 requirements

**Description:** Prepare a complete, itemized final report answering all 15 teammate requirements:
1. Every requirement completed, one by one
2. Every file modified
3. Backend flows verified
4. Any features blocked by missing backend support or device permissions
5. Actual `flutter analyze` output
6. Actual `flutter test` output
7. Actual `flutter build web` result
8. Actual `flutter run -d chrome` result (or headless web test verification on Linux)

**Acceptance criteria:**
- [ ] Itemized status for all 15 requirements
- [ ] Verbatim test and build command outputs included
- [ ] Clear documentation of all modified files and verified flows

**Verification:**
- [ ] Report review against teammate prompt criteria

**Dependencies:** Task 14

**Files likely touched:** None (reporting)

**Estimated scope:** Small: 1 file

---

## Checkpoint: Final Release Ready
- [ ] `flutter analyze` passes with zero issues
- [ ] `flutter test` executes cleanly
- [ ] `flutter build web` compiles successfully
- [ ] All 15 teammate requirements satisfied and documented
