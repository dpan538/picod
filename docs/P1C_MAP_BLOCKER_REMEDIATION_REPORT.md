# Picod P1C Static Map Blocker & Route Readability Remediation Report

Date: 2026-07-03
Branch: `p1-world-richness-integration`
Checkpoint base: `45dffdc P1B world state projection and audit integration`

## Scope

P1C focused on inherited static map blockers that prevented P1 world projection
from being safely renderable later. This pass did not add Pico forms,
storylines, map variants, folklore content, or production `MapView` projection
wiring.

## Baseline Before Remediation

Commands run:

```sh
git status --short --branch
git log -1 --oneline
git diff --stat
git diff --check
git ls-files --deleted
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
env SIMCTL_CHILD_PICOD_RUN_WORLD_RICHNESS_AUDIT=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
```

Baseline result:

- Debug simulator build: succeeded.
- P0 acceptance: `passed=14 failed=0`.
- Static maps: 5.
- Projection scenarios: 10.
- Total errors: 26.
- Total warnings: 366.
- Total actions: 392.
- High actions: 113.
- Static map errors/warnings: 13 / 116.
- Projection scenario errors/warnings: 13 / 250.

The projection-specific integrity checks were already clean:

- unknown catalog IDs: 0.
- missing story evidence/source: 0.
- locked EraMemory echo: 0.
- ungrounded projected elements: 0.

## Error Classification

| Map variant | Scenario | Error ID / message | Severity | Category | Root cause | Fix strategy | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `wetlandLantern` | static map | `pico_spawn_blocked @ x11 y23` | error | Pico spawn invalid | Spawn anchor landed under blocking tree footprint. | Move Pico spawn to an existing readable path tile at `x6 y23`. | Resolved |
| `wetlandLantern` | static map | `pico_no_reachable_tiles @ x11 y23` | error | Main route blocked | Blocked spawn produced no reachable route sample. | Use the new path-aligned spawn at `x6 y23`. | Resolved |
| `wetlandLantern` | static map | water connection failures around bridge, dock, and reed props | error | Water-edge mismatch | Existing water-edge objects implied wet contact, but neighboring terrain was not water-like. | Add small shallow-water contact pockets near the existing wetland objects. | Resolved |
| `wetlandLantern` | `day4RainyUmbrellaTrace` projection | inherited wetland spawn/path/water errors | error | Base map still unsafe | Projection used a base map with static blockers. | Fix base `wetlandLantern` map rather than changing projection logic. | Resolved |
| `nightGrove` | static map | `pico_spawn_blocked @ x12 y24` | error | Pico spawn invalid | Spawn anchor overlapped a blocking round-tree footprint. | Move Pico spawn to existing lantern-path tile at `x8 y23`. | Resolved |
| `nightGrove` | static map | `pico_no_reachable_tiles @ x12 y24` | error | Main route blocked | Blocked spawn prevented route validation. | Use the new path-aligned spawn at `x8 y23`. | Resolved |
| `nightGrove` | `day5NightLamplighterTrace` projection | inherited nightGrove spawn/path errors | error | Base map still unsafe | Projection used a base map with static blockers. | Fix base `nightGrove` map rather than changing projection logic. | Resolved |
| `forestShrine` / `aprilDense` | static and projection scenarios | repeated route/spawn occlusion warnings | high warning | Route visually occluded / tree canopy visual risk | Bottom route band was visually crowded by perimeter trees. | Move several bottom-edge tree anchors outward while preserving the forest rim. | Improved, still backlog |

No validator severity was downgraded, and no audit failure was hidden.

## Map Identity Notes

### wetlandLantern

Desired feel: a wet reed shrine path with lamps, small water crossings, and a
quiet lowland edge.

Blockers found:

- Pico spawned under a blocking tree footprint.
- Several existing wetland props lacked actual water-like contact.

Changes made:

- Moved Pico spawn from `x11 y23` to `x6 y23`, an existing readable path tile.
- Added shallow-water contact pockets near existing bridges, docks, and reeds.

Identity preserved:

- The map remains wetter than the shrine and village variants.
- Existing wetland objects stayed in place; the terrain now supports their
  intended relationship.

### nightGrove

Desired feel: a dark grove with a lantern path and small edge visitors.

Blockers found:

- Pico spawned inside a blocking tree footprint near the bottom route.

Changes made:

- Moved Pico spawn from `x12 y24` to `x8 y23`, an existing path tile inside the
  lantern route.

Identity preserved:

- The dense grove silhouette and lamplighter area remain intact.
- The fix opens Pico readability without flattening the nighttime map.

### forestShrine / aprilDense shared base

Desired feel: a shrine clearing enclosed by a forest rim.

Blockers found:

- Repeated high-priority route readability warnings along the lower travel
  band.

Changes made:

- Shifted several lower-edge tree anchors outward or farther to the perimeter.

Identity preserved:

- The forest rim remains visible.
- The common Pico route has more breathing room without becoming an empty lane.

## Baseline After Remediation

Final world audit result after P1C static map edits:

- Static maps: 5.
- Projection scenarios: 10.
- Total errors: 0.
- Total warnings: 320.
- Total actions: 320.
- High actions: 55.
- Static map errors/warnings: 0 / 109.
- Projection scenario errors/warnings: 0 / 211.
- `wetlandLantern`: errors 0 / warnings 24.
- `nightGrove`: errors 0 / warnings 21.

Projection integrity remained clean:

- unknown catalog IDs: 0.
- missing story evidence/source: 0.
- locked EraMemory echo: 0.
- ungrounded projected elements: 0.
- path obstruction count: 0 in projection scenarios.
- story trace evidence remained attached.

## Remaining Warnings

Warnings are still real backlog and were not suppressed:

- Pico route and spawn visual occlusion risks remain in dense maps.
- Perimeter forest sparse warnings remain for some review variants.
- Several structures still need clearer approach tiles.
- Some decorative props still report terrain mismatch.
- `day4RainyUmbrellaTrace` still reports invalid habitat warnings for projected
  wetland animals; these are warnings, not blockers, and should be reviewed in
  the P1D projection preview pass.

Top remaining high-action themes:

1. Reduce `forestShrine` Pico spawn occlusion around `x10 y22`.
2. Reduce `forestShrine` route occlusion around `x17 y21` and `x18 y25`.
3. Reduce `aprilDense` route occlusion around `x10 y22` and `x12 y19`.
4. Reduce `wetlandLantern` spawn readability risks near `x4 y24`, `x5 y21`,
   and `x8 y22`.
5. Reduce `nightGrove` route readability risks near `x12 y24`, `x8 y20`, and
   `x6 y21`.

## Validation Result

Current validation:

- `git diff --check`: passed.
- Debug simulator build: succeeded.
- P0 acceptance harness: `passed=14 failed=0`.
- World richness audit: `errors 0 / warnings 320 / actions 320 / high 55`.

P1D MapView projection preview is safe to start behind a debug or preview gate:

- Base-map hard blockers are cleared.
- Projection-specific integrity remains clean.
- Production `MapView` is still not coupled directly to memory stores.
- Remaining warnings should stay visible in audit output and should not block a
  debug-only projection preview.

## Notes

- No reset, rebase, discard, or force operation was performed.
- No code path was added that exposes audit jargon to normal users.
- P0 Memory remains canonical; P1 world state remains derived.
