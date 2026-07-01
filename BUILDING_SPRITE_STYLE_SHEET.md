# Picod Building Sprite Style Sheet (Rule Version)

Version: 0.1
Scope: `MapView` building-like props and future replacements
Primary goal: keep shrine/pagoda/residential assets in one visual language while preserving role differences

## 1) Visual Direction
- Style target: miniature Japanese garden + symbolic architecture
- Readability target: identify building type in <= 1 second at map zoom
- Consistency target: all buildings share the same pixel grammar (roof/body/shadow rhythm)

## 2) Global Pixel Grammar
- Grid: 8 px per tile (current renderer assumption)
- Anchor: bottom-center (`anchor = (0.5, 1.0)`) unless a specific prop requires otherwise
- Shadow direction: down + slight right bias
- Silhouette priority: roofline first, body second, details third

## 3) Proportion Rules
- Standard vertical split (for most buildings):
- Roof mass: 35% to 45% of sprite height
- Body mass: 45% to 55% of sprite height
- Base/plinth: 8% to 15% of sprite height
- Eave overhang: 1 to 2 px equivalent beyond body edges
- Door opening width ratio: 15% to 25% of body width
- Window module width ratio: 8% to 15% of body width

## 4) Color Hierarchy
Use this hierarchy before introducing new hues.
- Roof dark: deep blue-gray / charcoal family
- Roof mid/light: +1 and +2 value steps from roof dark
- Body dark: warm brown-neutral
- Body mid/light: +1 and +2 value steps from body dark
- Accent red: reserved for ceremonial cues (torii/shrine details)
- Highlight neutral: paper/wood highlight for readability

Hard constraints:
- Do not use pure black or pure white for large regions
- Keep per-building palette to 6 to 9 colors
- New building palettes must share at least 3 color families with existing set

## 5) Outline + Shading Rules
- Outer contour: selective, not full hard outline on every edge
- Roof underside: always darker than roof top plane
- Vertical faces: one-step darker on side opposite light direction
- Contact shadow at base: required for all buildings >= 2x2 tiles
- Detail density: avoid checker-noise; group details into clusters

## 6) Type Differentiation (Same Language, Different Role)
### 6.1 Ceremonial Set (`pagoda`, `shrineSmall`, `torii`)
- Geometry: more vertical and axial
- Rhythm: cleaner centerline, stronger symmetry signal
- Accent usage: red accents allowed and intentional
- Detail placement: frame edges and thresholds, not noisy center fill

### 6.2 Residential Set (`mansion`, `japaneseHouse`, `japaneseSmallHouse`)
- Geometry: lower, wider, more horizontal spread
- Rhythm: slight asymmetry allowed
- Accent usage: limited red, prioritize neutral/warm body tones
- Detail placement: doors, porch edges, lived-in cues near bottom third

### 6.3 Utility Set (`gate`, `dock`, `lowWall`)
- Geometry: simplified silhouettes
- Detail budget: 50% to 70% of residential complexity
- Contrast: one level lower than ceremonial anchors

## 7) Footprint Standards
- 1x1: tiny utility only (wall segments, tiny markers)
- 1x2: slim vertical props (lantern/sign-like)
- 2x2: small house / gate-like minor structure
- 2x3: torii / compact vertical landmark
- 3x3: shrine-class compact landmark
- 4x3: large residence
- 5x4: main hall tier

Rule:
- Avoid introducing new footprints unless gameplay/placement requires it
- If new footprint is introduced, add one ceremonial and one residential reference asset to keep scale language aligned

## 8) Detail Budget by Size
- 2x2: 2 major details max (door + one window cluster)
- 2x3 / 3x3: 3 to 5 major details
- 4x3 / 5x4: 5 to 8 major details

Major detail examples:
- door block
- window band
- roof ornament ridge
- base stair/plinth cue

## 9) Centerline + Threshold Rules
For ceremonial buildings and their related props:
- Preserve a readable centerline from approach side
- Threshold (front 1 tile band) must remain lower-noise than flanks
- Framing details should sit on sides/corners first

## 10) Asset Acceptance Checklist
A building sprite is accepted only if all are true:
- Type readable at map zoom
- Fits the section 3 proportion window
- Uses section 4 color hierarchy
- Passes silhouette check in grayscale
- Matches section 6 differentiation intent
- No single side has accidental visual weight spikes

## 11) Immediate Refactor Order
Apply this order to reduce risk while improving perceived quality quickly:
1. `mansion` (defines residential baseline)
2. `shrineSmall` (defines ceremonial baseline)
3. `pagoda` (defines vertical landmark baseline)

After these 3 are aligned, update `japaneseHouse` and `japaneseSmallHouse` to match the new baseline.

## 12) Notes for Implementation in `MapView`
- Keep sprite dimensions compatible with existing `tileFootprint`
- Prefer editing `PA` pixel arrays first; only change palette if readability demands it
- When changing palette, keep existing semantic slot ordering (roof/body/accent/shadow families)
- Re-render `ContentView` preview after each major sprite revision

---
This is the rule baseline. Next step is to produce concrete sprite revisions against this sheet, starting with `mansion`, `shrineSmall`, and `pagoda`.
