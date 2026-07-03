# Picod P1 World Audit Baseline

## Baseline Source

This file tracks the P1 world richness audit before and after the P1B world
state projection pass.

Console hook:

```sh
env SIMCTL_CHILD_PICOD_RUN_WORLD_RICHNESS_AUDIT=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

## P1A Static Map Baseline

P1A established the initial static map audit:

- maps: 5
- errors: 13
- warnings: 116
- actions: 129
- high actions: 34
- `forestShrine`: errors 0 / warnings 25

Known static blockers:

- `wetlandLantern`: Pico spawn blocked and no reachable tiles.
- `nightGrove`: Pico spawn blocked and no reachable tiles.

## P1B Combined Baseline

P1B adds memory-driven projection scenario audit while preserving the static map
audit.

Latest combined console result:

- static maps: 5
- projection scenarios: 10
- total errors: 26
- total warnings: 366
- total actions: 392
- high actions: 113

Breakdown:

- static map errors/warnings: 13 / 116
- projection scenario errors/warnings: 13 / 250

The projection scenario errors are inherited from static base maps, not from
missing projection evidence:

- `day4RainyUmbrellaTrace` uses `wetlandLantern` and inherits blocked spawn /
  unreachable path errors.
- `day5NightLamplighterTrace` uses `nightGrove` and inherits blocked spawn /
  unreachable path errors.

## P1C Static Map Blocker Remediation

P1C fixes the inherited base-map blockers instead of suppressing validator
errors.

Latest combined console result after P1C:

- static maps: 5
- projection scenarios: 10
- total errors: 0
- total warnings: 320
- total actions: 320
- high actions: 55

Breakdown:

- static map errors/warnings: 0 / 109
- projection scenario errors/warnings: 0 / 211

Resolved blockers:

- `wetlandLantern`: moved Pico spawn to a valid path tile and added shallow
  water contact pockets for existing wetland bridge, dock, and reed props.
- `nightGrove`: moved Pico spawn to a valid path tile inside the lantern route.
- `day4RainyUmbrellaTrace`: projection errors cleared through the base
  `wetlandLantern` fix.
- `day5NightLamplighterTrace`: projection errors cleared through the base
  `nightGrove` fix.
- Shared lower-route occlusion pressure in `forestShrine` / `aprilDense` was
  reduced by moving lower perimeter tree anchors outward.

Projection-specific checks remain clean:

- unknown catalog IDs: 0
- ungrounded projected elements: 0
- missing evidence/source: 0
- locked EraMemory echo: 0
- projection path obstruction count: 0

Remaining warnings are still actionable backlog, not ignored noise:

- route and spawn visual occlusion risks in dense maps
- perimeter forest sparse warnings in several review maps
- disconnected structures and missing approach tiles
- terrain mismatch warnings under some decorative props
- wetland projected animal habitat warnings for future projection placement
  tuning

## P1D Projection Preview Baseline

P1D adds a DEBUG-only visual preview for memory-driven projection scenarios.
The preview uses deterministic synthetic memory signals and the same
`WorldStateProjector`, `WorldProjectionMapAdapter`, and `WorldMapValidator`
path used by the audit. Normal `MapView` behavior remains unchanged.

P1D does not change the audit totals:

- static maps: 5
- projection scenarios: 10
- total errors: 0
- total warnings: 320
- total actions: 320
- high actions: 55

Preview-only scenarios available in the DEBUG UI:

- `freshDay1Empty`
- `day1WarmIndoorCapture`
- `day4RainyUmbrellaTrace`
- `day5NightLamplighterTrace`
- `day7MirrorClosure`
- `completedLifeAlbum`
- `completedCycleRecord`
- `lowParticipationLife`
- `lockedEraMemory`
- `unlockedEraMemory`

Post-P1D warning classification:

- Route readability polish: high-priority warnings around common Pico routes.
- Visual occlusion risk: tall trees/structures near spawn or route bands.
- Density imbalance: perimeter forest sparse warnings in some map variants.
- Habitat mismatch: wetland projection animal/visitor placement needs tuning.
- Decorative grounding: terrain mismatch under non-critical props.
- Building/path connection: disconnected structures and missing approach tiles.
- Validator threshold: no known false-positive blockers; thresholds should be
  reviewed only after visual preview captures are compared.
- Projection placement refinement: story/cycle/era placement is valid but still
  needs visual taste passes before production rendering.

Top 10 P1E candidates:

1. Reduce `aprilDense` route occlusion around `x10 y22`.
2. Reduce `aprilDense` route occlusion around `x12 y19`.
3. Reduce `aprilDense` spawn occlusion around `x10 y22`.
4. Reduce `forestShrine` route occlusion around `x17 y21`.
5. Reduce `forestShrine` route occlusion around `x18 y25`.
6. Reduce `forestShrine` spawn occlusion around `x10 y22`.
7. Reduce `wetlandLantern` spawn/route occlusion near the lower-left path.
8. Reduce `nightGrove` route occlusion near the lamplighter path.
9. Add approach tiles for shrine/structure props that still feel disconnected.
10. Tune wetland projected animal habitat without weakening water-edge mood.

Warnings intentionally deferred:

- All 55 high actions remain visible; none were downgraded.
- Perimeter forest sparse warnings are deferred until visual density goals are
  balanced against Pico route readability.
- Terrain mismatch warnings are deferred unless they affect route clarity,
  story trace grounding, or Pico readability.
- Projection placement refinement waits for P1D/P1E visual comparison rather
  than speculative map churn.

## Projection Scenario Coverage

Audited scenarios:

- empty fresh install
- Day 1 capture
- Day 4 rainy umbrella trace
- Day 5 night lamplighter trace
- Day 7 mirror closure
- completed Life Album
- completed Cycle Record
- unlocked Era Memory
- low participation Life
- corrupt/partial memory fallback

Projection-specific checks passed in the latest audit:

- unknown catalog IDs: 0
- ungrounded projected elements: 0
- missing evidence/source: 0
- invalid story evidence: 0
- locked EraMemory echo: 0

## Top Priority Backlog

1. Reduce `forestShrine` Pico spawn occlusion risk around `x10 y22`.
2. Reduce `forestShrine` route occlusion risk around `x17 y21` and `x18 y25`.
3. Reduce `aprilDense` route occlusion risk around `x10 y22` and `x12 y19`.
4. Reduce `wetlandLantern` spawn readability risk near `x4 y24`, `x5 y21`,
   and `x8 y22`.
5. Reduce `nightGrove` route readability risk near `x12 y24`, `x8 y20`, and
   `x6 y21`.
6. Add clearer approach tiles for disconnected shrine and structure props.
7. Tune wetland projected animal placement to avoid habitat warnings.
8. Continue perimeter forest densification without crowding Pico routes.
9. Align terrain under decorative props that still report mismatch warnings.
10. Keep projection preview behind validation until remaining high route
    readability warnings are reviewed.

## Not Implemented Intentionally

- Normal MapView rendering does not yet require `WorldStateProjection`.
- Projection adapter output is not fed into production map rendering until base
  maps with blocker spawn/path issues are corrected.
- No new Pico forms were added.
- No new storylines were added.
- No map variants were added.
- No folklore expansion was added.

## Validation Commands

Simulator Debug build:

```sh
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
```

P0 acceptance:

```sh
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Observed result:

- `passed=14 failed=0`
- `daily=49 albums=7 cycles=7 cards=3 eras=1`

World audit:

```sh
env SIMCTL_CHILD_PICOD_RUN_WORLD_RICHNESS_AUDIT=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Observed result:

- P1B baseline: `static maps 5 / projection scenarios 10 / errors 26 / warnings 366 / actions 392 / high 113`
- P1C current: `static maps 5 / projection scenarios 10 / errors 0 / warnings 320 / actions 320 / high 55`
- P1D current: `static maps 5 / projection scenarios 10 / errors 0 / warnings 320 / actions 320 / high 55`
