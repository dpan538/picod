# Control Mode Technical Spec

## Overview
Control Mode converts the bottom operation area (from below LOG region to screen bottom) into an interactive controller panel. The map area remains unchanged; only the bottom panel switches UI and behavior.

## Enter / Exit
### Enter
- Gesture: swipe right -> left on bottom operation area
- Thresholds:
  - `minimumDistance: 40pt`
  - `velocity > 300pt/s`
- Effect:
  - bottom operation area switches to control panel
  - map/canvas region remains unchanged

### Exit
- Gesture: swipe left -> right on control panel area
- Same thresholds as enter
- Effect:
  - control panel collapses
  - original operation area is restored (including `PAT PICO` button)

## Control Panel Layout
### Left: Virtual Joystick
- Base:
  - fixed circle
  - color: `Color.picod_ink`
  - opacity: `0.15`
- Knob:
  - small circle
  - color: `Color.picod_ink`
  - opacity: `0.6`
- Interaction:
  - press and drag to move knob
  - max knob displacement = base radius * 0.8
  - release -> knob springs back to center

### Right: Two Action Buttons (Vertical)
- Top: `TALK`
- Bottom: `PICK`
- Style: same visual language as `PAT PICO`
  - `picod_ink` background
  - paper-colored text
- Size: approximately `48x48pt` square (smaller than `PAT PICO`)

## Movement Rules
### Map Mode (default)
- Joystick resolves to 4-direction only (`up/down/left/right`)
- Direction resolution:
  - if `|dx| > |dy|` -> left/right
  - if `|dy| > |dx|` -> up/down
- Diagonal input is normalized to nearest 4-direction
- Pico moves by tile (1 step each input tick)

### Scene Mode (building/shrine/forest etc.)
- Joystick supports omni-direction movement (8-direction or continuous)
- Pico moves freely inside scene
- Movement clamped to scene canvas bounds

## TALK Action
- Tap `TALK`:
  - trigger environment reaction generation
  - render chat bubble above Pico
- Bubble style:
  - rectangle + small bottom triangle pointing to Pico
  - background: `Color.picod_paper2`
  - border: `Color.picod_ink`, `1px`
  - font: `PicodFont.monoSM`
  - content source: `PetResponseGenerator`
- Timing:
  - visible for 2-3s
  - fade out animation: opacity `0.3s`
- Rendering layer:
  - above map canvas
  - follows Pico position
  - does not block core map elements

## PICK Action
- Tap `PICK`:
  - detect collectible props within 1-2 tiles around Pico
- Collectible prop types:
  - `flower`, `stone`, `mushroom`, `reed`, etc.

### If target exists
- play pickup animation:
  - prop disappears
  - small particle effect
- append one pickup event to log area
- append daily diary phrase (e.g. "today picked up XX")
- remove prop from map data

### If no target
- apply light haptic feedback on PICK button (`UIImpactFeedbackGenerator`)
- no other effect

## Integration Points
- Joystick movement:
  - integrate with existing `movement_system.swift`
  - extend move direction handling with controller input path
- Chat bubble:
  - new `ChatBubbleView`
  - overlay in `MapView` ZStack
  - content from `PetResponseGenerator`
- Pickup event:
  - integrate with existing prop data layer
  - query props near Pico coordinate
  - update `TestMap` prop array after pickup
  - sync pickup text into diary database
- Control mode state:
  - add `@State var isControlMode: Bool`
  - managed in `ContentView`
  - passed down to `MapView` and bottom operation area

## Implementation Order
1. Control mode state switching + bottom UI switch
2. Virtual joystick component
3. Joystick -> `movement_system` integration (4-direction in map mode)
4. Chat bubble system (`TALK`)
5. Pickup system (`PICK`)
