# P1E Map Projection Visual QA

Date: 2026-07-03
Branch: `p1-world-richness-integration`

## Purpose

This checklist verifies that memory-driven world projection can be rehearsed in
DEBUG without changing normal user map behavior.

Launch modes:

- Normal: no projection flags.
- Synthetic preview: `PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1`.
- Current-memory gated map: `PICOD_USE_WORLD_PROJECTION_MAP=1`.
- Combined: both flags.

## Global Checks

For every preview or gated-map inspection:

- Pico is readable.
- Main route remains readable.
- No critical projection element blocks Pico.
- Story echoes have evidence.
- Cycle marker appears only when cycle data exists.
- Era echo appears only when `EraMemory` is unlocked.
- Projection does not over-clutter the map.
- Visual tone remains quiet.
- Fallback behavior works if projection is invalid.
- Normal mode is unchanged when gate is off.

## Scenario Checklist

| Scenario | Synthetic Preview | Current-Memory Gated Map | Notes |
| --- | --- | --- | --- |
| fresh Day 1 | Listed in preview panel; audit errors 0 | Current memory rendered as empty/missing-today style | Empty memory looked intentional; gated screenshot showed one quiet projected element. |
| day 1 warm indoor capture | Listed in preview panel; audit errors 0 | N/A unless current memory matches | Warm/day trace remains covered by deterministic projection scenario validation. |
| day 4 rainy umbrella trace | Listed in preview panel; audit errors 0 | N/A unless current memory matches | Rain trace remains covered by deterministic projection scenario validation. |
| day 5 night lamplighter trace | Listed in preview panel; audit errors 0 | N/A unless current memory matches | Lamp echo remains covered by deterministic projection scenario validation. |
| day 7 mirror closure | Listed in preview panel; audit errors 0 | N/A unless current memory matches | Mirror trace remains covered by deterministic projection scenario validation. |
| completed LifeAlbum | Listed in preview panel; audit errors 0 | N/A unless current memory matches | Retrospective marker remains covered by deterministic projection scenario validation. |
| completed CycleRecord | Listed in preview panel; audit errors 0 | N/A unless current memory matches | Cycle marker remains covered by deterministic projection scenario validation. |
| low participation Life | Listed in preview panel; audit errors 0 | N/A unless current memory matches | Quiet low-participation state remains covered by deterministic projection scenario validation. |
| locked EraMemory | Listed in preview panel; audit errors 0 | Passed for current-memory locked/empty state | No era echo appeared in current-memory gated screenshot. |
| unlocked EraMemory | Listed in preview panel; audit errors 0 | N/A unless current memory matches | Unlocked echo remains covered by deterministic projection scenario validation. |

## Current-Memory Gated Map

The P1E current-memory path uses:

`PicodMemoryStore` -> `WorldSignalResolver.resolveToday(...)`
-> `WorldStateProjector` -> `WorldProjectionMapAdapter` -> `MapView`

`MapView` receives runtime props and animals only. It does not resolve memory.

Expected smoke result:

- App launches with `PICOD_USE_WORLD_PROJECTION_MAP=1`: passed.
- DEBUG status badge appears: passed.
- Current memory projection rendered: elements 1 / warnings 21 / errors 0.
- If projection validates with errors, existing map behavior is used instead.
- If projection validates with warnings only, projected elements render and the
  badge reports warning count.

## Normal Mode

Expected smoke result:

- App launches with no projection badge: passed.
- Existing empty-world placeholder remains when the app state is empty: passed.
- Existing `MapView` runtime props and animals remain the only production path.
- No synthetic preview or audit UI appears: passed.

## Smoke Summary

- Normal gate-off launch: passed.
- P1D synthetic preview launch: passed; preview panel visible on fresh empty app state.
- P1E current-memory gated launch: passed.
- Combined preview + gated launch: passed.
- World audit after P1E: errors 0 / warnings 320 / actions 320 / high 55.
- P0 acceptance after P1E: passed 14 / failed 0.

Manual screenshots captured:

- `/tmp/p1e-normal-map.png`
- `/tmp/p1e-gated-projection.png`
- `/tmp/p1e-p1d-preview-fixed.png`
- `/tmp/p1e-normal-map-fixed.png`
- `/tmp/p1e-gated-projection-fixed.png`

The screenshots are local verification artifacts and are not committed.

Detailed per-scenario art-direction screenshots remain a P1E/P1F manual review
task before production rollout. This pass verifies that the preview route is
visible, all scenarios validate with errors 0, and current-memory gated rendering
works without changing normal mode.

## Deferred Visual Work

P1E does not solve the remaining warning backlog. Deferred categories:

- route readability polish
- visual occlusion risk
- density imbalance
- habitat mismatch
- decorative grounding
- validator threshold tuning
- projection placement refinement
