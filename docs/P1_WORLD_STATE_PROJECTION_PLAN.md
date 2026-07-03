# Picod P1 World State Projection Plan

## Purpose

P1B closes the data path between P0 Memory and the visible world without making
the map renderer depend on every persistence store.

Target architecture:

`Canonical Memory -> WorldSignalResolver -> WorldStateProjection -> WorldElementPlacementPlan -> WorldMapValidator / WorldMapRichnessAuditor -> MapView / DEBUG UI`

This is not a map rewrite. It is a projection boundary.

## Files Added

- `picod/WorldSignalModels.swift`
- `picod/WorldSignalResolver.swift`
- `picod/WorldStateProjection.swift`
- `picod/WorldStateProjector.swift`

## Files Inspected

- `picod/ContentView.swift`
- `picod/PicodStagePreviewView.swift`
- `picod/DailyCaptureOrchestrator.swift`
- `picod/PicodMemoryStore.swift`
- `picod/LifeAlbumStore.swift`
- `picod/CycleRecordStore.swift`
- `picod/StoryCardStore.swift`
- `picod/EraMemoryStore.swift`
- `picod/PicodMemoryModels.swift`
- `picod/PicodStoryEventModels.swift`
- `picod/PhotoSeedMatcher.swift`
- `picod/PicoEvolutionEngine.swift`
- `picod/StoryTriggerEngine.swift`
- `picod/PicodStoryScheduler.swift`
- `picod/PhotoTraitSnapshotDatabase.swift`
- `picod/MapView.swift`
- `picod/full_test_map.swift`
- `picod/movement_system.swift`
- `picod/world_seed_engine.swift`
- `picod/world_seed_mapper.swift`
- `picod/world_generation_context.swift`
- `picod/WorldElementCatalog.swift`
- `picod/WorldMapValidation.swift`
- `picod/WorldMapRichnessAudit.swift`
- `picod/ObjectGalleryDebugView.swift`
- `picod/DevTestMode.swift`

## Architecture Answers

### 1. What Is Canonical Memory Truth?

Canonical memory truth is the aggregate P0 memory model exposed through
`PicodMemoryStore` and its sub-stores:

- `DailyLifeRecord`
- `LifeAlbum`
- `CycleRecord`
- `StoryCard`
- `EraMemory`
- `PicodMemoryIndex`

These objects own user-facing memory continuity. A world projection must derive
from them and keep evidence IDs that point back to them.

### 2. What Is Raw Lower-Level Log Data?

Lower-level logs remain implementation evidence, not the direct map contract:

- photo trait snapshots;
- diary database records;
- story summaries;
- interaction logs;
- raw story events;
- world seed/debug records.

These can enrich future signal resolution, but MapView should not query them
directly.

### 3. What Is Derived World State?

Derived world state is:

- `WorldSignalBundle`
- `WorldStateProjection`
- `WorldProjectedElement`
- `WorldElementPlacementPlan`

These objects are deterministic summaries of memory, photo mood, Pico evolution,
story evidence, cycle markers, and era unlock state. They can be generated at
runtime and optionally snapshotted later for album/cycle/era retrospectives.

### 4. What Is Temporary Debug State?

Temporary debug state includes:

- representative projection scenarios in `WorldMapRichnessAuditor`;
- `ObjectGalleryDebugView` audit panels;
- console hooks such as `PICOD_RUN_WORLD_RICHNESS_AUDIT=1`;
- review map variants from `DevTestMode.MapReviewVariant`.

Debug state may generate synthetic signals, but it must not become product
memory truth.

### 5. What Should MapView Read?

For P1 world richness, MapView should read a compact projection or placement
plan:

- `WorldStateProjection`
- or `WorldElementPlacementPlan`
- or adapted `runtimeProps` / `runtimeAnimals` from
  `WorldProjectionMapAdapter`

MapView should continue to accept static/default map inputs as fallback. It
should not open memory stores, photo DBs, story stores, diary DBs, or cycle/era
stores directly.

