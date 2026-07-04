# Picod P1K Real-Device Frontend And Longitudinal QA Report

Date: 2026-07-04

Branch: `p1-world-richness-integration`

Starting commit: `c12be26f7fbd4f40504ac8ac01dc3af3e3f11887`

## Scope

P1K focused on the first real-device frontend issues from P1J and added deterministic long-loop QA. Projection remains gated and is still not allowed for default-on production, App Store default-on, or external TestFlight default-on.

No new Pico forms, storylines, map variants, folklore content, projection defaults, MapView memory-store reads, app architecture rewrites, Memory Drawer rewrites, or P0 canonical memory semantic rewrites were introduced.

## Baseline

| Check | Result |
| --- | --- |
| `git status --short --branch` | Clean at baseline on `p1-world-richness-integration` |
| `git log -1 --oneline` | `c12be26 Document P1J go-no-go and real-device QA resume` |
| `git diff --check` | Passed |
| `git ls-files --deleted` | No deleted files |
| Debug simulator build | Passed |
| P0 acceptance | Passed: `passed=14 failed=0`; generated `daily=49 albums=7 cycles=7 cards=3 eras=1` |
| World audit | Passed core gates: `errors 0 / high 0` |
| Evidence copy audit | Passed: `failed 0` |
| Evidence link audit | Passed: `unresolved 0 / duplicate anchors 0 / locked leaks 0 / missing evidence 0` |

Device model if physically tested in this pass: not retested on hardware during P1K.

Last known physical QA from P1J: iPhone 14 / iOS 26.0.1, build/install/launch and projection launch modes succeeded.

## Frontend Fixes

| Area | Change | Result |
| --- | --- | --- |
| Photo entry | Replaced `TODAY'S PHOTO` plus `CHOOSE PHOTO` with one compact camera-icon `PHOTO` button. | Passed simulator screenshot sanity check. |
| Photo source sheet | The single button opens the existing short source sheet with `Take Photo`, `Choose from Library`, and cancel. | Camera and library fallback retained. |
| Accessibility | PHOTO button label is `Photo. Take or choose today's photo.` | Added. |
| Top status | Header copy now uses short state-based lines: `waiting for today's photo`, `checking local context`, `local context is quiet`, `local context ready`, `today is remembered`. | Fits iPhone-size screenshot beside the gear. |
| Camera UI | Day/cycle label contrast increased, filmstrip strips removed, shutter simplified to a white circle with black outline. | Build verified; hardware camera route still needs hands-on visual QA. |
| DEBUG audit panel | Object gallery / projection audit route now opens as a full-height DEBUG screen instead of being trapped inside the map square. | DEBUG-only route remains env-gated. |
| Pre-photo map | Added a shared pre-photo map policy so no active Pico spawn appears before today's capture, including with projection gate on. | Longitudinal audit passed. |
| P0 story projection | Normalized camel-case P0 StoryCard IDs to snake-case world projection IDs at resolver/projector boundary. | NPC/story projection audit passed. |

Simulator screenshot captured: `/tmp/picod-p1k-normal.png`.

## Pre-Photo No-Pico Regression

Audit command: `SIMCTL_CHILD_PICOD_RUN_LONGITUDINAL_LOOP_AUDIT=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod`

Summary: `prePhoto=pass`.

| Case | Projection gate | Active Pico allowed | Pico signals | Pico trace elements | Result |
| --- | --- | ---: | ---: | ---: | --- |
| Fresh install before photo | Off | 0 | 0 | 0 | Pass |
| Day 2 before photo | Off | 0 | 0 | 0 | Pass |
| Day 7 before photo | Off | 0 | 0 | 0 | Pass |
| Day 8 / new Life before photo | Off | 0 | 0 | 0 | Pass |
| Relaunch before today's photo | Off | 0 | 0 | 0 | Pass |
| Projection gate off before photo | Off | 0 | 0 | 0 | Pass |
| Projection gate on before photo | On | 0 | 0 | 0 | Pass |

