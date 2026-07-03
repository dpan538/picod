# Picod P1 World Richness Plan

## Purpose

This document plans the next product layer after the P0 productized alpha.

P0 proves the daily loop:

`Daily Capture -> Pico evolution -> map trace -> diary -> StoryCard -> LifeAlbum -> CycleRecord -> EraMemory`

P1 should make the world feel richer, lived-in, and long-lived without turning Picod into a generic open-world game. The map remains a memory board for a quiet daily photo ritual.

## Read Pass

Files inspected before writing this plan:

- `docs/P0_NORMALIZATION_PLAN.md`
- `docs/P0_PRODUCTIZATION_REPORT.md`
- `docs/P0_ACCEPTANCE_REPORT.md`
- `docs/P0_REAL_DEVICE_QA_REPORT.md`
- `picod/full_test_map.swift`
- `picod/test_map.swift`
- `picod/prop.swift`
- `picod/animal.swift`
- `picod/MapView.swift`
- `picod/ObjectGalleryDebugView.swift`
- `picod/world_generation_context.swift`
- `picod/world_seed_engine.swift`
- `picod/world_seed_mapper.swift`
- `picod/world_participation_engine.swift`
- `picod/landform.swift`

## Existing Foundations

Picod already has more map/world structure than the current on-device surface communicates.

- `PropKind` already includes many natural props, structures, and civic objects: trees, bushes, flowers, lanterns, wells, bridges, gates, houses, shrines, kiosks, trucks, billboards, windmills.
- `AnimalKind` already includes everyday animals, quiet human visitors, and the P0 active story figures.
- `MapView.propSpec(for:)` already renders most existing props with pixel sprites.
- `ObjectGalleryDebugView` already exists as a simple readability gallery for selected object glyphs.
- `full_test_map.swift` already has a layered world generator:
  - landform skeleton
  - explicit zones
  - major structures
  - gates, walls, bridges
  - trees
  - props
  - animals
  - validation pass
- `full_test_map.swift` also has review variants:
  - forest shrine
  - wetland lantern
  - village market
  - night grove
  - dense April garden
- `WorldSeedEngine` already maps a 7-day Life into world dimensions:
  - Day 1: terrain warmth and brightness
  - Day 2: water expansion and clarity
  - Day 3: vegetation density and vines
  - Day 4: courtyard expansion and torii probability
  - Day 5: path extension and path condition
  - Day 6: prop weights
  - Day 7: visitor probability bonuses
- `WorldParticipationEngine` already distinguishes full, partial, minimal, and absent participation.

The right next move is not to rewrite the map. It is to productize the existing grammar and extend it carefully.

## Current Product Gaps

### Map Density

The current home map still reads too sparse at the outer edge. The perimeter should feel like the world continues past the visible board. Right now, too much edge space reads as empty test-map margin.

### Building Meaning

Buildings exist as sprites, but their product roles are not yet formal. They should become memory nodes, not random decoration.

### Object Governance

There is no explicit catalog saying which objects are structures, daily props, traces, anchors, memory markers, or ambience-only details.

### Placement Semantics

`full_test_map.swift` has local placement rules, but the rules are not yet reusable as a product system. Footprints, forbidden zones, clearance, passability, and story anchors should become inspectable.

### Pico Readability

Pico is the living subject of the board. World richness must never make Pico hard to find.

Current and future maps need explicit rules for:

- where Pico can walk;
- what can overlap Pico;
- how large sprites are sorted;
- when foreground objects should fade, trim, or avoid placement;
- which paths and spawn zones must stay readable on small iPhone screens.

### Grounding

The recent hardware QA found floating-object issues. P1 needs formal grounding rules:

- Pico may have a character shadow.
- Animals should usually read as flat sprites with contact pixels or tiny water/grass offsets, not heavy shadows.
- Buildings should sit through bases, thresholds, fences, steps, wall contact, or terrain color, not ellipse shadows.
- Trees should sit through trunks, roots, undergrowth, and occlusion, not generic shadows.
- Water objects should use wave contact or reflection, not land shadows.

### World Connection

Buildings and large props should not simply sit on top of terrain. They need a visible relationship to the map.

Each structure should have at least one of:

- an entrance tile connected to a path;
- a foundation or ground skirt;
- nearby support props such as stones, low wall, crate, lantern, mailbox, bench, or flower bed;
- matching terrain underlay, such as `stoneGround`, `dirt`, `wornPath`, `mossGround`, or `wetBank`;
- a story or memory anchor that explains why the object belongs there.

