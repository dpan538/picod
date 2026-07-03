# P1G Limited Production Evidence UX Report

Date: 2026-07-03

## Baseline

- Branch: `p1-world-richness-integration`
- Starting commit: `886a0a1 P1 world projection and memory-map evidence linking`
- Starting working tree: clean.
- Deleted files before edits: none.
- `git diff --check` before edits: passed.
- Debug simulator build before edits: passed.
- P0 acceptance before edits: passed 14 / failed 0.
- World audit before edits: static maps 5 / projection scenarios 10 / errors 0 / warnings 320 / actions 320 / high 55.
- Evidence-link audit before edits: anchors 35 / unresolved 0 / duplicate anchors 0 / locked leaks 0 / missing evidence 0.

## Scope

P1G promotes a limited, text-only portion of memory-map evidence into normal
Memory Drawer detail UX. Projection rendering remains gated and is not the
default normal-user map path.

Allowed normal-user surfaces:

- DailyLifeRecord detail
- StoryCard detail
- LifeAlbum detail
- CycleRecord detail
- EraMemory detail after unlock

Not exposed in normal UI:

- projection preview panels
- validator/auditor language
- raw evidence IDs
- projected element IDs
- catalog IDs
- anchor coordinates
- confidence scores
- raw JSON/store terminology

## Files Changed

- `picod/PicodUserFacingText.swift`
- `picod/PicodStagePreviewView.swift`
- `picod/WorldMapRichnessAudit.swift`
- `docs/P1G_LIMITED_PRODUCTION_EVIDENCE_UX_REPORT.md`
- `docs/P1G_EVIDENCE_COPY_GUIDE.md`
- `docs/P1_WORLD_AUDIT_BASELINE.md`

## User-Facing UX Changes

Memory Drawer detail text now uses `PicodWorldTraceText` helpers for world trace
copy. The detail layout remains the same; the change is limited to softer,
deterministic text fragments.

DailyLifeRecord detail:

- Shows one or two calm world trace lines.
- Captured days prefer photo/map mood evidence.
- Missed or future days fall back to quiet placeholder text.

StoryCard detail:

- Keeps first seen, last seen, recurrence count, and evidence fragments.
- Shows up to three subtle world trace lines.
- Locked cards remain ambiguous and do not show a visible map anchor.

LifeAlbum detail:

- Shows a seven-day retrospective trace.
- Adds a captured-day rhythm line when no anchor is available.

CycleRecord detail:

- Shows world marker/cycle rhythm text.
- Stays distinct from Life Album language.

EraMemory detail:

- Locked state remains quiet.
- Unlocked state shows one rare echo line.
- The reset is not directly explained.

## Copy Helpers Added

`PicodWorldTraceText` centralizes production-safe evidence copy:

- `worldTraceLine(for:languageCode:)`
- `dailyTraceLine(for:anchors:didCapturePhoto:mapMood:languageCode:)`
- `storyEvidenceLine(for:languageCode:)`
- `storyEvidenceLine(for:anchors:displayState:recurrenceCount:languageCode:)`
- `lifeAlbumTraceLine(for:anchors:capturedDays:languageCode:)`
- `cycleTraceLine(for:anchors:toriiCount:languageCode:)`
- `eraTraceLine(for:anchors:isUnlocked:languageCode:)`

These helpers:

- keep text short and calm
- avoid raw IDs and debug/audit words
- localize English and Chinese copy
- provide deterministic fallbacks for missing anchors/projection data
- keep locked EraMemory unrevealed

## Regression Guard

`PicodEvidenceCopyDebugValidator` adds deterministic copy checks for:

1. `umbrella_woman` story evidence copy
2. `night_lamplighter` story evidence copy
3. `mirror_miko` story evidence copy
4. DailyLifeRecord fallback copy
5. LifeAlbum retrospective copy
6. CycleRecord marker copy
7. Locked EraMemory quiet copy
8. Unlocked EraMemory rare echo copy
9. Missing projection fallback copy
10. Forbidden normal-UI term scan

The copy validator is printed by the world audit console as an additive line. It
does not alter static map counts, projection counts, warning counts, or evidence
link counts.

## Validation Commands

```sh
git diff --check
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
xcrun simctl install B862520B-F900-4497-914A-DE36E90DFF3B /tmp/picod_build/Build/Products/Debug-iphonesimulator/picod.app
SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
SIMCTL_CHILD_PICOD_RUN_WORLD_RICHNESS_AUDIT=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
xcrun simctl launch --terminate-running-process B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
SIMCTL_CHILD_PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1 xcrun simctl launch --terminate-running-process B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
SIMCTL_CHILD_PICOD_USE_WORLD_PROJECTION_MAP=1 xcrun simctl launch --terminate-running-process B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
SIMCTL_CHILD_PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1 SIMCTL_CHILD_PICOD_USE_WORLD_PROJECTION_MAP=1 xcrun simctl launch --terminate-running-process B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Observed final result:

- `git diff --check`: passed.
- Debug simulator build: passed.
- P0 acceptance: passed 14 / failed 0.
- World audit: errors 0 / warnings 320 / actions 320 / high 55.
- Evidence-link audit: unresolved 0 / duplicate anchors 0 / locked leaks 0 / missing evidence 0.
- Evidence copy audit: failed 0.
- Normal smoke launch: passed.
- P1D projection preview smoke launch: passed.
- P1E gated projection map smoke launch: passed.
- Combined preview + gated projection smoke launch: passed.

## Remaining Work

- The world audit warning backlog remains 320 warnings / 55 high actions.
- Production map highlighting from Memory Drawer remains deferred.
- Projection rendering remains gated behind DEBUG/runtime flags.
- Real-device QA is still blocked by unavailable physical hardware, not by a
  known product defect.

## P1H Readiness

P1H art-direction screenshot review is safe to start. It should focus on visual
tone, text fit, Memory Drawer readability, and whether the text-only evidence
fragments feel calm rather than explanatory.

## Guardrails Confirmed

- No Pico forms were added.
- No storylines were added.
- No map variants were added.
- No folklore content was expanded.
- Normal MapView projection rendering remains off by default.
- `MapView` still does not read memory stores directly.
- No audit warnings were silenced or downgraded.
- No reset, rebase, or discard was performed.