No egg placeholder is intentionally shown before capture in the current main map.

## Seven-Day Environment And Map Complexity

Summary: `sevenDay=pass`.

| Day | Seed | Form | Changed trait | Map variant | Elements | Persistent | Transient | Story traces | NPC count | Validation |
| --- | --- | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | `form_56` | 56 | hatch | forestShrine | 2 | 1 | 1 | 0 | 0 | 0 errors |
| 2 | `form_2` | 2 | textureTrait | forestShrine | 2 | 1 | 1 | 0 | 0 | 0 errors |
| 3 | `form_2` | 2 | appendageTrait | forestShrine | 2 | 1 | 1 | 0 | 0 | 0 errors |
| 4 | `form_23` | 23 | anomalyMark | wetlandLantern | 3 | 1 | 1 | 1 | 1 | 0 errors |
| 5 | `form_30` | 30 | memoryScar | nightGrove | 3 | 1 | 1 | 1 | 1 | 0 errors |
| 6 | `form_30` | 30 | eyeTrait | nightGrove | 3 | 1 | 1 | 1 | 1 | 0 errors |
| 7 | `form_45` | 45 | anomalyMark | forestShrine | 3 | 1 | 1 | 1 | 1 | 0 errors |

Day 7 meaningful trace count is greater than Day 1. The audit does not require strict monotonic visual counts because weather/time layers can vary.

## NPC / Story Trigger QA

Summary: `npc=pass`.

| Story | Trigger inputs | Expected | Actual | StoryCard / evidence | Result |
| --- | --- | --- | --- | --- | --- |
| `night_lamplighter` | Day 3 afternoon clear -> Day 5 night | Absent before night, present on Day 5/6 night | Before absent, Day 5 present | `encountered`; card evidence 2, map traces 2, projected story 1 | Pass |
| `umbrella_woman` | Day 4 clear -> Day 4 rain | Absent without rain, present with rain | Clear absent, rain present | `encountered`; card evidence 1, map trace 1, projected story 1 | Pass |
| `mirror_miko` | Day 6 no reflection -> Day 7 reflection | Absent before reflection, present on Day 7 closure/reflection; locked EraMemory does not leak | Day 6 absent, Day 7 present, locked era leak false | `encountered`; card evidence 1, map trace 1, projected story 1 | Pass |

No second-batch folklore characters were activated.

## Smoke Launches

| Mode | Result |
| --- | --- |
| Normal mode | Passed launch smoke |
| `PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1` | Passed launch smoke |
| `PICOD_USE_WORLD_PROJECTION_MAP=1` | Passed launch smoke |
| Both projection flags | Passed launch smoke |

Normal projection remains off by default. `MapView` still does not read memory stores directly.

## Open Hardware QA Items

These were not completed during P1K because they require hands-on physical interaction with the iPhone and camera/photo permission prompts:

1. Tap new single PHOTO button on iPhone.
2. Take a real photo.
3. Choose from library.
4. Cancel action sheet.
5. Deny camera permission.
6. Allow camera permission.
7. Deny location permission.
8. Allow location permission.
9. Verify Today's Trace after capture.
10. Verify Memory Drawer after capture.
11. Relaunch after capture.
12. Verify no active Pico before next daily capture on hardware.
13. Gated projection mode launch after capture.
14. Normal mode remains projection-free after capture.
15. Capture screenshots after capture, camera UI, and Memory Drawer day detail.

## Result

P1K simulator build, P0 acceptance, world audit, evidence-copy audit, evidence-link audit, smoke launches, pre-photo regression audit, 7-day map/environment audit, NPC/story trigger audit, five-trajectory sampling, and seven-cycle lineage audit all pass.

P1L is recommended as a focused physical-device interaction pass, not as a blocker for the simulator/debug validation completed here.
