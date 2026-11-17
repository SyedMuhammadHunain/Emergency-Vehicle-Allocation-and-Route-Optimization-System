# Spec: Report Page Map Category Filtering & App-Wide Layout Fix

## Objective

Two changes to the ResQ APK:

1. **Map Category Markers on Report Emergency Page**: When the citizen selects an emergency type (Medical, Fire Hazard, Road Accident, Rescue/Other) on the Report Emergency screen, the map must display markers for all existing emergencies matching that category — loaded from `MockRepository`. Currently the map only shows the user's own location pin and ignores the category selector for marker display.

2. **App-Wide Layout & Structural Fixes**: Audit-driven cleanup of overflow, text clipping, missing `SafeArea`, missing scroll wrappers, and hardcoded sizing across all role screens (citizen, dispatcher, driver, admin, shared). Structural fix only — no visual redesign.

## Tech Stack

- Flutter 3.44.x / Dart 3.12.x
- `flutter_map` + `latlong2` for maps
- Provider for state management
- `MockRepository` / `DemoEmergency` for data
- Existing `EmergencyCategory` constants: `MEDICAL`, `FIRE`, `ACCIDENT`, `RESCUE`

## Commands

```bash
flutter analyze
flutter test
flutter build apk --release
```

## Project Structure

```
lib/features/citizen/screens/report_emergency_screen.dart  → Map category markers
lib/features/citizen/screens/citizen_home_screen.dart       → Layout fixes
lib/features/citizen/screens/citizen_profile_screen.dart    → Layout fixes
lib/features/citizen/screens/emergency_detail_screen.dart   → Layout fixes
lib/features/citizen/screens/live_tracking_screen.dart      → Layout fixes
lib/features/citizen/screens/my_reports_screen.dart         → Layout fixes
lib/features/citizen/screens/notifications_screen.dart      → Layout fixes
lib/features/dispatcher/screens/*.dart (7 files)            → Layout fixes
lib/features/driver/screens/*.dart (6 files)                → Layout fixes
lib/features/admin/screens/*.dart (6 files)                 → Layout fixes
lib/features/map/screens/map_screen.dart                    → Layout fixes
lib/features/profile/screens/profile_screen.dart            → Layout fixes
lib/features/incidents/screens/incident_detail_screen.dart  → Layout fixes
lib/features/home_sos/screens/home_sos_screen.dart          → (clean)
lib/features/auth/screens/*.dart (4 files)                  → SafeArea fixes
lib/core/mock/mock_repository.dart                          → Add category filter method
```

## Code Style

Follow existing project conventions. Example fix pattern:

```dart
// BEFORE (overflow):
Row(children: [Text(item.id), Text('· ${item.category}'), StatusChip(...)])

// AFTER (safe):
Row(children: [
  Expanded(child: Row(children: [
    Flexible(child: Text(item.id, overflow: TextOverflow.ellipsis, maxLines: 1)),
    const SizedBox(width: 4),
    Flexible(child: Text('· ${item.category}', overflow: TextOverflow.ellipsis, maxLines: 1)),
  ])),
  StatusChip(...),
])
```

## Testing Strategy

- `flutter analyze` must pass with 0 issues
- `flutter build apk --release` must succeed
- Manual verification: check each fixed screen on 360px width emulator
- Existing tests must not break

## Boundaries

- **Always**: Run `flutter analyze` before committing. Keep existing functionality intact. Work on branch `Hunain`.
- **Ask first**: Before modifying data models or adding new dependencies.
- **Never**: Run `git push`. Delete existing tests. Change visual design (colors, fonts, spacing system). Remove existing comments.

## Detailed Fix List

### A. Map Category Markers (report_emergency_screen.dart)

**Bug**: Category selection (`_selectedCategory`) only updates chip highlight. Map shows only user pin marker. No existing-emergency markers rendered.

**Fix**:
1. Add `getEmergenciesByCategory(String category)` method to `MockRepository`
2. In `report_emergency_screen.dart`, read `MockRepository` and filter emergencies by `_selectedCategory`
3. Render filtered emergencies as colored markers on the map (distinct icon/color per category)
4. When category changes, `setState` rebuilds markers
5. User's own pin marker stays on top (existing behavior preserved)

