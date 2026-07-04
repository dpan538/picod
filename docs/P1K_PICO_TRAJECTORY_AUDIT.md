# Picod P1K Pico Trajectory Audit

Date: 2026-07-04

Audit command: `SIMCTL_CHILD_PICOD_RUN_LONGITUDINAL_LOOP_AUDIT=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod`

Summary: `trajectories=pass`.

## Assertions

Each sampled trajectory checks:

- Day 1 hatches.
- Day 2-6 inherit the previous day's genome.
- No random full-body replacement occurs.
- Only one major trait changes per day after hatch.
- Core color persists across the Life.
- Accent color and anomaly/scar changes stay controlled.
- Day 7 final form is stored in a seven-slot LifeAlbum.
- Next Life starts from a fresh hatch with `genomeBefore=nil`.
- Next Life does not silently inherit the previous Life's active body genome.

## Five Seven-Day Trajectories

| Family | Day 1-7 selectedSeedID | Rendered forms | Changed traits | One-major-trait | Core color | LifeAlbum | Next Life | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `warmIndoorObject` | `form_56 -> form_2 -> form_2 -> form_23 -> form_30 -> form_30 -> form_45` | `56,2,2,23,30,30,45` | hatch, textureTrait, appendageTrait, anomalyMark, memoryScar, eyeTrait, anomalyMark | Pass | Pass | 7 slots, final 45 | `genomeBefore=nil`, hatch lineage starts from `form_56` | Pass |
| `plantNature` | `form_90 -> form_47 -> form_47 -> form_48 -> form_47 -> form_47 -> form_47` | `90,47,47,48,47,47,47` | hatch, textureTrait, appendageTrait, anomalyMark, memoryScar, eyeTrait, anomalyMark | Pass | Pass | 7 slots, final 47 | `genomeBefore=nil`, hatch lineage starts from `form_90` | Pass |
| `rainWater` | `form_48 -> form_48 -> form_48 -> form_48 -> form_48 -> form_48 -> form_48` | `48,48,48,48,48,48,48` | hatch, textureTrait, appendageTrait, anomalyMark, memoryScar, eyeTrait, anomalyMark | Pass | Pass | 7 slots, final 48 | `genomeBefore=nil`, hatch lineage starts from `form_48` | Pass |
| `nightLampDark` | `form_56 -> form_76 -> form_76 -> form_48 -> form_30 -> form_30 -> form_30` | `56,76,76,48,30,30,30` | hatch, textureTrait, appendageTrait, anomalyMark, memoryScar, eyeTrait, anomalyMark | Pass | Pass | 7 slots, final 30 | `genomeBefore=nil`, hatch lineage starts from `form_56` | Pass |
| `animalOutdoorOrPersonObject` | `form_20 -> form_3 -> form_3 -> form_48 -> form_30 -> form_30 -> form_3` | `20,3,3,48,30,30,3` | hatch, textureTrait, appendageTrait, anomalyMark, memoryScar, eyeTrait, anomalyMark | Pass | Pass | 7 slots, final 3 | `genomeBefore=nil`, hatch lineage starts from `form_20` | Pass |

## Notes

The engine currently appends the Day 1 seed to `seedLineageIDs` after hatch, so Day 1 rows can show the same seed twice in the immediate next-Life debug summary. This was classified as harmless retrospective seed metadata, not active-body inheritance, because the next Life starts with `genomeBefore=nil`, age layer 1, and a hatch decision.

No hidden body trait inheritance across Life boundaries was detected.
