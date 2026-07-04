# P1I Targeted Warning Remediation Report

Date: 2026-07-03

## Baseline

- Branch: `p1-world-richness-integration`
- Starting commit: `bc01afa P1 world projection evidence UX and art-direction review`
- Working tree before edits: clean.
- Deleted files before edits: none.
- `git diff --check` before edits: passed.
- Debug simulator build before edits: passed.
- P0 acceptance before edits: `passed=14 failed=0`.
- World audit before edits: `static maps 5 / projection scenarios 10 / errors 0 / warnings 320 / actions 320 / high 55`.
- Static map breakdown before edits: `errors 0 / warnings 109`.
- Projection scenario breakdown before edits: `errors 0 / warnings 211`.
- Evidence-link audit before edits: `unresolved 0 / duplicate anchors 0 / locked leaks 0 / missing evidence 0`.
- Evidence-copy audit before edits: `checked 10 / failed 0`.

## Goal

P1I targeted warning remediation is not a content expansion pass. The goal was
to reduce the route and spawn visual readability warnings identified in P1H
without changing validator policy, adding map variants, adding storylines, or
making projection rendering a normal-user path.

## Changes Made

All code changes were coordinate-level map placement edits in
`picod/full_test_map.swift`.

- Moved shared lower-garden houses and one shared cherry canopy away from
  common Pico route bands.
- Moved `forestShrine` lower-route canopy away from the shrine route.
- Moved `wetlandLantern` lower-left canopy and large tree anchors outward while
  preserving wetland density.
- Moved `villageMarket` lower-left canopy, a small house, and one shed away
  from Pico spawn and route bands.
- Moved `nightGrove` route-adjacent canopy and small house anchors outward
  while keeping the lamplighter path and grove density.

No validator severity was downgraded. No warning was hidden. No production
projection gate was enabled.

## Error And Warning Classification

| Map variant | Scenario | Message / Coordinate | Severity | Category | Root Cause | Fix Strategy | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `forestShrine` | static and forest-backed projection scenarios | spawn risk around `x10 y22` | high before P1I | Pico spawn visual occlusion | Shared lower-garden house/canopy visual footprints sat too close to Pico's opening route. | Move shared structures upward/outward and move lower shrine canopy off the route edge. | Resolved; no high remains. |
| `forestShrine` | static and forest-backed projection scenarios | route risk around `x17 y21`, `x18 y25` | high before P1I | Route visually occluded | Tall structure/canopy silhouettes crowded the shrine route. | Move right/lower visual-risk anchors away from route bands. | Resolved; no high remains. |
| `wetlandLantern` | static and `day4RainyUmbrellaTrace` | spawn risks near `x4 y24`, `x5 y21`, `x8 y22` | high before P1I | Pico spawn visual occlusion | Rainy lower-left canopy sat too close to the wetland spawn pocket. | Push canopy anchors farther left/down and move the large lower tree outward. | Resolved; no high remains. |
| `wetlandLantern` | static and `day4RainyUmbrellaTrace` | route risks near `x4 y24`, `x10 y24` | high before P1I | Route visually occluded | Wetland identity props crowded the playable lower path. | Keep the wetland mood but open the route silhouette. | Resolved; no high remains. |
| `nightGrove` | static and `day5NightLamplighterTrace` | route risks near `x12 y24`, `x8 y20`, `x6 y21` | high before P1I | Route visually occluded | Grove canopy and a small house competed with the lamplighter route. | Move canopy/structure anchors outward while preserving lamps as the visual rhythm. | Resolved; no high remains. |
| `villageMarket` | static | route risk near `x11 y15` after first pass | high during P1I | Route visually occluded | A moved shed still sat too close to the market's common route. | Move the shed to a left-side market pocket connected to existing ground. | Resolved; no high remains. |
| `aprilDense` | static | route risk near `x10 y20` after first pass | high during P1I | Route visually occluded | A shared cherry canopy remained in the dense spring route band. | Move the canopy upward into a non-critical garden pocket. | Resolved; no high remains. |
| `wetlandLantern` | projection | invalid habitat count remains `2` | medium backlog | Animal habitat mismatch | Wetland projection placement still needs animal/visitor habitat tuning. | Defer to projection placement refinement; evidence integrity is clean. | Deferred. |
| multiple | static/projection | missing approach tiles and disconnected structures | medium backlog | Building/path connection | Some structures remain decorative rather than fully grounded. | Add approach/connection polish in P1J where it improves map belonging. | Deferred. |
| multiple | static/projection | terrain mismatch under decorative props | low backlog | Decorative grounding | Some existing props sit on imperfect terrain. | Defer unless it affects Pico readability or story trace grounding. | Deferred. |

## After P1I Audit

Observed world audit after targeted remediation:

- Static maps: 5
- Projection scenarios: 10
- Total errors: 0
- Total warnings: 321
- Total actions: 321
- High actions: 0
- Static map errors/warnings: `0 / 95`
- Projection scenario errors/warnings: `0 / 226`

Integrity checks remained clean:

- Evidence-copy audit: `checked 10 / failed 0`
- Evidence-link audit: `anchors 35 / unresolved 0 / duplicate anchors 0 / locked leaks 0 / missing evidence 0`
- Unknown catalog IDs: 0
- Ungrounded projected elements: 0
- Projection path obstruction count: 0
- Locked EraMemory echo leak: 0

The total warning count increased by one compared with P1H, but the warning
shape changed materially: all 55 high-priority route/spawn readability actions
were cleared. Remaining warnings are medium/low structure connection, terrain
grounding, perimeter density, and projection habitat polish.

## Map Identity Notes

### forestShrine

The shrine axis, water/reflection band, and forest density are preserved. Edits
opened the route silhouette around Pico rather than turning the shrine into a
sparse layout.

### wetlandLantern

The rainy wetland still has water, reeds, lamps, and low path rhythm. Lower-left
canopy moved outward so Pico and umbrella traces have breathing room.

### nightGrove

Night density and lamplighter rhythm are preserved. Canopy and structure anchors
were moved away from the route, not removed from the grove.

### villageMarket

The market remains busy, but the first readable Pico route is less crowded.
Stalls and structures still sit around the market instead of being flattened
into an empty square.

### aprilDense

The spring map remains dense. The shared canopy adjustment reduced route
occlusion without removing the lower garden's seasonal feel.

## Deferred P1J Candidates

1. Add structure approach tiles where buildings currently feel decorative.
2. Tune wetland animal/visitor habitat placement for rainy projection scenarios.
3. Continue perimeter forest densification outside protected Pico route bands.
4. Reduce medium/low terrain mismatch under important visual story traces.
5. Review projection scenario warning increase with screenshot comparison.
6. Polish DEBUG preview ergonomics for repeated art reviews.

## Validation Commands

Debug simulator build:

```sh
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
```

P0 acceptance:

```sh
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

World audit:

```sh
env SIMCTL_CHILD_PICOD_RUN_WORLD_RICHNESS_AUDIT=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

## Safety Confirmation

- No reset, rebase, discard, or force operation was performed.
- No new Pico forms were added.
- No new storylines were added.
- No map variants were added.
- No folklore content was expanded.
- Normal `MapView` behavior remains unchanged with projection gate off.
- `MapView` still does not read memory stores directly.
