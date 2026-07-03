# Picod P0 Screenshot Audit

This audit is intentionally CLI-friendly but not fully automated yet. The current project has stable DEBUG hooks for opening Settings, opening the Memory Drawer, and running the P0 acceptance harness. Use those before adding screenshot automation.

## Build

```sh
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
```

## Simulator Launch Helpers

Run the acceptance harness:

```sh
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Open the Memory Drawer on launch:

```sh
env SIMCTL_CHILD_PICOD_OPEN_SIDE_STORY=1 xcrun simctl launch --terminate-running-process B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Open Settings on launch:

```sh
env SIMCTL_CHILD_PICOD_OPEN_SETTINGS=1 xcrun simctl launch --terminate-running-process B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Capture the simulator screen after the target state is visible:

```sh
xcrun simctl io B862520B-F900-4497-914A-DE36E90DFF3B screenshot /tmp/picod-p0-state.png
```

## Required Audit States

1. Fresh Day 1
   - Main screen asks for one photo and does not show debug internals.

2. After Day 1 capture
   - Today Trace appears, Pico changes, Current Life Day 1 slot is captured.

3. Day 4 rainy umbrella trace
   - Run DEBUG P0 checks, open Memory Drawer, confirm umbrella-related StoryCard evidence is subtle and fragmentary.

4. Day 5 night lamplighter trace
   - Run DEBUG P0 checks, open Memory Drawer, confirm night lamp evidence and diary/map trace wording.

5. Day 7 final form
   - Run DEBUG P0 checks, inspect completed Life Album and Day 7 detail.

6. Completed Life Album
   - Life Albums section shows date range, seven-day rhythm, final Pico fallback, mood, recurring traits, and story hints.

7. Cycle Record
   - Cycle Records section emphasizes world markers, participation rhythm, weather/time rhythm, and visitors.

8. Story Card partial
   - StoryCard in trace/encountered state shows first seen, last seen, recurrence, and 1-3 evidence fragments.

9. Story Card recurring
   - Recurring StoryCard does not duplicate evidence and does not dump lore.

10. Locked Era Memory
    - Before 49-day completion, Era Memory is quiet and not visible as an explanation of reset.

11. Unlocked Era Memory
    - After the acceptance harness, Era Memory appears as a rare memory with echoes, not an explicit reset explainer.

## Current Automation Status

Full screenshot state seeding is documented rather than automated in this pass to avoid destabilizing the P0 acceptance harness. The DEBUG acceptance route remains the canonical deterministic state generator.
