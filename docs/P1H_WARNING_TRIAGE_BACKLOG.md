# P1H Warning Triage Backlog

Date: 2026-07-03

## Current Audit State

- Static maps: 5
- Projection scenarios: 10
- Errors: 0
- Warnings: 320
- Actions: 320
- High actions: 55
- Evidence-link audit: clean
- Evidence-copy audit: clean

P1H did not silence warnings, downgrade severities, or treat warning count
reduction as a goal. This backlog keeps the warning pressure visible.

## High Action Classification

| Classification | Meaning |
| --- | --- |
| Must fix before production projection | Blocks making projection rendering a normal path. |
| Should fix before external alpha | Does not block P1I, but affects first external readability. |
| Can defer as polish | Important art cleanup, but not core loop risk. |
| Validator threshold review | Needs screenshot comparison before changing validator behavior. |
| Intentional artistic exception | Allowed only with explicit product/art justification. |

## Top 10 Issues

| # | Issue Summary | Affected Map / Scenario | Category | Triage | User Impact | Fix Recommendation | Blocks P1I |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Pico spawn occlusion risk around `x10 y22`. | `forestShrine`, shared by `freshDay1Empty`, `day1WarmIndoorCapture`, `day7MirrorClosure`, `completedLifeAlbum`, `completedCycleRecord`, `lowParticipationLife`, `unlockedEraMemory` | visual occlusion risk | Must fix before production projection | Pico can feel hidden or less readable at the ritual center. | Move canopy/props away from spawn sightline or adjust spawn-adjacent visual priority. | No, this is prime P1I work. |
| 2 | Common route occlusion near `x17 y21` and `x18 y25`. | `forestShrine` scenarios | route readability polish | Must fix before production projection | The main route can read as crowded even when not blocked. | Open the route band while preserving shrine density. | No. |
| 3 | Multiple spawn occlusion risks near `x4 y24`, `x5 y21`, `x8 y22`. | `wetlandLantern`, `day4RainyUmbrellaTrace` | visual occlusion risk | Must fix before production projection | Rain trace may compete with Pico readability. | Reduce lower-left canopy/prop pressure and protect the wetland spawn pocket. | No. |
| 4 | Route occlusion near `x4 y24` and `x10 y24`. | `wetlandLantern`, `day4RainyUmbrellaTrace` | route readability polish | Must fix before production projection | Umbrella/water trace may feel like clutter rather than a placed story echo. | Keep wetland mood but widen the route silhouette. | No. |
| 5 | Repeated route occlusion near `x12 y24`, `x8 y20`, `x6 y21`. | `nightGrove`, `day5NightLamplighterTrace` | route readability polish | Must fix before production projection | Lamplighter echo can look like an extra prop in an already dense night route. | Thin the route edge and use lamps as rhythm, not blockers. | No. |
| 6 | Spawn/route occlusion around `x7 y21`, `x6 y23`, `x12 y17`. | `villageMarket` | visual occlusion risk | Should fix before external alpha | Market map may feel busy in repeated play. | Rebalance market props around route bands. | No. |
| 7 | Spawn/route occlusion around `x10 y22`, `x12 y19`. | `aprilDense` | visual occlusion risk | Should fix before external alpha | Dense spring map risks hiding Pico. | Pull dense foliage outward or lower its visual priority. | No. |
| 8 | Perimeter forest sparse warnings. | `wetlandLantern`, `villageMarket`, `nightGrove` | density imbalance | Should fix before external alpha | Some map edges can feel unfinished compared with the intended richer world. | Add density only outside protected Pico/route bands. | No. |
| 9 | Disconnected structures and missing approach tiles. | `forestShrine`, `nightGrove`, `aprilDense` | building/path connection | Should fix before external alpha | Buildings can feel decorative rather than belonging to the map. | Add or clarify approach tiles for existing structures. | No. |
| 10 | Wetland projection habitat warnings. | `day4RainyUmbrellaTrace` | habitat mismatch / projection placement refinement | Should fix before production projection | Animals/visitors can feel placed by rules rather than living in the wetland. | Tune habitat filters for water-edge traces and wetland visitors. | No. |

## Classification Totals

Approximate P1H classification of remaining high actions:

- Must fix before production projection: route/spawn occlusion in `forestShrine`, `wetlandLantern`, and `nightGrove`.
- Should fix before external alpha: `villageMarket`, `aprilDense`, approach tiles, edge density, and wetland habitat placement.
- Can defer as polish: minor terrain mismatch and non-critical decorative grounding.
- Validator threshold review: canopy versus hard occlusion thresholds after screenshot comparison.
- Intentional artistic exception: none accepted during P1H.

## Warning Categories

Route readability polish:

- Common Pico routes remain readable in validation, but several are visually crowded.

Visual occlusion risk:

- Tall trees and dense props still report near spawn/route bands.

Density imbalance:

- Some perimeter forest edges are sparse while route interiors are dense.

Habitat mismatch:

- Wetland/rain projection scenarios need animal and visitor habitat tuning.

Decorative grounding:

- Terrain mismatch warnings remain under non-critical props.

Building/path connection:

- Some structures need clearer approach tiles.

Story trace placement:

- Evidence is valid, but final art placement should wait for route clarity.

Projection placement refinement:

- Current projection is deterministic and valid, but not yet art-final.

Validator threshold review:

- No false-positive blocker was identified. Threshold changes should wait until after P1I screenshots.

Copy/readability concern:

- No P1H copy blocker. Minor polish suggestions are documented in `P1H_EVIDENCE_COPY_REVIEW.md`.

## P1I Recommendation

P1I should target a small set of warning reductions, not the entire 320-warning backlog:

1. ForestShrine spawn and route occlusion.
2. WetlandLantern rainy-route readability.
3. NightGrove lamplighter route readability.
4. Wetland habitat placement for rainy story traces.
5. Approach tiles only where they improve map belonging.

P1I is safe to start because errors are already 0 and evidence integrity is clean.
