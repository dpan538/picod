# Picod P1D World Projection Screenshot / Manual Audit

Date: 2026-07-03

Automated screenshot capture is deferred for P1D to avoid destabilizing the
simulator harness. The debug preview route is CLI-friendly and suitable for
manual screenshots.

## How To Open The Preview

Build and install the Debug simulator app, then launch with:

```sh
SIMCTL_CHILD_PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1 xcrun simctl launch --terminate-running-process B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

The preview appears in the DEBUG object/world audit surface. Use the scenario
picker under `WORLD PROJECTION PREVIEW`.

## Marker Legend

- spawn marker: pale circle with ink outline.
- photo mood: warm gold marker.
- Pico evolution: green marker.
- story trace: muted purple marker.
- cycle record: rust marker.
- era memory: pale light marker.
- participation stillness: olive marker.
- dashed line: approximate protected spawn-to-center readability path.

## Scenario Audit Table

| Scenario | Screenshot status | Base map | Projected elements | Story echoes | Issue count | Visual notes | Safe for future production preview |
| --- | --- | --- | ---: | ---: | ---: | --- | --- |
| `freshDay1Empty` | Manual route ready | `forestShrine` | 1 | 0 | warning-only | Sparse first-day stillness; should not feel broken. | Yes, behind debug gate |
| `day1WarmIndoorCapture` | Manual route ready | `forestShrine` | 2 | 0 | warning-only | Warm trace should sit near path while Pico remains readable. | Yes, behind debug gate |
| `day4RainyUmbrellaTrace` | Manual route ready | `wetlandLantern` | 3 | 1 | warning-only | Wetland identity and water-edge story trace should read as rainy. | Yes, with habitat follow-up |
| `day5NightLamplighterTrace` | Manual route ready | `nightGrove` | 3 | 1 | warning-only | Lamp-path trace should feel subtle and night-related. | Yes, with route polish follow-up |
| `day7MirrorClosure` | Manual route ready | `forestShrine` | 2 | 1 | warning-only | Shrine/reflection trace should feel like closure, not lore. | Yes, behind debug gate |
| `completedLifeAlbum` | Manual route ready | `forestShrine` | 1 | 0 | warning-only | Marker should feel Pico-retrospective, not world-cycle marker. | Yes, behind debug gate |
| `completedCycleRecord` | Manual route ready | `forestShrine` | 1 | 0 | warning-only | Torii/world marker should read as Cycle memory. | Yes, behind debug gate |
| `lowParticipationLife` | Manual route ready | `forestShrine` | 1 | 0 | warning-only | Quiet stillness should remain beautiful and non-punitive. | Yes, behind debug gate |
| `lockedEraMemory` | Manual route ready | `forestShrine` | 0 | 0 | warning-only | No Era echo should appear while locked. | Yes |
| `unlockedEraMemory` | Manual route ready | `forestShrine` | 2 | 1 | warning-only | Rare echo appears with unlocked Era evidence. | Yes, behind debug gate |

## Required Visual Checks

For every scenario:

- Pico spawn visible.
- Main route readable enough for debug preview.
- No projected element blocks Pico spawn.
- No high-priority story echo covers Pico.
- Story echoes include evidence IDs.
- Cycle marker appears only when cycle data exists.
- Era echo appears only when EraMemory is unlocked.
- Low participation appears quiet, not punitive.
- Fresh Day 1 appears empty but intentional.
- Scene does not feel overly cluttered.

## Deferred Screenshot Automation

Recommended P1E/P1F screenshot automation path:

1. Launch with `SIMCTL_CHILD_PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1`.
2. Add a DEBUG-only deep link or environment scenario selector if needed.
3. Use `xcrun simctl io booted screenshot` per scenario.
4. Store screenshots outside the app bundle and keep them out of commits unless
   explicitly requested.

No automated screenshot files were generated in P1D.
