# Picod P1D DEBUG World Projection Preview Report

Date: 2026-07-03
Branch: `p1-world-richness-integration`
Baseline commit: `ae60b48 P1 world projection pipeline and static map blocker remediation`

## Scope

P1D adds a DEBUG-only visual inspection route for memory-driven
`WorldStateProjection` output. Normal production map behavior is unchanged:
`MapView` still receives explicit map/render inputs and does not read
`PicodMemoryStore`, `StoryCardStore`, `LifeAlbumStore`, `CycleRecordStore`, or
`EraMemoryStore`.

## Baseline

Initial checks:

- `git status --short --branch`: clean on `p1-world-richness-integration`.
- `git log -1 --oneline`: `ae60b48 P1 world projection pipeline and static map blocker remediation`.
- `git diff --check`: passed.
- `git ls-files --deleted`: none.

Baseline validation:

- Debug simulator build: succeeded.
- P0 acceptance: `passed=14 failed=0`.
- World audit: `static maps 5 / projection scenarios 10 / errors 0 / warnings 320 / actions 320 / high 55`.
- Static map warnings: 109.
- Projection scenario warnings: 211.

Known remaining high warnings are route/spawn readability risks, mostly:

- `aprilDense` route/spawn occlusion near `x10 y22` and `x12 y19`.
- `forestShrine` route/spawn occlusion near `x10 y22`, `x17 y21`, and
  `x18 y25`.
- `wetlandLantern` spawn/route readability risk near `x4 y24`, `x5 y21`,
  `x8 y22`, and `x10 y24`.
- `nightGrove` route readability risk near `x12 y24`, `x8 y20`, and `x6 y21`.

## Implementation

Added:

- `WorldProjectionDebugScenarios.swift`
  - deterministic DEBUG synthetic memory scenarios;
  - each scenario produces `WorldSignalBundle`, `WorldStateProjection`,
    `WorldElementPlacementPlan`, validation report, action list, and summary
    counts;
  - synthetic memory is explicitly marked in `debugSummary`.

Updated:

- `ObjectGalleryDebugView.swift`
  - adds `WorldProjectionPreviewDebugView`;
  - includes a scenario picker, rendered map preview, source-colored projection
    markers, projection counts, evidence IDs, story echoes, and warning/action
    rows;
  - uses the existing `WorldProjectionMapAdapter` and `MapView` runtime
    prop/animal inputs.
- `DevTestMode.swift`
  - adds DEBUG-only environment access:
    `PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1`.
- `WorldMapRichnessAudit.swift`
  - exposes the existing action conversion helper for debug preview reporting.

## Preview Scenarios

| Scenario | Base map | Expected projection role | Elements | Story | Cycle | Era |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| `freshDay1Empty` | `forestShrine` | quiet first-day stillness | 1 | 0 | 0 | 0 |
| `day1WarmIndoorCapture` | `forestShrine` | warm photo + Pico hatch trace | 2 | 0 | 0 | 0 |
| `day4RainyUmbrellaTrace` | `wetlandLantern` | rainy water-edge story trace | 3 | 1 | 0 | 0 |
| `day5NightLamplighterTrace` | `nightGrove` | night path lamp trace | 3 | 1 | 0 | 0 |
| `day7MirrorClosure` | `forestShrine` | shrine/reflection closure trace | 2 | 1 | 0 | 0 |
| `completedLifeAlbum` | `forestShrine` | Pico-centric retrospective marker | 1 | 0 | 0 | 0 |
| `completedCycleRecord` | `forestShrine` | world-level cycle marker | 1 | 0 | 1 | 0 |
| `lowParticipationLife` | `forestShrine` | sparse stillness marker | 1 | 0 | 0 | 0 |
| `lockedEraMemory` | `forestShrine` | locked Era, no echo | 0 | 0 | 0 | 0 |
| `unlockedEraMemory` | `forestShrine` | rare Era echo with evidence | 2 | 1 | 0 | 1 |

## Preview UI Location

The preview lives in the existing DEBUG object/world audit panel:

```sh
SIMCTL_CHILD_PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1 xcrun simctl launch --terminate-running-process B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Normal users do not see this route. The flag is ignored outside DEBUG builds.

## MapView Adapter Status

No new production `MapView` adapter was added in P1D.

The preview uses the adapter that already existed:

- `WorldProjectionMapAdapter.placementPlan(for:)`
- `MapView(runtimeProps:runtimeAnimals:)`

This keeps projection rendering optional and explicit. `MapView` remains
decoupled from memory stores.

## Visual Readability Findings

Current preview checks:

- Pico spawn remains visible in all required scenarios.
- Projected story echoes carry evidence IDs.
- Cycle marker appears only in `completedCycleRecord`.
- Era echo count is 0 for `lockedEraMemory`.
- Era echo appears only in `unlockedEraMemory`.
- Low participation projects one quiet stillness marker, not a punishment state.
- Fresh Day 1 projects as intentionally sparse.
- Day 4 rain uses the wetland map and water-edge trace.
- Day 5 lamplighter uses the night grove and lamp-path trace.
- Day 7 mirror closure uses shrine/reflection evidence.
- No scenario introduces projection validation errors.

Remaining visual concerns are warning-level:

- route/spawn occlusion risk remains visible in dense maps;
- wetland scenario still needs animal/habitat placement review;
- some structures need clearer approach tiles;
- some decorative terrain mismatches remain.

## Validation

Final validation commands:

```sh
git diff --check
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
env SIMCTL_CHILD_PICOD_RUN_WORLD_RICHNESS_AUDIT=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Results:

- `git diff --check`: passed.
- Debug simulator build: succeeded.
- P0 acceptance: `passed=14 failed=0`.
- World audit: `static maps 5 / projection scenarios 10 / errors 0 / warnings 320 / actions 320 / high 55`.
- DEBUG projection preview smoke launch:
  `SIMCTL_CHILD_PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1` launched without an app
  crash during the smoke window.

## P1E Readiness

P1E production projection integration is safe to consider only behind a
debug/preview gate first. Hard blockers are cleared, but route readability,
visual occlusion, habitat placement, and approach-tile warnings should remain
visible until production rendering is attempted.

## Non-Changes

- No new Pico forms.
- No new storylines.
- No new map variants.
- No folklore expansion.
- No production `MapView` replacement.
- No direct `MapView` coupling to memory stores.
- No reset, rebase, discard, or force operation.