Disconnected buildings should be treated as placement failures unless intentionally rare and documented.

## Product Principle

World richness is memory density, not asset quantity.

Every added building, tree cluster, prop, and visitor anchor should answer at least one question:

- What daily photo trait can influence it?
- What Life, Cycle, or Era boundary can change it?
- What diary fragment or StoryCard evidence can point back to it?
- How does it preserve calm instead of becoming visual noise?

## Richness Pillars

### 1. Perimeter Forest

Goal: make the map feel held by a living edge.

P1 should first improve the outer world before adding many new buildings.

Rules:

- Use two to three perimeter density bands.
- Keep at least one readable entrance or opening.
- Vary tree sizes and silhouettes.
- Mix `forestEdge`, `groveFloor`, `mossGround`, and `clearing` so the border does not read as a hard wall.
- Use foreground edge trees sparingly where they do not block the main Pico/map read.
- High participation may open small clearings, flowers, and path-side details.
- Low participation may add moss, vines, stillness, and fewer visitors, but should remain beautiful.

Existing assets to reuse first:

- `roundTree`
- `tallTree`
- `bigTree`
- `sacredEvergreen`
- `gardenPine`
- `tallPine`
- `dwarfPine`
- `denseBush`
- `fallenLog`
- `mushroomPatch`

### 2. Pico Readability And Occlusion Budget

Goal: let the world get denser without losing Pico.

Pico should always remain the easiest living object to identify.

Rules:

- Keep Pico spawn and primary wandering routes away from heavy canopies and tall building fronts.
- Reserve a `picoSafetyRadius` around spawn, current rest points, and common path nodes.
- Large sprites may frame Pico but should not cover Pico's face/body for more than a tiny moment.
- Foreground trees can exist, but they should be outside the main Pico travel corridor or have a fade/clip rule.
- Story visitors should not spawn directly on top of Pico or behind a large building.
- Animal movement can cross near Pico, but should not visually merge with Pico.
- The main camera/map crop should keep Pico, the nearest path, and the main memory node visible together.

Suggested readability budgets:

- Pico body visible: target 100 percent in idle and normal walking states.
- Temporary partial overlap by small animals/props: acceptable only if brief and visually harmless.
- Overlap by large buildings, big trees, shrines, or bridges: should be prevented.
- Spawn zone: no blocking or tall foreground object within 2 tiles.
- Main corridor: no large occluder on both sides of a path at the same y-depth.

Implementation options:

- hard placement exclusion around `petSpawn`;
- precomputed `picoRouteCorridor` from spawn to major memory nodes;
- `occlusionClass` per object;
- `canOccludePico` flag defaulting to false;
- runtime fade for rare foreground overlaps;
- debug overlay for Pico visibility, spawn safety, and route safety.

### 3. Buildings As Memory Nodes

Buildings should not be filler. They should be places where the world stores repeated behavior.

Initial building roles should be defined before adding more art:

- `homeRestNode`: a quiet small house or hut near the Life rhythm.
- `rainShelterNode`: eaves, tea shelter, or small covered stop for rainy captures and `umbrella_woman`.
- `lampNode`: lamp hut, lantern row, or path light for night captures and `night_lamplighter`.
- `waterMirrorNode`: basin, bridge-side structure, well, or dock for reflection traces and `mirror_miko`.
- `cycleMarkerNode`: torii, shrine, gate, wall, or small marker added or modified at Cycle boundaries.
- `workStorageNode`: shed, crate cluster, tool corner, or garden storage for object/photo traces.

Existing building sprites to audit before new art:

- `japaneseHouse`
- `japaneseSmallHouse`
- `tinyShed`
- `kiosk`
- `shrineSmall`
- `pagoda`
- `gate`
- `torii`
- `stoneWell`
- `dock`
- `japaneseBridge`
- `lowWall`

New building candidates can be planned, but should not be implemented until existing sprites are audited in the gallery and on device:

- tea shelter
- lamp keeper hut
- rain eave
- mirror basin pavilion
- garden tool shed
- small covered bridge shelter
- cycle marker alcove

### 4. Building And Object Connection Grammar

Goal: make buildings and props look physically connected to terrain.

Every major structure should define:

- `footprint`: occupied map cells.
- `visualFootprint`: pixels that extend beyond occupied cells.
- `entranceCoord`: where Pico or a visitor would approach.
- `foundationTerrain`: preferred underlay.
- `connectionProps`: optional nearby props that make the structure feel used.
- `pathConnection`: required, optional, or forbidden.
- `waterConnection`: required, optional, or forbidden.
- `groundingStyle`: foundation, contact pixels, water contact, canopy occlusion, glow only, or Pico shadow.

