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

1. Fix `wetlandLantern` Pico spawn blockage.
2. Restore reachable path from `wetlandLantern` Pico spawn.
3. Fix `nightGrove` Pico spawn blockage.
4. Restore reachable path from `nightGrove` Pico spawn.
5. Reduce repeated Pico spawn occlusion risks in `forestShrine`.
6. Reduce repeated Pico route occlusion risks in `forestShrine`.
7. Reduce repeated Pico spawn/route occlusion risks in `aprilDense`.
8. Review water-contact failures in `wetlandLantern`.
9. Add approach tiles for disconnected or hard-to-read structures.
10. Continue perimeter forest densification without crowding Pico routes.

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

- `static maps 5 / projection scenarios 10 / errors 26 / warnings 366 / actions 392 / high 113`
