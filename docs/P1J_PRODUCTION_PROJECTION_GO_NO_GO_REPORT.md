# P1J Production Projection Go/No-Go Report

Date: 2026-07-04

## Decision

**CONDITIONAL GO** for limited internal production-gated projection testing.

**NO-GO** for default-on production projection, App Store release default-on
projection, or external TestFlight default-on projection.

The data path is stable enough for internal gated review: build is green, P0
acceptance is green, world audit errors are zero, high actions are zero,
evidence links are clean, evidence copy is clean, and gated smoke launches do
not crash. The remaining risk is visual and device-readiness, not data
integrity.

## Baseline Verification

- Branch: `p1-world-richness-integration`
- Commit: `037f3aa3afd4228086572f9a7205f0e2d1eb069c`
- Tag at HEAD: `p1i-world-projection-warning-remediation-2026-07-04`
- Working tree before P1J docs: clean.
- Deleted files before P1J docs: none.
- `git diff --check` before P1J docs: passed.

Validation results:

| Check | Result |
| --- | --- |
| Debug simulator build | Passed |
| P0 acceptance | `passed=14 failed=0` |
| World audit | `errors 0 / warnings 321 / actions 321 / high 0` |
| Static maps | `errors 0 / warnings 95` |
| Projection scenarios | `errors 0 / warnings 226` |
| Evidence-copy audit | `checked 10 / failed 0` |
| Evidence-link audit | `anchors 35 / unresolved 0 / duplicate anchors 0 / locked leaks 0 / missing evidence 0` |
| Normal smoke launch | Passed launch smoke |
| `PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1` smoke launch | Passed launch smoke |
| `PICOD_USE_WORLD_PROJECTION_MAP=1` smoke launch | Passed launch smoke |
| Both projection flags smoke launch | Passed launch smoke |

Simulator logs still include known CoreSimulator/UIKit accessibility noise such
as `IOSurfaceClientSetSurfaceNotify failed` and duplicate accessibility class
messages. These were not treated as Picod failures because the harnesses
completed successfully.

## P1I Delta Analysis

| Area | Before | After | Cause | User impact | Go/no-go implication | Follow-up recommendation |
| --- | --- | --- | --- | --- | --- | --- |
| Static warnings | 109 | 95 | P1I moved existing canopy/structure anchors away from common Pico spawn and route bands. | Static maps have less route/spawn crowding. | Supports conditional go for internal gated testing. | Continue with approach-tile and terrain grounding polish. |
| Projection warnings | 211 | 226 | Projection scenarios inherited the updated static maps; clearing highs exposed more medium/low connection and grounding warnings in projected contexts. | No errors, no high actions, but some scenes still need visual review. | Does not block internal gated testing; blocks default-on production. | Review medium/low clusters with screenshots before production rollout. |
| Total warnings | 320 | 321 | Static warnings dropped by 14; projection warnings rose by 15. | Overall warning volume is nearly flat, but severity changed materially. | Conditional go because severity moved from high route/spawn risk to medium/low polish. | Use warning policy in `P1J_REMAINING_WARNING_POLICY.md`. |
| High actions | 55 | 0 | Root cause was fixed through coordinate-level placement changes, not severity downgrade. | Pico readability and route silhouettes are safer in audited maps. | Required go criterion satisfied. | Do not reintroduce route/spawn highs during P1K/P2 work. |
| Evidence-copy audit | failed 0 | failed 0 | No user-facing evidence copy regressions. | Normal Memory Drawer trace copy remains calm and non-technical. | Supports internal gated testing. | Keep copy audit in world audit. |
| Evidence-link audit | clean | clean | Story/cycle/era anchors remain evidence-backed. | Story traces remain explainable without lore dumping. | Supports internal gated testing. | Keep locked EraMemory leak checks. |
| Map identity | Preserved but route-crowded | Preserved with opened routes | P1I moved props outward rather than deleting map identity. | Maps still read as shrine, wetland, grove, market, and dense garden. | Supports conditional go. | Validate visually on real device before external alpha. |
| Wetland habitat warnings | Present | Still present | P1I did not alter projection placement/habitat rules. | Rainy story traces may still feel slightly rule-placed. | Blocks default-on production polish, not internal gated review. | Tune wetland animal/visitor habitat in a dedicated pass. |

## Criteria Review

| Criterion | Status | Notes |
| --- | --- | --- |
| Debug build succeeds | GO | Build passed. |
| P0 acceptance passes | GO | `passed=14 failed=0`. |
| World audit errors remain 0 | GO | Latest audit errors: 0. |
| High actions remain 0 | GO | Latest audit high actions: 0. |
| Evidence-link audit remains clean | GO | Unresolved, duplicate anchors, locked leaks, and missing evidence are all 0. |
| Evidence-copy audit remains clean | GO | `failed 0`. |
| Normal mode unchanged with gate off | GO | Normal smoke launch passed; P1H recorded no projection/debug badge in normal mode. |
| Gated projection renders current-memory map without crash | GO | `PICOD_USE_WORLD_PROJECTION_MAP=1` smoke launch passed. |
| `MapView` does not read memory stores directly | GO | `MapView.swift` has no direct store/raw JSON references in the checked terms. |
| Locked EraMemory does not leak visible anchors | GO | Evidence-link audit locked leaks: 0. |
| StoryCard traces have evidence | GO | Missing evidence: 0. |
| Projection fallback works | GO | Runtime state keeps explicit fallback reasons and audit scenarios include corrupt/partial memory fallback with errors 0. |
| No raw debug/audit/projection terms appear in normal Memory Drawer copy | GO | Evidence-copy audit failed 0; debug terms are limited to DEBUG surfaces/copy validation fixtures. |
| P1H story tone remains acceptable | GO | P1H copy review passed for umbrella, lamplighter, and mirror traces. |
| P1I did not flatten map identity | GO | P1I report documents identity preservation by map. |

