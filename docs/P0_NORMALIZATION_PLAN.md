# Picod P0 Normalization Plan

## Audit Summary

Picod already has useful P0 foundations:

- `PicodProgressStore` tracks a 49-day era, 7-day cycles, current generation IDs, daily participation, fired story beats, and day keys.
- `PhotoTraitSnapshotDatabase` stores per-day photo trait logs with Vision labels, color palette, selected form, and replaced Pico parts.
- `PicoFormRenderer` already supports 7-day inheritance by replaying previous snapshots and replacing only one part per day after Day 1.
- `WorldSeedEngine` maps daily photo snapshots and participation into persistent world/map seed properties.
- `StoryTriggerEngine` and `PicodStoryScheduler` evaluate story eligibility, but currently operate over all registered narrative profiles.
- The left/right swipe story panel exists in `PicodStagePreviewView.swift`; it should become the user-facing memory drawer rather than moving memory to Settings.

Important local state:

- The working tree has existing uncommitted UI/map/debug changes in `ContentView.swift`, `DashboardView.swift`, `MapView.swift`, `DevTestMode.swift`, `PicodStagePreviewView.swift`, and related icon/compatibility files.
- These local files are treated as source of truth.
- P0 work should avoid resetting or replacing that UI work.

## P0 Architecture Direction

The normalized product loop is:

`Daily Capture -> PhotoSeedMatch -> PicoEvolutionDecision -> WorldSeedDecision -> StoryBeat/MapTrace/DiaryInfluence -> DailyLifeRecord -> LifeAlbum -> CycleRecord -> EraMemory`

New domain layers:

- Time: `PicodTimeModel.swift`, `PicodCalendarResolver.swift`
- Photo seed matching: `PhotoSeedMatcher.swift`
- Evolution grammar: `PicoEvolutionEngine.swift`
- Memory: `PicodMemoryModels.swift`, `PicodMemoryStore.swift`, `LifeAlbumStore.swift`, `CycleRecordStore.swift`, `StoryCardStore.swift`, `EraMemoryStore.swift`, `PicodMemoryExporter.swift`
- Capture orchestration: `DailyCaptureOrchestrator.swift`
- Story event normalization: `PicodStoryEventModels.swift`
- Debug simulation: `PicodP0DebugScenarios.swift`

## Implementation Boundaries

- Keep existing lower-level JSON logs compatible: interactions, diary, story summaries, photo snapshots, world seeds.
- Add memory objects as aggregates above those logs.
- Do not expand the Pico form library or story library.
- P0 activates only `night_lamplighter`, `umbrella_woman`, and `mirror_miko`; the other storylines remain documented/spec-ready.
- Store writes are atomic and corrupt JSON falls back to empty state without crashing.
- Missing days become explicit placeholders in Life Albums, not punishment.

## UI Plan

Upgrade the side story panel into a Memory Drawer:

- Current Life: seven day slots, capture state, form thumbnail, diary/story trace hints.
- Life Albums: completed 7-day Pico-centric retrospectives.
- Cycle Records: world-level rhythm and marker summaries.
- Story Cards: locked/partial/unlocked story progression tied to evidence.
- Era Memory: hidden/quietly locked until a 49-day boundary.

Settings should stay for preferences and local reset controls only.
