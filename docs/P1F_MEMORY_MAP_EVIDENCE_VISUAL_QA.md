# P1F Memory Map Evidence Visual QA

Date: 2026-07-03

## Scope

P1F visual QA checks whether Memory Drawer records can describe world traces
from `WorldStateProjection` anchors without turning the normal UI into a debug
panel. This pass does not promote projection rendering to production default.

## Normal UI Checks

| Surface | Expected | Status |
| --- | --- | --- |
| DailyLifeRecord detail | Shows a soft world trace fragment or fallback. | Passed |
| StoryCard detail | Keeps first/last/recurrence evidence and adds a world trace fragment. | Passed |
| LifeAlbum detail | Adds a seven-day retrospective world trace or fallback. | Passed |
| CycleRecord detail | Adds world marker/rhythm trace or fallback. | Passed |
| EraMemory detail | Shows a rare echo only when the memory is available; otherwise stays quiet. | Passed |
| Main screen | No new debug/audit clutter. | Passed |
| Settings | No new normal-user projection controls. | Passed |

Normal UI words intentionally avoid: projection, anchor, validator, evidence ID,
audit, catalog ID, projected element ID.

## DEBUG Preview Checks

| Scenario | Anchor expectation | Status |
| --- | --- | --- |
| freshDay1Empty | Empty or quiet fallback, no crash. | Passed |
| day1WarmIndoorCapture | Photo/Pico/day trace can produce a visible or hinted anchor. | Passed |
| day4RainyUmbrellaTrace | Umbrella/rain story evidence links to wet edge/path trace. | Passed |
| day5NightLamplighterTrace | Night/light evidence links to lamp/path trace. | Passed |
| day7MirrorClosure | Mirror closure links to shrine/reflection-style trace. | Passed |
| completedLifeAlbum | Retrospective life trace is available or gracefully falls back. | Passed |
| completedCycleRecord | Cycle marker anchor is visible when cycle data exists. | Passed |
| lowParticipationLife | Quiet/missed-day evidence remains non-punitive. | Passed |
| lockedEraMemory | No visible era echo leaks. | Passed |
| unlockedEraMemory | Rare remembered echo anchor appears. | Passed |

## Highlight Behavior

In DEBUG projection preview:

- selecting an evidence anchor highlights its projected element
- the selected anchor card shows source type, anchor kind, display state,
  validation state, projected element ID, catalog ID, evidence ID, and debug
  reason
- locked era anchors remain hidden instead of highlighted
- missing anchors retain fallback text and do not crash the preview

## Smoke Launches

| Mode | Flag | Expected | Status |
| --- | --- | --- | --- |
| Normal | none | App launches; no projection badge or debug evidence panel. | Passed |
| P1D preview | `PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1` | DEBUG preview launches and anchor list is inspectable. | Passed |
| P1E gated map | `PICOD_USE_WORLD_PROJECTION_MAP=1` | Gated map launches with projection path and no crash. | Passed |
| Combined | both flags | Preview and gated projection can coexist without crash. | Passed |

## Visual Notes

- The Memory Drawer evidence line is intentionally short so it does not compete
  with diary fragments or story evidence.
- The DEBUG highlight ring is diagnostic only and appears only inside the
  projection preview overlay.
- The normal map remains the existing map path when projection gates are off.
- Evidence anchors are derived from projected element evidence, so story/cycle
  traces remain tied back to canonical P0 memory rather than free-floating
  decoration.

## Deferred

- Production tap-to-highlight from Memory Drawer into the main map.
- Screenshot capture of every anchor highlight state.
- User-facing map highlight affordance and transition design.
- Reducing the existing world warning backlog.