Connection rules:

- Houses, kiosks, sheds, shrines, gates, and lantern rows should connect to a path or courtyard.
- Bridges must cross water and connect to land/path on both sides.
- Docks must touch water and land.
- Wells/basins should sit on stone, dirt, or moss and leave one approach tile.
- Torii should mark a route or threshold, not sit as random decoration.
- Low walls should imply enclosure but not trap Pico.
- Forest objects can be unconnected, but should strengthen the edge silhouette or habitat.
- Daily traces can be small and unconnected, but should sit on compatible terrain.

Grounding examples:

- `japaneseHouse`: foundation terrain plus entrance tile, mailbox/crate/flower nearby.
- `tinyShed`: dirt or moss underlay plus crate/tool cluster.
- `kiosk`: worn path front plus bench/lantern nearby.
- `shrineSmall`: stone or moss base plus torii/lantern context.
- `stoneWell`: stone/moss base plus one clear approach tile.
- `japaneseBridge`: water under center, land/path endpoints.
- `reedCluster`: water edge only.
- `bigTree`: trunk contact plus grove/forest terrain, no ellipse shadow.

### 5. Everyday Props And Photo Traces

Props should make the world react to daily photos without needing new storylines.

Suggested prop groups:

- Weather traces: wet stones, puddle edge, umbrella stand, reed bend, lamp glow.
- Color traces: flower bed tint, cloth strip, small painted tile, fruit crate.
- Object traces: cup, book, sign mark, tool basket, folded cloth.
- Path traces: worn path tile, leaf trail, small footprint, mossy edge.
- Cycle traces: extra stone lantern, torii ribbon, repaired bridge board, new low wall segment.

P1 should prefer symbolic traces over literal object duplication from the photo.

### 6. Visitors And Animals

Visitors and animals should make the board feel alive, but they should not overtake the ritual.

Rules:

- P0 active story visitors remain limited to:
  - `night_lamplighter`
  - `umbrella_woman`
  - `mirror_miko`
- Other visitors can stay present as ambient/spec-ready only if already safely wired.
- Animals can move subtly inside habitat rules.
- Animal bubbles should stay sparse.
- Human visitor bubbles should remain more ambiguous than animal bubbles.
- Interaction logs should remain Pico-level observations, not lore explanations.

### 7. Atmosphere

Atmosphere should carry meaning when real weather is unavailable.

Use:

- time of day
- local device time
- photo brightness and palette
- humidity/weather if real provider is available
- map mood
- participation rhythm

Do not present fallback climate as real measured weather.

### 8. Memory Drawer Linkage

World richness must be inspectable through memory.

Each persistent world change should eventually be able to link to:

- a DailyLifeRecord
- a Life Album
- a Cycle Record
- a StoryCard evidence item
- an Era Memory echo

If an object cannot be explained through the memory system, it should probably stay ambient and non-persistent.

## Proposed Technical Shape

Do not rewrite the architecture. Introduce small, inspectable layers around the existing map generator.

### World Element Catalog

Future file:

- `picod/WorldElementCatalog.swift`

Purpose:

- classify existing `PropKind` values by role;
- define footprints, grounding style, occlusion style, connection requirements, persistence behavior, and allowed zones;
- distinguish structures, flora, props, traces, anchors, and memory markers.

Suggested model:

```swift
enum WorldElementRole {
    case structure
    case flora
    case dailyProp
    case photoTrace
    case visitorAnchor
    case cycleMarker
    case eraEcho
}

enum GroundingStyle {
    case picoShadow
    case contactPixels
    case foundation
    case waterContact
    case canopyOcclusion
    case glowOnly
}

enum OcclusionClass {
    case none
    case low
    case canopy
    case tallStructure
    case foregroundOnly
}

enum ConnectionRequirement {
    case none
    case path
    case courtyard
    case water
    case threshold
}
```

Catalog entries should also capture:

- visual footprint versus blocking footprint;
- whether the object can ever occlude Pico;
- required clear approach tiles;
- compatible terrain underlay;
- preferred companion props;
- story or memory anchor compatibility.

Default policy: `canOccludePico` should be false unless an object is intentionally foreground-only and has a fade/clip rule.

### Map Richness Profile

Future file:

- `picod/MapRichnessProfile.swift`

Purpose:

- convert `WorldSeed`, participation, story flags, and time/weather context into density targets;
- keep richness deterministic and explainable.

