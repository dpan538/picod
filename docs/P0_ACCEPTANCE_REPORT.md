# Picod P0 Acceptance & Hardening Report

## Scope

This pass verifies and hardens the normalized P0 loop:

`Daily Capture -> PhotoTraitSnapshot -> PhotoSeedMatch -> PicoEvolutionDecision -> DailyLifeRecord -> StoryCard progression -> LifeAlbum -> CycleRecord -> EraMemory`

The pass intentionally does not add Pico forms, storylines, map complexity, cloud services, accounts, social features, AR, or network AI.

## Files Inspected

- `picod/ContentView.swift`
- `picod/PicodStagePreviewView.swift`
- `picod/DailyCaptureOrchestrator.swift`
- `picod/PicodMemoryStore.swift`
- `picod/LifeAlbumStore.swift`
- `picod/CycleRecordStore.swift`
- `picod/StoryCardStore.swift`
- `picod/EraMemoryStore.swift`
- `picod/PhotoSeedMatcher.swift`
- `picod/PicoEvolutionEngine.swift`
- `picod/StoryTriggerEngine.swift`
- `picod/PicodStoryScheduler.swift`
- `picod/PicodP0DebugScenarios.swift`
- `picod/PicodProgressStore.swift`
- `picod/photo_trait_snapshot_database.swift`
- `picod/pico_diary_database.swift`
- `picod/pico_interaction_database.swift`
- `picod/pico_story_summary_database.swift`

## Verified Working Paths

- Real capture flow calls `DailyCaptureOrchestrator` from `ContentView.processCapturedPhoto`.
- The orchestrator builds a `PhotoTraitSnapshot`, deterministic `PhotoSeedMatch`, `PicoEvolutionDecision`, map mood, and structured story event bundle.
- `ContentView` writes successful captures into `PicodMemoryStore.recordDailyCapture`.
- The Memory Drawer reads the same canonical `PicodMemoryStore` instance that capture writes to.
- Memory stores use atomic JSON writes through `PicodAtomicJSON`.
- Missing/corrupt JSON loads fall back to empty state instead of crashing.
- Store arrays are bounded: daily records 420, Life Albums 60, Cycle Records 60, Story Cards 80, Era Memories 12.
- P0 story activation is narrowed to `nightLamplighter`, `umbrellaWoman`, and `mirrorMiko`.
- Story card evidence, diary IDs, and map trace IDs are deduplicated.
- Life Album closure materializes seven canonical daily slots, including explicit missed-day placeholders.
- Day 7 capture no longer stores the egg as the Day 7 final genome; closure is separate from final capture evolution.
- Passive lifecycle reconciliation can close finalized Day 7 Life/Cycle/Era boundaries on launch or foreground without requiring a new photo.
- Existing closure calls are idempotent: already-exported Life Albums, Cycle Records, and Era Memories are returned instead of rewritten.
- DEBUG Settings includes a dev-safe P0 acceptance route that runs deterministic local scenarios and prints detailed logs.
- A DEBUG-only launch environment hook, `PICOD_RUN_P0_ACCEPTANCE=1`, can run the same acceptance harness in the simulator without Xcode tapping.
- Generated Info.plist settings now include `NSLocationWhenInUseUsageDescription`, matching the local-world-context behavior already present in the app.

## Debug Acceptance Scenarios

`PicodP0DebugScenarios.runSummary()` covers:

- Day 1 hatch from warm indoor photo traits.
- Day 2 inheritance with minor texture/accent mutation.
- Day 3 appendage/environmental habit mutation.
- Day 4 rainy capture with `umbrellaWoman` evidence.
- Day 5 night capture with `nightLamplighter` evidence.
- Day 6 mature form with story recurrence.
- Day 7 final form, LifeAlbum export, CycleRecord export, and mirror/egg closure check.
- Low participation Life with five missed-day placeholders.
- Corrupt JSON fallback.
- Passive lifecycle reconciliation after a finalized Day 7.
- App relaunch-style reload from the same memory store files.
- Era Memory locked before seven cycles and idempotently unlocked after the 49-day boundary.

Latest simulator auto-run:

- Passed: 14
- Failed: 0
- Generated DailyLifeRecords: 49
- Generated LifeAlbums: 7
- Generated CycleRecords: 7
- Generated StoryCards: 3
- Generated EraMemories: 1

## Broken Or Partial Paths

- There is still no formal XCTest target coverage; P0 validation is currently deterministic debug validation.
- The passive reconciler closes finalized/skipped Day 7 rows and active Day 7 night rows, but does not synthesize photo traits for missed days. Missed days intentionally remain placeholders.
- `PicoDiaryDatabase` remains a lower-level diary log. The memory system links diary IDs, but richer diary text aggregation can still be improved later.
- StoryCard visual presentation is intentionally subtle and evidence-linked, but deep evidence drilldown remains lightweight.
- Era reset behavior is represented by `EraMemory` creation and idempotent closure; richer post-reset world preparation remains a follow-up.

## Build Commands

Scheme inspection:

```sh
xcodebuild -list -project picod.xcodeproj
```

Debug simulator build:

```sh
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
```

Final build result:

- `xcodebuild -list -project picod.xcodeproj`: succeeded; scheme `picod` confirmed.
- `xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build`: succeeded.
- Simulator acceptance launch: `PICOD_RUN_P0_ACCEPTANCE=1` produced `passed=14 failed=0`.

## Remaining Blocking Issues

- No remaining blocking P0 acceptance issue found in this pass.
- Formal XCTest coverage is still a recommended follow-up, but the deterministic in-app validation route is green.
