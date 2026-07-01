# Picod Narrative Technical Spec (Phase 1)

Version: 0.1
Status: Active

## Scope
This document defines the first batch narrative architecture for Picod:
- daily interaction persistence
- daily diary generation
- daily story-summary persistence (storage only, no UI wiring)
- storyline documentation structure

## Data Stores
All files are local, on-device, no network dependency.

1. `pico_interactions_db.json`
- source code: `picod/picod/pico_interaction_database.swift`
- stores raw interaction records from `PetEvent`
- purpose: canonical event ledger for future storyline assembly

2. `pico_diary_db.json`
- source code: `picod/picod/pico_diary_database.swift`
- stores interaction objects mapped for diary composition
- purpose: produce concise first-person diary text for current day

3. `pico_story_summaries_db.json`
- source code: `picod/picod/pico_story_summary_database.swift`
- stores daily high-level summaries
- purpose: future lore/memory layer
- note: storage-only for now, intentionally not wired to UI

## Current UI Surface
- Entry: DAYS cell in status bar
- Modal: diary popup (`pico's diary`)
- Source: generated from daily diary DB, not from log list rendering

## Event Ingestion Rules
- Trigger source: `WorldSimulation.latestEvent` -> `ContentView.appendLogEntry(from:)`
- Persist to interaction DB and diary DB on interaction events
- Ignore tap-only events (`.tappedByUser`) for raw interaction DB
- Dedupe near-identical events by small time window in DB layer

## Narrative Constraints
- first-person tone
- concise output for a single popup page + half
- no repetitive scene beats
- no direct system exposition in diary body

## Stability Constraints
- all DB writes are atomic file writes
- in-memory cap keeps arrays bounded
- missing/corrupt files fallback to empty state
- no dependency on network or AI service

## Extension Points (Not yet wired)
1. Storyline progression resolver
- input: daily interactions + cycle/day index + weather/time
- output: active storyline beats and hidden anomalies

2. Epoch memory exporter
- writes end-of-cycle summaries into `pico_story_summaries_db.json`

3. Lore unlock policy
- maps summary records to post-cycle memory UI

## First Batch Storyline IDs (doc level)
- night_lamplighter
- lost_backpacker
- umbrella_woman
- torii_between_light
- door_knocker
- mirror_miko
