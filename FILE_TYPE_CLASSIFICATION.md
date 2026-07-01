# Picod File Type Classification

## Runtime Gameplay / Simulation
- `picod/movement_system.swift` - movement, ambient actors, interactions, event emission
- `picod/full_test_map.swift` - procedural map generation and structural passes
- `picod/world_generation_context.swift` - generation input context and profile
- `picod/location_traits.swift` - location-driven traits/archetype shaping

## Narrative Data Layer
- `picod/pico_interaction_database.swift` - raw interaction records
- `picod/pico_diary_database.swift` - first-person daily diary composer
- `picod/pico_story_summary_database.swift` - cycle-level summary storage
- `picod/narrative_character_database.swift` - character profiles + dialogue pools (prepared interface)

## Presentation / UI
- `picod/ContentView.swift` - app entry UI composition and overlays
- `picod/MapView.swift` - map and actor rendering
- `picod/DashboardView.swift` - dashboard state blocks
- `picod/PetView.swift` - companion rendering
- `picod/SettingsView.swift` - settings panel

## Domain Models
- `picod/pet_state.swift` - pet runtime state
- `picod/pet_response.swift` - response generation
- `picod/animal.swift` - actor kinds and animal models
- `picod/prop.swift`, `picod/landform.swift`, `picod/structure.swift`, `picod/flora.swift`, `picod/creature.swift`

## Vision / Camera Input
- `picod/camera/*`
- `picod/image_processing/*`
- `picod/models/CaptureResult.swift`

## Narrative Specs & Docs
- `WORLDVIEW.md`
- `TECHNICAL_NARRATIVE_SPEC.md`
- `STORYLINES_FIRST_BATCH.md`
- `storylines/` (all storyline files)
