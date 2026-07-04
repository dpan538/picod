# Picod P1K Seven-Cycle Lineage Audit

Date: 2026-07-04

Audit command: `SIMCTL_CHILD_PICOD_RUN_LONGITUDINAL_LOOP_AUDIT=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod`

Summary: `lineage=pass`.

## Expected Rule

Within one Life, Pico evolves by inheritance from Day 1 to Day 7. After Day 7, Pico returns to egg/initial state. Across Life boundaries, world memories, StoryCards, CycleRecords, EraMemory, and subtle world echoes may persist. Active Pico body genome should not silently inherit the previous Life's final body traits unless a deliberate lineage system is documented.

## Seven-Cycle Simulation

| Cycle | Life ID | Day 1 genomeBefore | Previous final form | Day 1 form | Same-value fields vs previous final | Classification | Result |
| --- | --- | --- | --- | ---: | --- | --- | --- |
| 1 | `debug-lineage-cycle-1` | nil | nil | 56 | none | Fresh hatch; no previous final | Pass |
| 2 | `debug-lineage-cycle-2` | nil | 45 | 90 | headTrait, appendageTrait | Fresh hatch; coincidental/default values only | Pass |
| 3 | `debug-lineage-cycle-3` | nil | 47 | 48 | headTrait | Fresh hatch; coincidental/default values only | Pass |
| 4 | `debug-lineage-cycle-4` | nil | 48 | 56 | headTrait | Fresh hatch; coincidental/default values only | Pass |
| 5 | `debug-lineage-cycle-5` | nil | 30 | 20 | headTrait, appendageTrait | Fresh hatch; coincidental/default values only | Pass |
| 6 | `debug-lineage-cycle-6` | nil | 3 | 56 | headTrait, textureTrait | Fresh hatch; coincidental/default values only | Pass |
| 7 | `debug-lineage-cycle-7` | nil | 45 | 90 | headTrait, appendageTrait | Fresh hatch; coincidental/default values only | Pass |

## Carryover Classification

| Field group | Classification |
| --- | --- |
| `baseBody`, `coreColor`, `accentColor`, `eyeTrait`, `renderedFormID` | No active-body carryover detected. |
| `headTrait`, `appendageTrait`, `textureTrait` | Some values match across Life boundaries, but Day 1 always starts with `genomeBefore=nil`; matches are fresh hatch/default coincidences. |
| `anomalyMark`, `memoryScar` | No accidental active-body leakage detected at Life Day 1. |
| `seedLineageIDs` | Harmless retrospective metadata; Day 1 starts from hatch and does not import the previous final body. |
| Cycle/Era records | Intended world/cycle/era echoes only. |

## Result

No accidental active-body leakage was found across the 49-day / seven-cycle simulation. Era-level memory can remain as world echo metadata, but the active Pico body does not continue evolving silently across Life boundaries.
