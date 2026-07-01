# Picod Safety Scan - 2026-07-01

## Backup Status

- Remote: `git@github.com:dpan538/picod.git`
- Branch: `main`
- Latest pushed commit: `f67d9e9 backup current working snapshot`
- Safety snapshot chain:
  - `75edf1a Initial Commit`
  - `7dd72a0 backup staged project snapshot`
  - `f67d9e9 backup current working snapshot`

The first backup intentionally used two project commits:

1. Preserve the staged files that existed only in the git index.
2. Restore those missing files to disk, add current working files, add `.gitignore`, and push a fuller working snapshot.

## Public Repository Note

The GitHub repository currently appears to be public. A quick secret scan did not find obvious API keys, private keys, or large binary risks, but private is still safer while the app direction and source history are unstable.

## Quick Safety Results

- No obvious secrets found.
- Two `token` matches were ordinary code variables, not credentials:
  - `ContentView.swift`
  - `PetView.swift`
- No files over 25 MB.
- Repository size was about 12 MB before push.
- Ignored local-only files:
  - `.DS_Store`
  - `xcuserdata/`
  - `*.xcuserstate`
  - local build products

## Current Project Shape

Picod reads less like a conventional game and more like an ambient companion / living diorama:

- Daily camera capture wakes or updates Pico.
- Photo classification chooses a form.
- Palette extraction influences the companion/world tint.
- Movement, logs, diary records, and story fragments create quiet continuity.
- The strongest design spine is the 7-day life / 7-day cycle / 49-day era structure.

The game-like controls should be treated as optional low-pressure interactions, not the core promise.

## High Priority Missing Or Mismatched Pieces

These are static-scan blockers likely to prevent a clean build:

1. `DashboardView` is referenced from `ContentView.swift` but no `DashboardView.swift` implementation exists.
2. `CameraManager` is referenced by `ContentView.swift`, `MainView.swift`, and `CameraView.swift`, but no implementation exists.
3. `MapView` has an older initializer:
   - current implementation accepts only `tileSize`, `testMap`, `showPetSpawn`, `petCoord`
   - `ContentView.swift` passes `petFormId`, `petAccentHex`, `runtimeProps`, `runtimeAnimals`, and `ambientCurve`
4. `MapAmbientMoodCurve` is referenced but no definition was found.
5. `WorldSimulation` is older than `ContentView.swift` expects:
   - missing `latestEvent`
   - missing `runtimeProps`
   - missing `runtimeAnimals`
   - missing `manualMove`
   - missing `setAppState`
   - `checkIn` signature does not accept `formId`
6. `PhotoClassificationPipeline.resolve` has an older signature:
   - implementation accepts only raw labels
   - `ContentView.swift` passes dominant color, day index, previous generation form, and last chosen form
7. `PhotoTraitSnapshotDatabase` is missing APIs used by `ContentView.swift`:
   - `resetAll`
   - `extractBackgroundColor`
8. `WorldSeedEngine.mockGenerate` is referenced but missing.
9. `DevTestMode` is missing flags referenced by `ContentView.swift`:
   - `showMockSeed`
   - `runPhotoPipelineMockValidation`
   - `showPhotoPipelineDebug`

## Suggested Next Development Plan

### Phase 1 - Compile Recovery

Goal: get a clean CLI build without opening Xcode UI.

- Add or recover `DashboardView.swift`.
- Add `CameraManager`.
- Bring `MapView` up to the interface expected by `ContentView.swift`.
- Upgrade `WorldSimulation` to expose events, runtime props/animals, manual movement, and app-state gating.
- Upgrade `PhotoClassificationPipeline.resolve` to match the current photo lifecycle.
- Add missing database helpers and debug flags.
- Only after static blockers are fixed, run a low-noise CLI build with DerivedData under `/tmp`.

### Phase 2 - MVP Direction Lock

Goal: stop the project from splitting between companion and game.

Recommended positioning:

> Picod is a quiet photo-fed companion world for iOS where daily captures shape Pico, its diary, and a living pixel diorama.

MVP loop:

1. User takes one photo per day.
2. Pico receives or updates a form.
3. The world changes subtly.
4. Pico wanders and records observations.
5. The diary summarizes the day.
6. A 7-day lineage view gives continuity.

Defer for later:

- Joystick-heavy control mode.
- Pickup systems.
- Explicit quests or win/lose structures.
- Large visual asset expansion.

### Phase 3 - Structure Cleanup

Goal: make future work less brittle.

- Split `ContentView.swift` into smaller surfaces:
  - dashboard
  - camera flow
  - photo processing
  - diary/story overlays
  - world rendering wrapper
- Move large static pixel-form data out of `PetView.swift` when convenient.
- Keep mock screenshots and mock validators as regression references.
- Add small pure-Swift tests for mapping, world seeds, and daily snapshot rules before adding new gameplay.

## Build Policy

Avoid opening Xcode UI for now. Prefer static scans and CLI builds. The previous `xcodebuild -list` attempt hung and had to be stopped, so the next build attempt should happen only after the missing interfaces above are fixed.