Suggested dimensions:

- perimeterForestDensity
- courtyardObjectDensity
- waterEdgeDensity
- buildingClusterLevel
- picoCorridorOpenness
- occlusionRisk
- traceDensity
- visitorAnchorLevel
- stillnessLevel
- pathWearLevel

### Placement Grammar

Future file:

- `picod/WorldPlacementGrammar.swift`

Purpose:

- lift the local placement ideas from `full_test_map.swift` into reusable validation;
- avoid collisions, blocked paths, and floating objects.

Rules to preserve:

- structures cannot overlap;
- bridges must cross water;
- gates must align with paths;
- torii must remain contextual;
- buildings need clearance;
- forest trees wrap the board but leave readable access;
- props should not block important path routes;
- story anchors should not sit inside visually noisy clusters.
- Pico spawn and common route corridors must stay readable.
- Large sprites cannot cover Pico's body or face.
- Each major structure must connect to terrain through foundation, entrance, path, water, or threshold rules.
- Any object with `OcclusionClass.canopy`, `tallStructure`, or `foregroundOnly` needs an explicit Pico avoidance or fade rule.

Suggested validation outputs:

- blocked route count;
- unsafe Pico spawn cells;
- tall occluders near Pico path;
- disconnected structures;
- water objects away from water;
- buildings without approach tile;
- excessive perimeter density in the main camera crop.

### Memory Map Patch

Future file:

- `picod/MapMemoryPatch.swift`

Purpose:

- represent persistent world changes caused by Daily Capture, Life closure, Cycle closure, or Era boundary;
- keep map changes small and idempotent.

Examples:

- Day trace: temporary wet path mark.
- Life closure: one small Pico memory object.
- Cycle closure: one world marker or modification.
- Era closure: quiet echo or rearranged absence.

## Content Roadmap

### Phase P1A: Audit And Rules

No new visible content required.

Deliverables:

- Document all existing `PropKind` values by role.
- Expand `ObjectGalleryDebugView` to include every currently rendered prop and animal.
- Add grounding rules for each sprite family.
- Record target object counts for 28x28 maps.
- Add validation for:
  - passable main route
  - structure overlap
  - perimeter density
  - no excessive shadows
  - no object covering Pico spawn
  - no tall object covering Pico's common route
  - no disconnected major structure
  - no building without approach tile
  - no water prop away from water
  - no story anchor hidden behind large trees

### Phase P1B: Perimeter Forest Richness

Primary visual improvement.

Deliverables:

- Increase outer tree density with multiple bands.
- Add more varied forest-edge terrain.
- Keep central ritual area readable.
- Preserve at least one entrance/exit read.
- Preserve Pico spawn and primary route readability.
- Keep tall canopy away from Pico's idle/rest corridor unless there is an explicit fade/clip rule.
- Add wind sway and leaf/grass movement that respects Reduce Motion as a comfort setting without freezing the whole world.

Acceptance:

- The edge should no longer read sparse on iPhone 14.
- Pico and the main map action remain legible.
- Pico is not covered by edge trees, foreground canopies, or large structures during normal wandering.
- No new storylines or Pico forms.

### Phase P1C: Existing Building Productization

Use existing sprites first.

Deliverables:

- Assign roles to current structures.
- Place structures through catalog/grammar instead of ad hoc lists.
- Add detail clusters around each building:
  - base/foundation
  - entrance tile
  - nearby prop
  - optional visitor anchor
  - optional memory trace slot
- Require path/water/threshold connection for every major structure.
- Add debug overlay or validation output for disconnected buildings and Pico occlusion risks.

Acceptance:

- Buildings feel grounded.
- Buildings differ by purpose, not just sprite.
- Buildings frame Pico's world without hiding Pico.
- Structures visibly connect to terrain through foundations, paths, thresholds, or water edges.
- Memory Drawer/Cycle Record can name world-level changes without exposing debug jargon.

### Phase P1D: Daily And Cycle Memory Traces

Connect richer map state to the P0 memory system.

Deliverables:

- Daily photo creates at most one visible trace.
- Life closure creates or updates one Pico-centric memory marker.
- Cycle closure creates or updates one world marker.
- StoryCards can point to map evidence.

Acceptance:

- Missed days remain quiet placeholders, not punishment.
- High participation creates more lived-in rhythm.
- Low participation creates beautiful stillness.

### Phase P2: New Building And Object Art

Only after P1A-P1D are stable.

Candidate first batch:

- tea shelter
- lamp keeper hut
- rain eave
- mirror basin pavilion
- garden tool shed
- small covered bridge shelter
- cycle marker alcove

For each new object, require:

- product role
- memory linkage
- footprint
- blocking behavior
- grounding style
- gallery preview
- iPhone screenshot check
- no P0 acceptance regression

### Phase P3: Long-Term Era World Memory

Make the world feel like it remembers more than it explains.

Deliverables:

- Era boundary can quietly alter the map arrangement.
- Some markers vanish, persist, or return changed.
- Era Memory can reference echoes without explaining the reset.
- World changes remain idempotent and local.

## Map Density Targets

Initial targets for the 28x28 board:

- Major structures: 3-6
- Secondary structures: 2-5
- Perimeter trees: 35-55, depending on view density
- Interior trees: 6-14
- Bushes/flora: 12-24
- Water-edge props: 4-12
- Daily trace slots: 0-7 active per Life, but only 1-3 visually prominent at once
- Cycle markers: 0-7 visible or implied per Era
- Ambient animals: 4-10
- Human/story visitor anchors: 0-3 visible at once

These are not hard requirements. They are readability targets for review.

## Building And Object Planning Table

| Candidate | Existing asset? | Role | Memory link | First phase |
| --- | --- | --- | --- | --- |
| Main quiet house | `japaneseHouse`, `mansion` | Life rest node | Life Album cover/detail | P1C |
| Small side house | `japaneseSmallHouse` | Pico daily routine | DailyLifeRecord diary fallback | P1C |
| Garden shed | `tinyShed` | object/photo trace storage | Daily trace / prop evidence | P1C |
| Kiosk / tea stop | `kiosk` | shelter/social trace | participation rhythm | P1C |
| Shrine | `shrineSmall`, `pagoda`, `torii` | Cycle/Era marker area | Cycle Record / Era Memory | P1C |
| Bridge | `japaneseBridge`, `bridgeShort` | water/reflection crossing | mirror_miko evidence | P1C |
| Well / basin | `stoneWell` | water memory node | mirror_miko evidence | P1C |
| Lantern row | `lantern`, `stoneLanternJp` | night path | night_lamplighter evidence | P1C |
| Tea shelter | new | rain waiting node | umbrella_woman / rainy diary | P2 |
| Lamp keeper hut | new | night visitor node | night_lamplighter recurrence | P2 |
| Rain eave | new | weather trace | rainy capture | P2 |
| Mirror basin pavilion | new | reflection anomaly node | mirror_miko / Era echo | P2 |
| Covered bridge shelter | new | water/transition node | Cycle/Era threshold | P2 |

## Validation Requirements

Every implementation phase should run:

- `git status --short --branch`
- `git diff --stat`
- `git diff --check`
- `xcodebuild -list -project picod.xcodeproj`
- simulator Debug build
- P0 acceptance harness

Visual validation should include:

- fresh Day 1
- after one capture
- Memory Drawer open
- dense forest variant
- wetland/rain variant
- night/lamp variant
- Pico walking through normal route corridors
- Pico near buildings, trees, bridges, and water nodes
- disconnected-building debug state
- completed Life Album state
- locked Era Memory state

Device validation should include at least:

- iPhone 14 size
- Reduce Motion on/off
- noon local time
- night local time
- weather unavailable fallback
- Pico visible during normal wandering
- no large prop/building hiding Pico
- every major building visibly connected to path, foundation, threshold, or water edge

## Non-Goals

Do not use P1 richness work to add:

- new Pico forms
- new storylines
- cloud sync
- accounts
- social sharing
- AR
- network AI
- explicit horror
- punitive missed-day mechanics

Do not move Memory Drawer content into Settings.

## Recommended Next Step

Suggested first implementation slice:

1. Add `WorldElementCatalog` for existing props only.
2. Expand `ObjectGalleryDebugView` to cover all existing props/animals.
3. Formalize grounding, occlusion, and connection style per object family.
4. Add Pico safety corridor and spawn readability validation.
5. Increase perimeter forest density using existing tree sprites.
6. Add validation/debug scenarios for forest density, passability, Pico visibility, and disconnected structures.
7. Run simulator build, P0 acceptance, and iPhone visual check.

This gives the world immediate visible richness while keeping the product loop intact.

## Implemented P1A Loop

The first P1A implementation now creates a closed internal production loop:

`WorldElementCatalog -> WorldMapValidator -> WorldMapRichnessAuditor -> DEBUG gallery -> console audit`