### 6. What Should Validators Read?

Validators should read:

- a static `TestMap`;
- or a `WorldStateProjection` plus a base `TestMap`.

`WorldMapValidator.validate(_ projection:baseMap:)` adapts projected elements
into existing prop/animal placement so existing safety, route, habitat, water
edge, connection, and occlusion checks still apply.

### 7. What Should Never Be Directly Coupled?

These direct couplings should remain forbidden:

- `MapView -> PicodMemoryStore`
- `MapView -> StoryCardStore`
- `MapView -> LifeAlbumStore`
- `MapView -> CycleRecordStore`
- `MapView -> EraMemoryStore`
- `MapView -> PhotoTraitSnapshotDatabase`
- `MapView -> diary/story summary databases`
- `WorldProjectedElement -> SwiftUI view state`
- validators hiding or ignoring audit failures

The world renderer consumes projection data. Stores remain behind the resolver.

## Signal Resolution

`WorldSignalResolver` converts canonical memory into `WorldSignalBundle`.

Signals include:

- local day, Life, Cycle, Era identifiers;
- capture and participation state;
- photo mood bands;
- color, weather, and time-of-day signals;
- Pico genome/form/change signals;
- P0 active story signals;
- diary and map trace references;
- Life Album, Cycle Record, and Era Memory signals;
- missing-day placeholders;
- evidence IDs.

Empty, partial, missing, or corrupt-store fallback states produce quiet signals
instead of crashes.

## Projection Rules

`WorldStateProjector` maps signals into projected elements:

- daily photo mood -> small photo trace;
- rainy weather -> wet/water-edge trace eligibility;
- night story evidence -> lamp/path echo;
- Pico evolution -> small personal trace near but outside Pico safety radius;
- StoryCard evidence -> subtle story trace;
- CycleRecord -> torii/cycle marker;
- EraMemory -> rare echo only when unlocked;
- missing day -> quiet stillness, not punishment.

All projected elements include:

- catalog element ID;
- role;
- placement intent;
- tile/anchor;
- visual priority;
- collision policy;
- occlusion policy;
- persistence scope;
- evidence IDs;
- source;
- debug reason.

## Active P0 Story Echoes

Only P0 active stories are mapped:

- `night_lamplighter`: lit path marker / warm lamp edge.
- `umbrella_woman`: wet path or water-edge trace.
- `mirror_miko`: shrine reflection / mirror trace / Day 7 closure echo.

No new storylines or lore dumps are introduced.

## MapView Boundary

P1B keeps MapView's normal rendering path stable. The new projection adapter can
produce `runtimeProps` and `runtimeAnimals`, but normal MapView consumption is
left as a controlled next step. This avoids destabilizing the P0 memory loop
while the static maps still have known path/spawn issues.

Next integration step:

1. Generate today's `WorldSignalBundle` from `PicodMemoryStore`.
2. Build a `WorldStateProjection` for the current base map.
3. Validate it.
4. If validation has no blocking Pico safety errors, feed adapter output into
   MapView runtime props/animals.
5. Fall back to the existing static/default map if validation fails.

## Current Validation Status

Latest P1B console world audit:

- static maps audited: 5
- projection scenarios audited: 10
- total errors: 26
- total warnings: 366
- total actions: 392
- high actions: 113
- static map errors/warnings: 13 / 116
- projection scenario errors/warnings: 13 / 250

Projection-specific invariants are working:

- projected elements have catalog IDs;
- story traces carry evidence IDs;
- cycle markers carry cycle source IDs;
- era echoes appear only for unlocked EraMemory scenarios;
- no missing evidence was reported;
- no unknown catalog IDs were reported.

Remaining errors are inherited primarily from static review map issues:

- `wetlandLantern` has blocked Pico spawn / no reachable tiles;
- `nightGrove` has blocked Pico spawn / no reachable tiles;
- repeated spawn and route occlusion warnings remain across dense maps.
