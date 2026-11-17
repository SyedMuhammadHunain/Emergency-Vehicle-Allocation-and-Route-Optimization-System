# Task List: Map Category Markers & App-Wide Layout Fix

## Task 1: Add `getEmergenciesByCategory()` to MockRepository

**Description:** Add a method to MockRepository that filters emergencies by category string, returning all matching `DemoEmergency` records.

**Acceptance criteria:**
- [x] `List<DemoEmergency> getEmergenciesByCategory(String category)` method exists
- [x] Returns only emergencies where `e.category == category`
- [x] Returns empty list when no matches

**Verification:**
- [x] `flutter analyze` clean
- [x] Unit test `test/category_map_markers_test.dart` passes (all assertions verified)

**Dependencies:** None

**Files likely touched:**
- `lib/core/mock/mock_repository.dart`
- `test/category_map_markers_test.dart`

**Estimated scope:** XS (1 file)

---

## Task 2: Render category-filtered markers on Report Emergency map

**Description:** When user selects a category on Report Emergency screen, load matching emergencies from MockRepository and render them as colored markers on the map. User's own location pin stays on top. Markers update on category change via setState.

**Acceptance criteria:**
- [x] Map shows existing emergency markers filtered by `_selectedCategory`
- [x] Each marker uses category-appropriate color (teal=medical, orange=fire, pink=accident, purple=rescue)
- [x] Markers are smaller (28px) than user pin (44px) and render below it
- [x] Switching category immediately updates markers
- [x] Tapping a marker does not interfere with user pin placement

**Verification:**
- [x] `flutter analyze` clean
- [x] Unit/Widget test `test/category_map_markers_test.dart` passes (all category switches tested)

**Dependencies:** Task 1

**Files likely touched:**
- `lib/features/citizen/screens/report_emergency_screen.dart`

**Estimated scope:** S (1 file)

---

## Task 3: Fix citizen screens layout (6 files)

**Description:** Fix Row overflow, text overflow, missing SafeArea across all 6 citizen screens. Add Expanded/Flexible to unconstrained Rows, add overflow/maxLines to tight Text widgets, wrap bodies in SafeArea.

**Acceptance criteria:**
- [ ] All Row overflow issues fixed (citizen_home:580,668,807; citizen_profile:431,720; emergency_detail:87,233,518; live_tracking:435,484,515,618; my_reports:127,324,392)
- [ ] All Text overflow issues fixed (14 locations per audit)
- [ ] SafeArea added to screens lacking AppBar (citizen_home, citizen_profile, my_reports, live_tracking)
- [ ] live_tracking FAB bottom position adjusted to avoid card collision
- [ ] Bottom sheet in live_tracking scrollable

**Verification:**
- [ ] `flutter analyze` clean
- [ ] Manual: open each citizen screen on 360px emulator, no yellow/black overflow stripes

**Dependencies:** None

**Files likely touched:**
- `lib/features/citizen/screens/citizen_home_screen.dart`
- `lib/features/citizen/screens/citizen_profile_screen.dart`
- `lib/features/citizen/screens/emergency_detail_screen.dart`
- `lib/features/citizen/screens/live_tracking_screen.dart`
- `lib/features/citizen/screens/my_reports_screen.dart`
- `lib/features/citizen/screens/notifications_screen.dart`

**Estimated scope:** L (6 files) — but all mechanical pattern: wrap in Flexible, add ellipsis

---

## Task 4: Fix dispatcher screens layout (7 files)

**Description:** Fix Row overflow, text overflow, missing SafeArea, missing ScrollView across all 7 dispatcher screens.

**Acceptance criteria:**
- [ ] Row overflow fixed: dispatcher_profile:346-365, dispatcher_notifications:29-91, dispatcher_allocation:81-109/488-502/617-630, dispatcher_dashboard:436-455, dispatcher_vehicles:278-292, dispatcher_map:579-601
- [ ] Text overflow fixed (14 locations per audit)
- [ ] SafeArea added to all 7 dispatcher screens
- [ ] Bottom sheets in dispatcher_vehicles and dispatcher_map wrapped in SingleChildScrollView
- [ ] dispatcher_map banner/filter bar overlap fixed (top positioning)

**Verification:**
- [ ] `flutter analyze` clean
- [ ] Manual: open each dispatcher screen on 360px emulator, no overflow

**Dependencies:** None

**Files likely touched:**
- `lib/features/dispatcher/screens/dispatcher_allocation_screen.dart`
- `lib/features/dispatcher/screens/dispatcher_dashboard_screen.dart`
- `lib/features/dispatcher/screens/dispatcher_emergency_screen.dart`
- `lib/features/dispatcher/screens/dispatcher_map_screen.dart`
- `lib/features/dispatcher/screens/dispatcher_notifications_screen.dart`
- `lib/features/dispatcher/screens/dispatcher_profile_screen.dart`
- `lib/features/dispatcher/screens/dispatcher_vehicles_screen.dart`

