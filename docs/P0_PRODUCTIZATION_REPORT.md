# Picod P0 Productization & Real-Device Readiness Report

## Safety Checkpoint

Local working tree is treated as source of truth. No reset, discard, rebase, destructive overwrite, push, or commit was performed.

Baseline commands:

```sh
git status --short --branch
git diff --stat
xcodebuild -list -project picod.xcodeproj
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Baseline result:

- Scheme `picod` confirmed.
- Debug iOS simulator build succeeded.
- P0 acceptance harness passed: `passed=14 failed=0`.
- Acceptance harness generated 49 DailyLifeRecords, 7 LifeAlbums, 7 CycleRecords, 3 StoryCards, and 1 EraMemory.

## Productization Work

Completed in this pass.

### Files Changed In This Pass

- `picod/ContentView.swift`
- `picod/DashboardView.swift`
- `picod/PicodStagePreviewView.swift`
- `picod/PicodMemoryStore.swift`
- `picod/PicodMemoryExporter.swift`
- `picod/PicodUserFacingText.swift`
- `docs/P0_PRODUCTIZATION_REPORT.md`
- `docs/REAL_DEVICE_P0_QA.md`
- `docs/P0_SCREENSHOT_AUDIT.md`

### UX Paths Verified

- Main screen keeps camera capture as the primary Daily Capture action.
- Main screen now exposes a quiet choose-photo fallback when today still needs a capture.
- Same-day duplicate captures remain idempotent: no duplicate DailyLifeRecord is created and the user sees that today's photo is already saved.
- Camera denied/unavailable copy now points to the photo-library fallback instead of feeling like a dead end.
- Normal users no longer see form IDs, seed IDs, confidence scores, or matcher jargon in post-capture feedback.
- DEBUG P0 route remains in Settings only behind `#if DEBUG`.

### Photo Influence Legibility

- Added `PicodTodayTraceText` and `TodayTraceToastView`.
- Post-capture feedback now shows 1-3 soft lines such as color, movement, map mood, or subtle story trace.
- Low-confidence or empty-label captures are phrased as mood/feeling rather than failure.
- Capture log entries use the same user-facing trace text instead of raw form numbers.

### Memory Drawer Improvements

- Current Life slots always render as seven visible slots.
- Slot states distinguish captured, today, quiet placeholder, and later days.
- Tapping a day now shows photo state, Pico state, diary fallback, map mood, and story evidence.
- Life Albums now read as seven-day Pico lives with date range, capture rhythm, dominant mood, recurring traits, story hints, and closing text/fallback.
- Cycle Records now emphasize world-level rhythm: markers, participation, weather/time rhythm, visitors, and summary.
- Era Memory remains quiet/locked until present and appears as rare memory text plus echoes after unlock.
- DEBUG preview story signals were narrowed to the three P0 active storylines: night_lamplighter, umbrella_woman, mirror_miko.

### Diary Aggregation Improvements

- Added deterministic diary fragments through `PicodDiaryTextBridge`.
- DailyLifeRecord detail surfaces a diary fragment even if the lower-level diary log has no rich entry yet.
- LifeAlbum detail summarizes seven-day diary rhythm with captured days, quiet placeholders, dominant mood, and story trace count.
- New DailyLifeRecords align `diaryEntryID` with StoryCard diary evidence IDs.

### Story Evidence Improvements

- StoryCards now show first seen, last seen, recurrence count, and up to three evidence fragments.
- Evidence fragments are derived from DailyLifeRecords and include day index, diary fragment, and map/story trace context.
- Evidence lookup tolerates duplicate DailyLifeRecord IDs without crashing.
- StoryCardStore remains deduplicated for daily record, diary, and map trace evidence.

### Empty, Error, And Partial States

- First launch still prompts for one photo and avoids debug text.
- Camera denied/unavailable path has plain user copy and a photo-picker fallback.
- Photo import failure shows a soft retry message.
- Missing or low-confidence classification still produces deterministic mood-based feedback.
- Memory Drawer empty states stay calm for no albums, no cycles, no story cards, and locked Era Memory.
- Missed days are visible quiet placeholders, not punishment.
- LifeAlbum export now uses duplicate-safe day-slot filling.

### Real-Device QA Checklist

Created `docs/REAL_DEVICE_P0_QA.md` with the requested 20 real-device cases:

- fresh install
- camera allowed/denied
- photo library path
- successful capture
- same-day duplicate behavior
- relaunch persistence
- offline/no network
- location allowed/denied
- low light, bright, and unrecognized photos
- seven-day simulation
- Memory Drawer after simulation
- corrupt JSON fallback
- foreground date boundary reconciliation
- Reduce Motion
- small and larger iPhone screens

### Screenshot Audit Route

Created `docs/P0_SCREENSHOT_AUDIT.md`.

- Documents the existing CLI-friendly DEBUG routes:
  - `PICOD_RUN_P0_ACCEPTANCE=1`
  - `PICOD_OPEN_SIDE_STORY=1`
  - `PICOD_OPEN_SETTINGS=1`
- Documents simulator screenshot capture with `xcrun simctl io ... screenshot`.
- Full state-seeded screenshot automation remains documented/manual to avoid destabilizing the P0 acceptance harness.

## Final Verification

Final commands:

```sh
xcodebuild -list -project picod.xcodeproj
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
xcrun simctl bootstatus B862520B-F900-4497-914A-DE36E90DFF3B -b
xcrun simctl install B862520B-F900-4497-914A-DE36E90DFF3B /tmp/picod_build/Build/Products/Debug-iphonesimulator/picod.app
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
xcrun simctl terminate B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Final result:

- Scheme `picod` confirmed.
- Debug iOS simulator build succeeded.
- P0 acceptance harness passed after productization edits: `passed=14 failed=0`.
- Acceptance harness generated 49 DailyLifeRecords, 7 LifeAlbums, 7 CycleRecords, 3 StoryCards, and 1 EraMemory.

## Remaining Blockers Or Partials

- No blocking P0 acceptance issue found.
- No XCTest target exists yet; deterministic DEBUG acceptance remains the validation path.
- Real-device camera/library behavior still needs manual verification using `docs/REAL_DEVICE_P0_QA.md`.
- Screenshot audit is documented/manual rather than fully automated.
- Diary aggregation remains intentionally lightweight and deterministic; no network AI or large writing system was introduced.
- Era reset representation remains basic and quiet, as intended for P0.

## Safety Confirmation

No push, commit, reset, rebase, discard, or destructive overwrite of local uncommitted work was performed.
