# P1H Art Direction Screenshot Review

Date: 2026-07-03

## Baseline

- Branch: `p1-world-richness-integration`
- Starting commit: `916586d P1 world projection, evidence links, and production trace UX`
- Working tree before review: clean.
- Deleted files before review: none.
- `git diff --check` before review: passed.
- Debug simulator build before review: passed.
- P0 acceptance before review: `passed=14 failed=0`.
- World audit before review: `static maps 5 / projection scenarios 10 / errors 0 / warnings 320 / actions 320 / high 55`.
- Evidence-link audit before review: `unresolved 0 / duplicate anchors 0 / locked leaks 0 / missing evidence 0`.
- Evidence-copy audit before review: `evidence copy checked 10 / failed 0`.

## Review Routes

- Normal mode: no environment flag.
- DEBUG projection preview: `SIMCTL_CHILD_PICOD_SHOW_WORLD_PROJECTION_PREVIEW=1`.
- DEBUG gated projection map: `SIMCTL_CHILD_PICOD_USE_WORLD_PROJECTION_MAP=1`.
- Combined DEBUG mode: both flags together.

Screenshots captured for this pass:

- `/tmp/picod_p1h_normal.png`
- `/tmp/picod_p1h_projection_preview.png`
- `/tmp/picod_p1h_gated_projection_map.png`

Screenshots were used as review evidence only and were not committed.

## Global Visual Findings

- Normal mode did not show a projection or debug badge.
- Projection rendering remains gated.
- The gated projection map rendered without crashing and kept Pico readable in the current-memory case.
- The DEBUG projection badge is correctly limited to gated mode.
- The DEBUG audit/preview panel is useful but vertically competes with the main HUD on phone-sized screens. This is acceptable for DEBUG, but should be improved before repeated art review sessions.
- The normal first-launch / unresolved-location state can show a large empty map area while context resolves. This is not a P1H world-projection bug, but it is a real product polish risk because it reads less alive than the intended quiet board.

## Scenario Review

| Scenario | Route / Flag | Screenshot Path | Visual Result | Copy Result | Top Issue | Severity | Recommended Action |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `freshDay1Empty` | DEBUG projection preview, scenario picker | Manual review; shared `/tmp/picod_p1h_projection_preview.png` | Partial | Pass | Fresh state is intentionally sparse, but normal unresolved-location state can look blank before the map arrives. | Medium | Add a non-debug art review target for loaded fresh Day 1 and later consider a gentler loading board. |
| `day1WarmIndoorCapture` | DEBUG projection preview, default selected scenario | Shared `/tmp/picod_p1h_projection_preview.png` | Partial | Pass | Warm trace is conceptually right, but forestShrine still reports route/spawn visual occlusion risk. | Medium | Keep copy; tune route-adjacent canopy/props in P1I. |
| `day4RainyUmbrellaTrace` | DEBUG projection preview / audit scenario | Manual review from audit and scenario provider | Partial | Pass | Rain/umbrella meaning is strong, but wetlandLantern still has spawn/route occlusion warnings and two invalid-habitat warnings. | High | Prioritize wetlandLantern route readability and wetland habitat placement before production projection. |
| `day5NightLamplighterTrace` | DEBUG projection preview / audit scenario | Manual review from audit and scenario provider | Partial | Pass | Lamp/night language fits, but nightGrove has repeated route occlusion warnings near the lamplighter path. | High | Reduce nightGrove route occlusion while preserving night density and lamp mood. |
| `day7MirrorClosure` | DEBUG projection preview / audit scenario | Manual review from audit and scenario provider | Partial | Pass | Shrine/reflection tone is correct, but forestShrine route/spawn occlusion remains the shared blocker for confident rendering. | Medium | Tune forestShrine route readability and preserve the shrine axis. |
| `completedLifeAlbum` | DEBUG projection preview / audit scenario | Manual review from audit and scenario provider | Partial | Pass | Retrospective trace is valid but visually minimal; it may not yet feel like a seven-day object. | Medium | In P1I/P1J, art-direct the Life Album marker without adding lore or forms. |
| `completedCycleRecord` | DEBUG projection preview / audit scenario | Manual review from audit and scenario provider | Partial | Pass | Cycle marker count is valid and evidence-backed, but route/spawn warnings still make production rendering premature. | Medium | Keep CycleRecord distinct from LifeAlbum; tune marker placement after route warnings are reduced. |
| `lowParticipationLife` | DEBUG projection preview / audit scenario | Manual review from audit and scenario provider | Pass | Pass | Low participation reads quiet rather than punitive; the remaining risk is that quietness can become visually empty if the base map has not loaded. | Low | Preserve this tone; avoid adding punitive text or decay language. |
| `lockedEraMemory` | DEBUG projection preview / evidence audit | Manual review from audit and scenario provider | Pass | Pass | Locked EraMemory does not leak visible era anchors. | Low | Keep hidden/quiet until unlock. |
| `unlockedEraMemory` | DEBUG projection preview / audit scenario | Manual review from audit and scenario provider | Partial | Pass | Rare echo is evidence-backed and unlocked only after boundary, but forestShrine occlusion warnings still apply. | Medium | Keep copy rare; tune visual echo only after route clarity improves. |

## Story-Specific Notes

### night_lamplighter

- Copy result: pass.
- Current line: `The lamp remembered this night.`
- Art direction: the phrase feels connected to night and path memory without explaining the visitor.
- Visual risk: nightGrove route occlusion can make a lamp/path trace feel like clutter instead of someone passing through.

### umbrella_woman

- Copy result: pass.
- Current line: `The rain stayed on the stones.`
- Art direction: quiet, rainy, and uneasy without identifying the visitor.
- Visual risk: wetlandLantern still needs water-edge and habitat tuning so the umbrella trace feels placed, not dropped.

### mirror_miko

- Copy result: pass.
- Current line: `Something by the shrine looked back.`
- Art direction: strange enough for Day 7 / mirror logic, but not a lore dump.
- Visual risk: keep the shrine/reflection relationship legible before adding any stronger echo.

## Main / Map Preview Result

- Pico readability: pass in current-memory gated projection screenshot.
- Calm map tone: pass, with caveat that the DEBUG badge darkens a corner of the map.
- Route readability: partial because audit still reports route/spawn occlusion warnings.
- Grounding: partial because wetland and decorative grounding warnings remain.
- Story echoes: pass on evidence integrity, partial on final art placement.
- Scene identity: pass; current maps still feel like Picod rather than a generic object dump.

## Memory Drawer Result

- Detail copy is understandable and calm.
- `World trace` labels are user-facing and not debug-heavy.
- No raw IDs, coordinates, validator, audit, projection, or confidence terms appear in normal copy.
- Story copy remains fragmentary and does not explain the full truth.
- Chinese copy is natural enough for P1H and should be revisited during real-device localization QA.

## Blocking Assessment

P1H found no blocker that requires an immediate code fix.

The biggest risk is visual readiness for production projection, not correctness:

- route/spawn visual occlusion warnings remain high-priority
- wetland habitat placement needs tuning
- DEBUG review UI could be easier to inspect on small screens
- fresh unresolved-location state can look too empty

P1I targeted warning remediation is safe to start.