**Estimated scope:** L (7 files)

---

## Task 5: Fix driver screens layout (6 files)

**Description:** Fix Row overflow, text overflow, missing SafeArea, hardcoded positioning across all 6 driver screens.

**Acceptance criteria:**
- [ ] Row overflow fixed: driver_dashboard:279-305, driver_history:118-148, driver_mission:180-206, driver_navigation:346-382, driver_notifications:29-91, driver_profile:341-360
- [ ] Text overflow fixed (8 locations per audit)
- [ ] SafeArea added to all 6 driver screens
- [ ] driver_navigation MapZoomControls top collision fixed

**Verification:**
- [ ] `flutter analyze` clean
- [ ] Manual: open each driver screen on 360px emulator, no overflow

**Dependencies:** None

**Files likely touched:**
- `lib/features/driver/screens/driver_dashboard_screen.dart`
- `lib/features/driver/screens/driver_history_screen.dart`
- `lib/features/driver/screens/driver_mission_screen.dart`
- `lib/features/driver/screens/driver_navigation_screen.dart`
- `lib/features/driver/screens/driver_notifications_screen.dart`
- `lib/features/driver/screens/driver_profile_screen.dart`

**Estimated scope:** L (6 files)

---

## Task 6: Fix admin screens layout (6 files)

**Description:** Fix Row overflow, text overflow, missing SafeArea, missing ScrollView in dialogs across all 6 admin screens.

**Acceptance criteria:**
- [ ] Row overflow fixed: admin_reports:122-154/319-338, admin_resources:246-258, admin_staff:429-460, admin_vehicles:368-382
- [ ] Text overflow fixed (7 locations per audit)
- [ ] SafeArea added to all 6 admin screens
- [ ] Dialog forms in admin_resources and admin_vehicles wrapped in SingleChildScrollView

**Verification:**
- [ ] `flutter analyze` clean
- [ ] Manual: open each admin screen on 360px emulator, no overflow

**Dependencies:** None

**Files likely touched:**
- `lib/features/admin/screens/admin_dashboard_screen.dart`
- `lib/features/admin/screens/admin_profile_screen.dart`
- `lib/features/admin/screens/admin_reports_screen.dart`
- `lib/features/admin/screens/admin_resources_screen.dart`
- `lib/features/admin/screens/admin_staff_screen.dart`
- `lib/features/admin/screens/admin_vehicles_screen.dart`

**Estimated scope:** L (6 files)

---

## Task 7: Fix shared screens layout (3 files)

**Description:** Fix Row overflow, text overflow, missing SafeArea in map_screen, profile_screen, incident_detail_screen.

**Acceptance criteria:**
- [ ] map_screen:575-600 Row overflow fixed
- [ ] map_screen:550,557 Text overflow fixed
- [ ] map_screen FAB and preview cards get SafeArea bottom padding
- [ ] profile_screen:66-102,231-251,268-296 Row overflow fixed
- [ ] profile_screen:84,92,234,270 Text overflow fixed
- [ ] incident_detail_screen:319-343 Row overflow fixed
- [ ] incident_detail_screen:322 Text overflow fixed

**Verification:**
- [ ] `flutter analyze` clean
- [ ] Manual: open each screen on 360px emulator, no overflow

**Dependencies:** None

**Files likely touched:**
- `lib/features/map/screens/map_screen.dart`
- `lib/features/profile/screens/profile_screen.dart`
- `lib/features/incidents/screens/incident_detail_screen.dart`

**Estimated scope:** M (3 files)

---

## Task 8: Fix auth screens SafeArea (3 files)

**Description:** Add SafeArea to login, register, forgot_password screens. Bottom padding for gesture bar. Top inset handled by existing GradientHeader padding.

**Acceptance criteria:**
- [ ] login_screen: SafeArea wrapping body (bottom: true)
- [ ] register_screen: SafeArea wrapping body (bottom: true)
- [ ] forgot_password_screen: SafeArea wrapping body (bottom: true)

**Verification:**
- [ ] `flutter analyze` clean
- [ ] Manual: open auth screens, no overlap with status bar or gesture bar

**Dependencies:** None

**Files likely touched:**
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/auth/screens/register_screen.dart`
- `lib/features/auth/screens/forgot_password_screen.dart`

**Estimated scope:** S (3 files)

---

## Task 9: Full build verification

**Description:** Run flutter analyze, flutter test, flutter build apk --release. Verify all pass.

**Acceptance criteria:**
- [ ] `flutter analyze` reports 0 issues
- [ ] `flutter test` all tests pass
- [ ] `flutter build apk --release` succeeds
- [ ] No new warnings introduced

**Verification:**
- [ ] All three commands exit code 0

**Dependencies:** Tasks 1-8

**Files likely touched:** None (verification only)

**Estimated scope:** XS