### B. Layout Fixes by Severity

#### B1. Row Overflow (Expanded/Flexible wrapping) — 30+ locations

| Screen | Lines | Issue |
|--------|-------|-------|
| citizen_home_screen | 580, 668, 807 | Unconstrained Row children |
| citizen_profile_screen | 431, 720 | Dialog title + header Row |
| emergency_detail_screen | 87, 233, 518 | Header, ETA card, timeline |
| live_tracking_screen | 435, 484, 515, 618 | Vehicle info, stats, buttons |
| my_reports_screen | 127, 324, 392 | Header, card header, footer |
| dispatcher_profile_screen | 346-365 | _buildSettingRow label+value |
| dispatcher_notifications_screen | 29-91 | Header Row |
| dispatcher_allocation_screen | 81-109, 488-502, 617-630 | Banner, vehicle, button |
| dispatcher_dashboard_screen | 436-455 | ListTile title Row |
| dispatcher_vehicles_screen | 278-292 | Vehicle card Row |
| dispatcher_map_screen | 579-601 | Vehicle sheet header |
| driver_dashboard_screen | 279-305 | Category + StatusChip |
| driver_history_screen | 118-148 | Inner Row + timestamp |
| driver_mission_screen | 180-206 | Step progression Row |
| driver_navigation_screen | 346-382 | Bottom ETA card |
| driver_notifications_screen | 29-91 | Header Row |
| driver_profile_screen | 341-360 | _buildRow label+value |
| admin_reports_screen | 122-154, 319-338 | 3-card Row, progress bar |
| admin_resources_screen | 246-258 | Item name + StatusChip |
| admin_staff_screen | 429-460 | User name + role badge |
| admin_vehicles_screen | 368-382 | License plate + StatusChip |
| map_screen | 575-600 | Responder preview Row |
| profile_screen | 66-102, 231-251, 268-296 | Name Row, ICE header, contacts |
| incident_detail_screen | 319-343 | Reporter + date Row |

#### B2. Text Overflow Handling — 35+ locations

Add `overflow: TextOverflow.ellipsis` and `maxLines: 1` to all unbounded `Text` widgets in tight Row/Column contexts. Full list in audit above.

#### B3. Missing SafeArea — 25+ screens

All screens rendered inside `RoleShell` tabs that lack their own `AppBar` need `SafeArea` wrapping at body level:
- All 6 citizen screens (except notifications_screen which has AppBar)
- All 7 dispatcher screens
- All 6 driver screens
- All 6 admin screens
- Auth screens (login, register, forgot_password): add SafeArea or respect MediaQuery.padding

#### B4. Missing ScrollView — 4 locations

| Screen | Lines | Issue |
|--------|-------|-------|
| dispatcher_vehicles_screen | 40-113 | Bottom sheet Column needs SingleChildScrollView |
| dispatcher_map_screen | 433-555, 557-618 | Emergency + vehicle bottom sheets |
| admin_resources_screen | 42-132 | Add resource dialog Form |
| admin_vehicles_screen | 64-127 | Add vehicle dialog Form |

#### B5. Hardcoded Heights — 5 locations

| Screen | Lines | Issue |
|--------|-------|-------|
| emergency_detail_screen | 299 | Map SizedBox(height: 200) — acceptable, leave as-is |
| live_tracking_screen | 383 | FAB bottom: 230 collides with card |
| dispatcher_map_screen | 252-290 | Banner/filter bar overlap at top: 60 |
| driver_navigation_screen | 175-179 | MapZoomControls top: 70 collides with guidance card |
| admin_dashboard_screen | 194-205 | GridView childAspectRatio clips on large font |

## Success Criteria

1. Selecting any emergency category on Report Emergency screen renders matching emergency markers on the map
2. Switching categories updates markers immediately
3. User's own location pin remains visible and tappable
4. No `RenderFlex overflowed` errors on 360px width emulator across all screens
5. No text clipping in tight Row/Column layouts
6. No UI elements hidden behind status bar, notch, or gesture navigation bar
7. All bottom sheets and dialogs scroll when content exceeds viewport
8. `flutter analyze` passes with 0 issues
9. `flutter build apk --release` succeeds
10. All existing tests pass

## Open Questions

None. Scope, data model, and boundaries are established.
