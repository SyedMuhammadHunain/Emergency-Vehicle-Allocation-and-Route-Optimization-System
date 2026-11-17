# Implementation Plan: Map Category Markers & App-Wide Layout Fix

## Overview

Two parallel workstreams: (1) add category-filtered emergency markers to Report Emergency map, (2) fix layout/structural issues across all 37 screens. Map markers depend on a new MockRepository method; layout fixes are independent per screen group and parallelizable.

## Architecture Decisions

- **MockRepository category filter**: Add `getEmergenciesByCategory(String category)` returning `List<DemoEmergency>`. Keeps filtering in repository layer, not scattered in UI.
- **Marker rendering**: Use existing `DemoEmergency.location` (LatLng) and `DemoEmergency.category` to build colored `Marker` widgets in `report_emergency_screen.dart`. Distinct icon/color per category, matching existing palette.
- **Layout fix pattern**: Wrap unconstrained `Text` in `Flexible` + `overflow: TextOverflow.ellipsis`. Wrap body content in `SafeArea`. Add `SingleChildScrollView` to unscrollable bottom sheets/dialogs. No visual redesign.
- **SafeArea strategy**: Screens inside `RoleShell` tabs have no AppBar. Wrap their Scaffold body in `SafeArea` to handle notch/gesture bar. Auth screens with `GradientHeader` get `SafeArea` with `bottom: true` only (top handled by header padding).

## Dependency Graph

```
MockRepository.getEmergenciesByCategory()  (Task 1)
    │
    └── report_emergency_screen.dart markers  (Task 2)

Layout fixes (Tasks 3-9) — all independent, parallelizable
    │
    └── Final verification (Task 10)
```

## Task List

### Phase 1: Map Category Markers
- [x] Task 1: Add `getEmergenciesByCategory()` to MockRepository
- [x] Task 2: Render category-filtered markers on Report Emergency map

### Checkpoint: Map Markers
- [x] Selecting any category shows matching markers on report map
- [x] User pin stays visible and tappable
- [x] `flutter analyze` clean

### Phase 2: Layout Fixes (parallelizable)
- [x] Task 3: Fix citizen screens (6 files)
- [x] Task 4: Fix dispatcher screens (7 files)
- [x] Task 5: Fix driver screens (6 files)
- [ ] Task 6: Fix admin screens (6 files)
- [ ] Task 7: Fix shared screens (map_screen, profile_screen, incident_detail_screen)
- [ ] Task 8: Fix auth screens SafeArea (login, register, forgot_password)

### Checkpoint: Layout
- [ ] No RenderFlex overflow on 360px emulator across all screens
- [ ] `flutter analyze` clean

### Phase 3: Verification
- [ ] Task 9: Full build verification and manual smoke test

### Checkpoint: Complete
- [ ] `flutter analyze` 0 issues
- [ ] `flutter build apk --release` succeeds
- [ ] All existing tests pass

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Wrapping Text in Flexible changes existing layout spacing | Medium | Only add Flexible/Expanded where audit found overflow; preserve padding/margins |
| SafeArea adds unwanted top padding on screens inside RoleShell | Medium | RoleShell already handles top via its own AppBar/nav; only add SafeArea where screens lack AppBar |
| Category markers clutter small map on report page | Low | Use small 28px markers with 0.7 opacity; user pin stays 44px and on top |

## Parallelization

Tasks 3-8 are fully independent. Each touches a different screen group with no shared state. Safe to parallelize across agents.

## Open Questions

None.
