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
- P1F current: `static maps 5 / projection scenarios 10 / errors 0 / warnings 320 / actions 320 / high 55`
- P1I current: `static maps 5 / projection scenarios 10 / errors 0 / warnings 321 / actions 321 / high 0`

## P1F Evidence Link Audit

P1F adds an evidence-link audit on top of the existing world richness audit. It
does not change the static or projection baseline counts.

Evidence-link checks:

- Memory Drawer records can resolve soft world trace links from projected
  element evidence.
- StoryCard anchors require story/map trace evidence.
- Cycle marker anchors require cycle evidence.
- Locked EraMemory scenarios do not produce visible era anchors.
- Unlocked EraMemory scenarios can produce remembered rare echo anchors.
- Duplicate anchors are reported instead of ignored.
- Missing projection data falls back to user-facing trace text without crash.

Observed P1F evidence-link audit:

- scenarios: 10
- anchors: 35
- unresolved links: 0
- duplicate anchors: 0
- locked leaks: 0
- missing evidence: 0

The remaining 320 warnings / 55 high actions are still the P1 world backlog,
not evidence-link failures.

## P1G Evidence Copy Audit

P1G adds a deterministic evidence-copy audit line to the world audit console. It
is additive and does not change static map counts, projection scenario counts,
warning counts, action counts, or evidence-link counts.

Evidence-copy checks:

- umbrella, lamplighter, and mirror story copy exists
- DailyLifeRecord fallback copy exists
- LifeAlbum retrospective copy exists
- CycleRecord marker copy exists
- locked EraMemory remains quiet
- unlocked EraMemory shows one rare echo line
- missing projection produces fallback copy
- normal-user copy avoids raw debug/audit terms

Observed P1G evidence-copy audit:

- checked: 10
- failed: 0

Projection rendering remains gated. Normal Memory Drawer UI receives only
textual world trace fragments.

## P1H Art Direction Review

P1H reviewed screenshots/manual scenario notes for:

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

P1H did not change audit counts:

- static maps: 5
- projection scenarios: 10
- total errors: 0
- total warnings: 320
- total actions: 320
- high actions: 55

Evidence integrity remained clean:

- evidence-link unresolved links: 0
- duplicate anchors: 0
- locked leaks: 0
- missing evidence: 0
- evidence-copy failures: 0

P1H art-direction result:

- Normal mode has no projection/debug badge.
- Projection rendering remains gated.
- `MapView` still does not read memory stores directly.
- Memory Drawer world trace copy is production-safe for P1H.
- Story copy stays subtle and avoids lore dumps.
- Locked EraMemory does not leak.
- Low participation reads quiet rather than punitive.

Top 10 P1I candidates after P1H:

1. Reduce `forestShrine` spawn occlusion risk around `x10 y22`.
2. Reduce `forestShrine` route occlusion around `x17 y21` and `x18 y25`.
3. Reduce `wetlandLantern` spawn occlusion near `x4 y24`, `x5 y21`, and `x8 y22`.
4. Reduce `wetlandLantern` route occlusion near `x4 y24` and `x10 y24`.
5. Reduce `nightGrove` route occlusion near `x12 y24`, `x8 y20`, and `x6 y21`.
6. Reduce `villageMarket` spawn/route occlusion around `x7 y21`, `x6 y23`, and `x12 y17`.
7. Reduce `aprilDense` spawn/route occlusion around `x10 y22` and `x12 y19`.
8. Densify sparse perimeter forest only outside protected Pico route bands.
9. Add approach tiles for disconnected structures where they improve map belonging.
10. Tune wetland projected animal/visitor habitat placement.

Production projection remains blocked by visual warning backlog, not by data
integrity:

- Route/spawn visual occlusion warnings must be reduced before projection
  rendering becomes a normal-user path.
- Wetland habitat placement needs tuning before rainy story echoes feel fully
  grounded.
- DEBUG preview UI is useful but not art-review polished on small screens.

Safe to defer:

- Minor terrain mismatch warnings under decorative props.
- Non-critical decorative grounding issues.
- Perimeter density changes that could crowd Pico routes.
- Copy polish suggestions that are not raw-term leaks.

## P1I Targeted Warning Remediation

P1I targeted the high-priority route and spawn visual readability warnings from
P1H. It changed only existing map prop coordinates in `full_test_map.swift`.
No validator thresholds were lowered, no warnings were hidden, and projection
rendering remains gated.

Observed combined console result after P1I:

- static maps: 5
- projection scenarios: 10
- total errors: 0
- total warnings: 321
- total actions: 321
- high actions: 0

Breakdown:

- static map errors/warnings: 0 / 95
- projection scenario errors/warnings: 0 / 226

Resolved high-priority clusters:

- `forestShrine`: spawn occlusion around `x10 y22`.
- `forestShrine`: route occlusion around `x17 y21` and `x18 y25`.
- `wetlandLantern`: lower-left spawn/route occlusion around `x4 y24`,
  `x5 y21`, `x8 y22`, and `x10 y24`.
- `nightGrove`: lamplighter-route occlusion around `x12 y24`, `x8 y20`, and
  `x6 y21`.
- `villageMarket`: route crowding around `x7 y21`, `x6 y23`, and `x12 y17`.
- `aprilDense`: route/spawn crowding around `x10 y22`, `x12 y19`, and
  `x10 y20`.

Evidence integrity remained clean:

- evidence-link unresolved links: 0
- duplicate anchors: 0
- locked leaks: 0
- missing evidence: 0
- evidence-copy failures: 0

Remaining warnings after P1I are not route/spawn blockers. They are medium/low
backlog:

- structure approach tiles and disconnected structures
- decorative terrain mismatch
- perimeter forest sparse warnings outside protected route bands
- wetland projected animal/visitor habitat tuning
- projection scenario polish that should be reviewed with screenshots

Top P1J candidates after P1I:

1. Add approach tiles for shrine, market, wetland, and grove structures where
   they improve map belonging.
2. Tune wetland animal and visitor habitat placement without weakening rain
   mood.
3. Compare projection scenario warning increase against screenshots before
   making more map changes.
4. Densify sparse perimeter forest only outside Pico route protection bands.
5. Polish decorative terrain mismatch for story-relevant traces first.
6. Keep production projection gated until medium connection and habitat warnings
   are reviewed visually.
