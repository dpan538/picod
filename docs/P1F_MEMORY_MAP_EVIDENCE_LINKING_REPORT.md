# P1F Memory Map Evidence Linking Report

Date: 2026-07-03

## Baseline

- Branch: `p1-world-richness-integration`
- Starting commit: `1998680 P1 world projection pipeline through gated MapView rehearsal`
- Starting working tree: clean before P1F edits.
- Deleted files before edits: none.
- Debug simulator build before edits: passed.
- P0 acceptance before edits: passed 14 / failed 0.
- World audit before edits: static maps 5 / projection scenarios 10 / errors 0 / warnings 320 / actions 320 / high 55.

Known warning backlog remains intentionally visible:

- static map warnings: 109
- projection scenario warnings: 211
- high actions: 55

## Goal

P1F adds a deterministic evidence-linking layer between canonical memory records
and memory-derived world projection anchors. This is not a production map rollout
and does not make projection rendering the default path.

The user-facing goal is simple: a Memory Drawer detail can say that a day,
album, cycle, card, or rare era memory left a quiet world trace without exposing
technical projection or audit language.

## Files Changed

- `picod/WorldEvidenceAnchorModels.swift`
- `picod/WorldEvidenceAnchorResolver.swift`
- `picod/WorldMapRichnessAudit.swift`
- `picod/ObjectGalleryDebugView.swift`
- `picod/PicodStagePreviewView.swift`
- `docs/P1F_MEMORY_MAP_EVIDENCE_LINKING_REPORT.md`
- `docs/P1F_MEMORY_MAP_EVIDENCE_VISUAL_QA.md`
- `docs/P1_WORLD_AUDIT_BASELINE.md`

## Evidence Model

`WorldEvidenceAnchor` is a Codable/loggable bridge object derived from
`WorldStateProjection` element evidence. It includes:

- evidence source type: daily record, diary entry, story card, map trace, life
  album, cycle record, era memory, photo mood, Pico evolution, or unknown
- source memory identifiers and local time identifiers where known
- projected element and catalog identifiers where available
- anchor kind: object, path, water edge, shrine, light, animal, atmosphere,
  cycle marker, era echo, or unknown
- display state: hidden, hinted, visible, remembered
- persistence scope from the projected element
- a soft user-facing label
- a DEBUG-only debug reason and validation state

`WorldEvidenceLink` summarizes which anchors belong to a Memory Drawer object
and supplies a graceful fallback label when no projected anchor is available.

## Resolver Behavior

`WorldEvidenceAnchorResolver` reads projection evidence IDs and an explicit
`PicodMemoryStore` index when available. It does not read files directly.

Rules implemented:

- Daily records link to their record ID, photo snapshot ID, diary ID, story beat
  IDs, and story trace IDs.
- Story cards link to their card ID, daily evidence IDs, diary IDs, and map
  trace IDs.
- Life albums link to their album ID, day records, story traces, and unlocked
  story cards.
- Cycle records link to their cycle record ID, cycle ID, life albums, and story
  cards.
- Era memories link only to valid remembered or unlocked traces.
- Duplicate anchor IDs are removed deterministically.
- Story anchors are derived only from projected elements with evidence.
- Locked era memory anchors remain hidden and do not leak visible map traces.
- Empty or missing memory produces empty anchors and fallback labels instead of
  crashing.

## Memory Drawer Integration

The Memory Drawer remains the primary user-facing memory surface. P1F adds a
single "World trace" fragment inside details for:

- DailyLifeRecord
- LifeAlbum
- CycleRecord
- StoryCard
- EraMemory

Normal UI rules:

- no raw IDs
- no words such as projection, anchor, validator, or evidence ID
- no debug/audit counts
- graceful poetic fallback when no anchor exists
- no main screen clutter

The Drawer derives a compact anchor set from current memory through
`WorldSignalResolver -> WorldStateProjector -> WorldEvidenceAnchorResolver`.
`MapView` is not involved and still does not read memory stores.

## DEBUG Highlight Behavior

`ObjectGalleryDebugView` now lets a DEBUG preview scenario inspect evidence
anchors. Selecting an anchor:

- highlights the corresponding projected element in the simplified projection
  preview
- shows an anchor debug card with source type, display state, persistence,
  projected element ID, catalog ID, evidence ID, and debug reason

This remains inside DEBUG audit/preview UI. Normal app UI does not expose the
debug card or audit terminology.

## Evidence Link Scenarios

The evidence-link audit runs over the deterministic P1D scenario set:

1. fresh Day 1 empty
2. Day 1 warm indoor capture
3. Day 4 rainy umbrella trace
4. Day 5 night lamplighter trace
5. Day 7 mirror closure
6. completed Life Album
7. completed Cycle Record
8. low participation Life
9. locked Era Memory
10. unlocked Era Memory

Checked expectations:

- story cards create story/map trace anchors when projected evidence exists
- completed cycle creates a cycle marker anchor
- locked era memory creates no visible era anchor
- unlocked era memory creates a remembered rare echo anchor
- low participation produces quiet evidence without punitive wording
- missing or empty anchor sets fall back without crash

## Audit Integration

`WorldMapRichnessAudit` now includes a small evidence-link report alongside the
existing static map and projection scenario audit.

The evidence-link report is intentionally additive. It does not change static
map error counts, projection error counts, warning counts, action counts, or
priority ranking.

Console output includes:

- evidence scenarios audited
- anchors generated
- unresolved memory links
- duplicate anchors
- locked leaks
- missing evidence count

## Validation

Commands used:

```sh
git diff --check
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
env SIMCTL_CHILD_PICOD_RUN_WORLD_RICHNESS_AUDIT=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
env SIMCTL_CHILD_PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
env SIMCTL_CHILD_PICOD_USE_WORLD_PROJECTION_MAP=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
env SIMCTL_CHILD_PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1 SIMCTL_CHILD_PICOD_USE_WORLD_PROJECTION_MAP=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Observed final result:

- `git diff --check`: passed.
- Debug simulator build: passed.
- P0 acceptance: passed 14 / failed 0.
- World audit: errors 0 / warnings 320 / actions 320 / high 55.
- Evidence-link audit: scenarios 10 / anchors 35 / unresolved 0 /
  duplicate anchors 0 / locked leaks 0 / missing evidence 0.
- Normal smoke launch: passed.
- P1D projection preview smoke launch: passed.
- P1E gated projection map smoke launch: passed.
- Combined preview + gated projection smoke launch: passed.

## Remaining Work

- The 320 world audit warnings / 55 high actions remain visible backlog.
- Memory Drawer evidence is currently textual. A production map highlight entry
  point is deferred until projection rendering is ready for normal users.
- DEBUG anchor inspection is available, but normal users do not yet tap a
  drawer record to jump into a production map highlight.

## P1G Readiness

P1G limited production evidence UX is safe to consider if it remains textual by
default, keeps projection rendering gated, and uses the new evidence links as
the boundary rather than making `MapView` read memory stores.

## Guardrails Confirmed

- No Pico forms were added.
- No storylines were added.
- No map variants were added.
- No folklore content was expanded.
- Production MapView default remains unchanged.
- `MapView` still does not read memory stores directly.
- No audit warnings were silenced or downgraded.
- No reset, rebase, or discard was performed.