This loop is intentionally development-facing. It does not add user-visible content, new forms, or new stories.

### WorldElementCatalog

`WorldElementCatalog` assigns every existing `PropKind` and `AnimalKind` a product role:

- structure
- flora
- daily prop
- visitor anchor
- cycle marker
- era echo

It also records footprint, visual footprint, grounding style, occlusion class, connection requirements, terrain compatibility, Pico blocking behavior, and approach-tile requirements.

### WorldMapValidator

`WorldMapValidator` now checks the map for:

- Pico spawn safety
- Pico route occlusion risk
- deterministic primary Pico route length
- perimeter forest density
- structure/path/courtyard/water/threshold connection
- approach tile availability
- terrain mismatch
- animal habitat mismatch
- reachable walking area

Validation issues are categorized so map work can be sorted into Pico safety, forest edge, connection, terrain, habitat, and reachability.

The primary route is not an arbitrary reachable-tile sample. It is a deterministic path from Pico's spawn toward a central reachable path target. This keeps route-occlusion warnings focused on the places Pico is most likely to travel.

### WorldMapRichnessAuditor

`WorldMapRichnessAuditor` runs all current review maps:

- forest shrine
- wetland lantern
- village market
- night grove
- April dense garden

It turns validation issues into prioritized actions:

- blocker
- high
- medium
- low

This is the key step that turns map richness from visual tweaking into a repeatable production workflow.

### DEBUG Review Surface

`ObjectGalleryDebugView` now shows:

- all-map audit summary
- per-variant error/warning/action counts
- next prioritized richness actions
- current-map validation detail
- prop/animal previews using real `MapView`
- per-object footprint, visual footprint, connection, Pico-blocking, and approach-tile specs

### CLI-Friendly Audit

Set this environment variable when launching the app to print the audit:

`PICOD_RUN_WORLD_RICHNESS_AUDIT=1`

Console output is prefixed with:

`[WorldRichnessAudit]`

This allows future build or device passes to check map richness without manually opening the DEBUG gallery.

### Current Audit Baseline

After the first P1A rule pass:

- P0 acceptance remains `passed=14 failed=0`.
- all-map audit: `maps 5 / errors 13 / warnings 116 / actions 129 / high 34`.
- forest shrine review: `errors 0 / warnings 25`.

The remaining errors are not content blockers for P0, but they are now sorted into an explicit P1 map-normalization backlog.

## Next Closure Step

The next long-running slice should use the audit output to normalize each map variant in order:

1. Fix blocker/high Pico safety issues first.
2. Repair disconnected structures and water-contact mismatches.
3. Fill sparse perimeter belts with existing tree/flora props.
4. Re-run the all-map audit.
5. Open the DEBUG gallery to verify visual readability.
6. Run simulator build and P0 acceptance.
7. Run a real-device visual pass for Pico readability.

Only after this loop is stable should Picod add new buildings or objects.

## Implemented P1B World State Projection Loop

P1B adds a derived world state layer between canonical P0 Memory and the map.
The new architecture is:

`Canonical Memory -> WorldSignalResolver -> WorldStateProjection -> WorldElementPlacementPlan -> WorldMapValidator / WorldMapRichnessAuditor -> MapView / DEBUG UI`

Added files:

- `picod/WorldSignalModels.swift`
- `picod/WorldSignalResolver.swift`
- `picod/WorldStateProjection.swift`
- `picod/WorldStateProjector.swift`
- `docs/P1_WORLD_STATE_PROJECTION_PLAN.md`
- `docs/P1_WORLD_AUDIT_BASELINE.md`

Updated systems:

- `WorldMapValidator` can validate `WorldStateProjection` against a base map.
- `WorldMapRichnessAuditor` now runs static map audit plus memory-driven projection scenarios.
- `ObjectGalleryDebugView` now shows projection scenario audit rows and projected element cards.

Projection scenarios now cover:

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

Current P1B audit result:

- static maps: 5
- projection scenarios: 10
- total errors: 26
- total warnings: 366
- total actions: 392
- high actions: 113
- static map errors/warnings: 13 / 116
- projection scenario errors/warnings: 13 / 250

Projection-specific evidence checks are green:

- unknown catalog IDs: 0
- missing story evidence/source: 0
- ungrounded projected elements: 0
- locked EraMemory echoes: 0

The remaining errors are inherited from static base maps, especially
`wetlandLantern` and `nightGrove` Pico spawn/path blockers. MapView is not yet
fed by production projection output because those base-map blockers should be
fixed before projected elements become normal runtime content.