No NO-GO criterion was triggered for internal gated testing.

## Limited Internal Production-Gated Definition

Limited internal production-gated testing means:

- Gate name: `PICOD_USE_WORLD_PROJECTION_MAP`.
- Default state: off.
- Release behavior: off; `WorldProjectionRuntimeGate.isEnabled` returns false
  outside DEBUG.
- DEBUG behavior: projection map rendering can be enabled with
  `SIMCTL_CHILD_PICOD_USE_WORLD_PROJECTION_MAP=1`.
- Existing synthetic preview remains available with
  `SIMCTL_CHILD_PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1`.
- Current-memory projection may be tested by internal developers/testers only.
- Normal user path remains the existing static/default map unless the internal
  gate is explicitly enabled.
- Memory Drawer evidence copy remains normal production UX; map projection
  rendering remains gated.
- If projection validation reports errors, the runtime path must fall back to
  static/default map.

Not allowed:

- Default-on App Store or external TestFlight projection.
- User-facing projection switch.
- Normal-mode DEBUG badge.
- `MapView` reading memory stores or raw databases directly.
- New forms, storylines, map variants, or folklore expansion as part of the
  gate.

Rollback plan:

1. Leave `PICOD_USE_WORLD_PROJECTION_MAP` unset.
2. If an internal gated run regresses, terminate the app and relaunch without
   the flag.
3. If a release build is created, projection remains off by compile-time gate.
4. Keep the static/default map path available until real-device QA and visual
   warning review are complete.

## Scenario Review

| Scenario | Decision | Reason | Required follow-up |
| --- | --- | --- | --- |
| Fresh Day 1 | CONDITIONAL GO | Empty/fresh projection is valid and quiet; unresolved-location first-load polish still needs visual review. | Review on real device and small screens. |
| Day 1 warm indoor | CONDITIONAL GO | Photo trace path is evidence-backed and no high route/spawn warnings remain. | Compare visual warmth against screenshots before default-on. |
| Day 4 rainy umbrella | CONDITIONAL GO | Story evidence is clean and wetland highs are cleared; habitat warnings remain. | Tune wetland animal/visitor habitat and water-edge grounding. |
| Day 5 night lamplighter | CONDITIONAL GO | Lamplighter evidence is clean and nightGrove route highs are cleared. | Visual review lamps/grove density on hardware. |
| Day 7 mirror closure | CONDITIONAL GO | Mirror evidence and Era/closure rules remain clean. | Keep shrine/reflection echo subtle; review medium structure warnings. |
| Completed LifeAlbum | CONDITIONAL GO | Retrospective trace is valid but still visually minimal. | Art-direct LifeAlbum marker after default route is fully reviewed. |
| Completed CycleRecord | CONDITIONAL GO | Cycle markers require cycle evidence and audit passes. | Keep world-level marker distinct from LifeAlbum during visual pass. |
| Low participation | GO for internal gate | Tone remains quiet rather than punitive. | Preserve non-punitive copy and avoid decay language. |
| Locked EraMemory | GO | Locked leaks remain 0. | Keep hidden/quiet until unlock. |
| Unlocked EraMemory | CONDITIONAL GO | Rare echo is evidence-backed and unlocked only after boundary. | Review on hardware before external alpha; do not explain reset. |

## Remaining Risks

- Projection warning count rose from 211 to 226 after P1I.
- Total warning count is nearly unchanged at 321.
- Remaining warnings are medium/low, but still meaningful: structure approach
  tiles, disconnected structures, wetland habitat tuning, perimeter density,
  terrain grounding, and screenshot review of projection warning clusters.
- Launch smoke checks prove startup health, not frame-rate, touch, camera, or
  long-session behavior.
- P0 real-device QA remains blocked by unavailable physical iPhone hardware.

## Real-Device Caveat

P0 real-device QA is still blocked by unavailable physical iPhone hardware.
Projection cannot be considered external-ready until physical iPhone QA is
completed.

Still unverified on hardware:

- camera capture path
- photo library fallback path
- location permission behavior
- weather/location unavailable behavior on real device
- real-device projection performance
- real-device screenshots for fresh, rainy, night, mirror, cycle, and Era states
- small-screen touch/readability in Memory Drawer and map projection modes

## Go/No-Go Summary

**CONDITIONAL GO** for internal gated projection testing with
`PICOD_USE_WORLD_PROJECTION_MAP=1`.

**NO-GO** for default-on production projection or external handoff.

The next recommended phase is **P1K internal gated projection visual QA and
real-device readiness**, focused on screenshots, hardware performance, wetland
habitat polish, and structure grounding. Projection should remain off by
default until those pass.

## Safety Confirmation

- No reset, rebase, discard, or overwrite was performed.
- No production default was enabled.
- No map layout remediation was performed in P1J.
- No new Pico forms were added.
- No new storylines were added.
- No new map variants were added.
- No folklore content was expanded.
- `MapView` remains decoupled from memory stores.
