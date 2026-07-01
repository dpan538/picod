# Picod Depth Cue Policy

Version: 0.1
Purpose: define minimal, consistent grounding cues for map readability without turning Picod into a 2.5D system.

## Core Principle
Picod map rendering remains top-down symbolic.
Depth cues are allowed only to improve grounding and readability, not to represent full physical height.
Absence of shadow is the default state; shadow must be justified by grounding benefit, not added by habit.

## What Picod Is (and Is Not)
- Is: symbolic top-down miniature scene with mild frontal readability on buildings.
- Is not: isometric, pseudo-3D, or full 2.5D projection.

## Allowed Depth Cues
- Thin bottom contact cue on major buildings.
- Very short contact shadow near object-ground contact area.
- Low-contrast grounding treatment for selected tall anchors.

## Disallowed Depth Cues
- Elevated plinth blocks that visually separate building body from ground plane.
- Long directional cast shadows that imply full 3D height hierarchy.
- Mixed shadow systems per asset (different directions/length models).
- Grounding treatment that introduces a readable side-wall or lifted platform illusion.

## Global Shadow Rules
- Direction: fixed globally (down with slight right bias).
- Length: short only (1 px, occasionally 2 px equivalent at sprite scale).
- Contrast: low to medium-low; must not compete with roof/body contrast.
- Function: grounding only, not height storytelling.
- Grounding cues must remain readable across major terrain families and must not create false second outlines on dirt or moss ground.

## Role-Based Application
- Major buildings (`mansion`, `shrineSmall`, `pagoda`, `japaneseHouse`, `japaneseSmallHouse`):
- May use the strongest grounding treatment in this policy.

- Tall anchors (`torii`, large trees):
- May use short grounding shadow if readability benefits.

- Utility structures (`dock`, `gate`, `lowWall`):
- Use minimal contact cues only.

- Small props and animals:
- Default to shadowless or near-shadowless rendering.

## Ground Contact Priority
When grounding a building, apply in this order:
1. Clear bottom silhouette.
2. Thin base contact cue (bottom trim / stone rhythm).
3. Optional very short contact shadow.
4. Remove any treatment that reads as floating or raised platform.

## Consistency Checks (Before Accepting an Asset)
- Does it still read as top-down symbolic at map zoom?
- Does grounding improve stability without implying heavy height?
- Is shadow direction consistent with global rule?
- Does the cue avoid toy-like floating or sticker-like separation?

## Integration With Style Sheet
This policy complements `BUILDING_SPRITE_STYLE_SHEET.md`.
If conflicts appear, this depth policy controls grounding behavior, while style sheet controls form language and proportions.
