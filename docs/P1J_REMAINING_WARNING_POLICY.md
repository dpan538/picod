# P1J Remaining Warning Policy

Date: 2026-07-04

## Purpose

P1I cleared high-priority route/spawn actions without hiding validator output.
P1J keeps the remaining warning backlog visible and classifies what blocks
which release path.

Current audit state:

- World audit: `errors 0 / warnings 321 / actions 321 / high 0`
- Static maps: `errors 0 / warnings 95`
- Projection scenarios: `errors 0 / warnings 226`
- Evidence-link audit: clean
- Evidence-copy audit: `failed 0`

## Severity Policy

Warnings must not be silenced or downgraded to improve release optics. A warning
can change severity only when the underlying validator semantics are wrong and
the report documents the visual evidence and reason.

Route/spawn readability regressions must remain high-priority if they return.
No artistic exception is accepted for hiding Pico, blocking the main route, or
showing story/cycle/Era traces without evidence.

## Classification Table

| Warning category | Classification | Reason | Required action |
| --- | --- | --- | --- |
| Any future world audit error | Blocks production projection | Errors mean unsafe path, invalid evidence, invalid placement, or broken projection integrity. | Fix before any gated rollout expansion. |
| Any future high route/spawn action | Blocks production projection | Highs directly threaten Pico readability and route clarity. | Fix before default-on or broader gated testing. |
| Story trace without evidence | Blocks production projection | Breaks the Memory -> World projection contract. | Fix immediately; no exception. |
| Locked EraMemory visible anchor | Blocks production projection | Leaks hidden Era state and breaks boundary restraint. | Fix immediately; no exception. |
| `MapView` reading memory/raw stores directly | Blocks production projection | Breaks the projection boundary and couples UI to canonical stores. | Revert or refactor through projection inputs. |
| Wetland habitat tuning | Blocks external alpha | Rainy story traces may feel rule-placed rather than naturally wetland-bound. | Tune animal/visitor habitat before external users see default projection. |
| Structure approach tiles / disconnected structures | Blocks external alpha | Buildings can look decorative rather than connected to the memory board. | Add or clarify approach tiles where visual belonging improves. |
| Perimeter forest density outside protected routes | Blocks external alpha if visually sparse | Sparse edges can make maps feel unfinished, but densification must not crowd Pico routes. | Add density only after route bands are protected. |
| Projection warning increase after P1I | Blocks default-on production | Projection warnings rose from 211 to 226 and need screenshot comparison. | Review scenario screenshots before changing placement or enabling default. |
| Screenshot review of medium/low clusters | Blocks default-on production | Medium/low warnings may be acceptable or may reveal clutter on device. | Capture and classify before default-on. |
| Decorative terrain grounding | Internal polish unless story-relevant | Minor terrain mismatch does not break the loop unless under story/cycle/Era traces. | Prioritize story-relevant grounding first. |
| Validator threshold review | Validator threshold review | No known false-positive blocker exists; changing thresholds too early risks hiding useful signal. | Review screenshots before threshold edits. |
| Artistic exception | Allowed only with written justification | Some visual overlap may be intentional, but never for Pico/route/evidence safety. | Document map, coordinate, reason, and user impact. |

## Blocks Production Projection

The following must be zero before default-on projection is considered:

- world audit errors
- high actions
- story trace missing evidence
- locked EraMemory leaks
- unknown catalog IDs
- ungrounded projected elements
- projection path obstructions
- `MapView` direct memory/raw store reads
- normal-mode DEBUG/projection badge leaks

Current status after P1J baseline:

- All are zero or absent.
- This supports internal gated testing only, not default-on production.

## Blocks External Alpha

The following can coexist with internal gated testing, but should be resolved or
visually accepted before external alpha:

- wetland habitat tuning
- disconnected structures and missing approach tiles
- perimeter forest sparse warnings
- scenario warning increase after P1I
- medium/low warning clusters without screenshot review
- physical iPhone QA blocker

## Internal Polish

The following can be deferred while the projection path remains gated:

- minor decorative terrain mismatch
- non-story decorative grounding
- DEBUG preview ergonomics
- visual density balancing outside the main route
- LifeAlbum and CycleRecord trace art polish

## Validator Threshold Review

Threshold changes are not part of P1J.

Future threshold changes require:

1. screenshot evidence that the validator is over-reporting a non-risk
2. a written before/after note
3. preserved route/spawn protection
4. unchanged evidence integrity checks
5. world audit errors still at 0

## Artistic Exceptions

No artistic exceptions are approved in P1J.

An exception must never allow:

- Pico to become hard to read
- main route to become visually blocked
- story traces without evidence
- Cycle markers without cycle evidence
- Era echoes before unlock
- raw debug/projection/audit terms in normal copy

## P1K Recommendations

1. Capture scenario screenshots on simulator and physical iPhone when hardware is
   available.
2. Tune wetland habitat placement for rainy/umbrella projection traces.
3. Add approach tiles for structures that should feel inhabited.
4. Review projection warning increase from 211 to 226 by scenario.
5. Keep `PICOD_USE_WORLD_PROJECTION_MAP` off by default.
6. Keep static/default map fallback available.
