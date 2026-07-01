# Storylines Second Batch

This batch introduces horror-leaning folklore and creature lines as staged content assets.

## Data Layer
- Runtime-ready dialogue database: `picod/narrative_character_database.swift`
- Story assets folder: `storylines/characters/`
- Interaction storage remains in: `picod/pico_interaction_database.swift`

## Design Rules
1. Not all characters are deployed simultaneously.
2. Use time windows (dusk/night/dawn/rain/fog) and cycle gates.
3. Prefer low-frequency presence and short narrative beats.
4. Keep diary tone subtle and first-person for Pico.

## Included Character Packs
- Chinese Folklore Line
- Southeast-Asia Folklore Line
- Strange Creature Line
- Dusk / Night / Dawn Line

## Next Integration Step
- Wire selected `NarrativeCharacterKind` entries into runtime spawn scheduler in `movement_system.swift`
- Bind dialogue pulls to interaction events and diary composer
- Keep unused character assets dormant until unlocked by cycle/condition
