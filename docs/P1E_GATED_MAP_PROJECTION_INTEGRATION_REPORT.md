# P1E Gated Map Projection Integration Report

Date: 2026-07-03
Branch: `p1-world-richness-integration`
Start commit: `99d500c P1 world projection pipeline, map remediation, and debug preview`

## Goal

Rehearse production-style `MapView` consumption of memory-derived `WorldStateProjection`
behind a DEBUG/runtime gate, without changing normal map behavior.

This pass is not a production rollout. Projection remains opt-in and DEBUG-gated.

## Baseline

- Debug simulator build before edits: succeeded.
- P0 acceptance before edits: passed 14 / failed 0.
- World audit before edits:
  - static maps: 5
  - projection scenarios: 10
  - errors: 0
  - warnings: 320
  - actions: 320
  - high actions: 55
  - static map warnings: 109
  - projection scenario warnings: 211

## Gate

New DEBUG/runtime flag:

`PICOD_USE_WORLD_PROJECTION_MAP=1`

Default behavior:

- DEBUG without the flag: projection map path is off.
- Release: projection map path is off.
- The gate does not mutate memory.
- The gate is independent of the P1D synthetic preview flag:
  `PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1`.

## Files Changed

- `picod/WorldProjectionRuntimeGate.swift`: DEBUG/runtime projection gate and render-state summary.
- `picod/DevTestMode.swift`: exposes the gate through `DevTestMode.useWorldProjectionMap`.
- `picod/ContentView.swift`: resolves current-memory projection in the parent, validates it, adapts placements, passes runtime props/animals to `MapView` when the gate is on, and keeps the P1D preview route ahead of the empty-state placeholder.
- `docs/P1E_GATED_MAP_PROJECTION_INTEGRATION_REPORT.md`: this report.
- `docs/P1E_MAP_PROJECTION_VISUAL_QA.md`: gated projection visual QA checklist and smoke results.

## MapView Boundary

`MapView` remains a renderer. It does not read:

- `PicodMemoryStore`
- `StoryCardStore`
- `LifeAlbumStore`
- `CycleRecordStore`
- `EraMemoryStore`
- raw JSON databases

The integration path is:

Canonical memory in `ContentView`
-> `WorldSignalResolver.resolveToday(...)`
-> `WorldStateProjector.project(...)`
-> `WorldMapValidator.validate(projection, baseMap:)`
-> `WorldProjectionMapAdapter.placementPlan(for:)`
-> `MapView(runtimeProps:runtimeAnimals:)`

When the gate is off, `ContentView` passes the same `worldSimulation.runtimeProps`
and `worldSimulation.runtimeAnimals` as before.

When the gate is on and validation has zero errors, `ContentView` passes:

- base runtime props + projected props
- base runtime animals + projected animals

This preserves the existing static world while layering projection output.

## Fallback Rules

Projection mode falls back to the existing map behavior when:

- the base map is missing
- projection validation reports one or more errors
- the resolver/projector cannot produce renderable placement output

Warnings are allowed to render in DEBUG gated mode and are surfaced through a
small DEBUG-only overlay.

Empty memory is handled through `WorldSignalResolver.resolveToday(...)`, which
returns an empty/missing-today signal bundle. This gives gated mode a
fresh-Day-1 style projection instead of forcing `MapView` to read stores.

## DEBUG Status

When `PICOD_USE_WORLD_PROJECTION_MAP=1`, the map area shows a DEBUG-only status
badge with:

- projection/fallback state
- projected element count
- validation warning count
- validation error count

This badge is not shown in normal mode.

## Smoke Launch Results

| Mode | Flags | Result | Notes |
| --- | --- | --- | --- |
| Normal app | none | Passed | Gate off; no projection badge; empty app state kept existing empty-world placeholder. |
| P1D preview | `PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1` | Passed | World Richness Audit / Projection Scenarios panel visible on fresh empty app state. |
| P1E gated map | `PICOD_USE_WORLD_PROJECTION_MAP=1` | Passed | Current-memory projection rendered with DEBUG badge: elements 1 / warnings 21 / errors 0. |
| Combined | both flags | Passed | Preview route and gated map flag launched together without crash. |

## Final Validation

- `git diff --check`: passed.
- Debug simulator build: succeeded.
- P0 acceptance: passed 14 / failed 0.
- World audit: errors 0 / warnings 320 / actions 320 / high 55.
- Normal smoke launch: passed.
- P1D preview smoke launch: passed.
- P1E gated projection smoke launch: passed.
- Combined smoke launch: passed.

Commands run:

```sh
git diff --check
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
xcrun simctl install B862520B-F900-4497-914A-DE36E90DFF3B /tmp/picod_build/Build/Products/Debug-iphonesimulator/picod.app
SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
SIMCTL_CHILD_PICOD_RUN_WORLD_RICHNESS_AUDIT=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
SIMCTL_CHILD_PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
SIMCTL_CHILD_PICOD_USE_WORLD_PROJECTION_MAP=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
SIMCTL_CHILD_PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1 SIMCTL_CHILD_PICOD_USE_WORLD_PROJECTION_MAP=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Screenshots captured for local verification:

- `/tmp/p1e-gated-projection.png`: DEBUG badge visible only with gated projection map enabled.
- `/tmp/p1e-normal-map.png`: no DEBUG badge with normal gate-off launch.
- `/tmp/p1e-p1d-preview-fixed.png`: P1D preview panel visible after preserving debug preview priority.
- `/tmp/p1e-gated-projection-fixed.png`: current-memory projection rendered after preview priority fix.
- `/tmp/p1e-normal-map-fixed.png`: gate-off normal launch still has no DEBUG badge.

## Remaining Warnings

P1E intentionally does not fix or silence the existing 320 warnings / 55 high
actions. Those remain world polish backlog, not projection integrity blockers.

Current warning categories remain:

- route readability polish
- visual occlusion risk
- density imbalance
- habitat mismatch
- decorative grounding
- validator threshold tuning
- projection placement refinement

## P1F Readiness

P1F Memory Drawer <-> Map evidence linking is safe to consider if final
validation keeps:

- P0 acceptance passed 14 / failed 0
- world audit errors 0
- normal MapView behavior unchanged with gate off
- `MapView` free of direct store coupling
