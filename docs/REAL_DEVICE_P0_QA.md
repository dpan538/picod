# Picod Real-Device P0 QA Checklist

Use this checklist on a physical iPhone before calling the P0 alpha playable. Keep the device offline-friendly; Picod should not require network access.

## Setup

- Build: Debug or TestFlight/internal build from the current local tree.
- Device: one small iPhone and one larger iPhone if available.
- Before destructive reset tests, confirm whether local Picod memory may be cleared.

## Cases

1. Fresh install
   - Expected: app opens calmly, no raw debug text appears, primary action asks for one photo, Memory Drawer can open without crashing.

2. Camera permission allowed
   - Expected: tapping the primary capture action requests permission, camera opens, capture returns to the main screen.

3. Camera permission denied
   - Expected: denial shows plain copy and does not trap the user; the choose-photo fallback remains available.

4. Photo library path
   - Expected: choose-photo opens the system picker, selected image runs through the same Daily Capture pipeline.

5. One successful capture
   - Expected: Pico changes, a Today Trace appears, a diary/log line appears, today's Current Life slot becomes captured.

6. Same-day duplicate capture or replacement behavior
   - Expected: a second capture for the same local day does not create duplicate DailyLifeRecords; UI says today's photo is already saved.

7. Relaunch after capture
   - Expected: app restores today's capture state, Pico form, Memory Drawer slot, and StoryCard state.

8. Airplane mode / no network
   - Expected: capture, memory, diary fallback, and drawer still work; weather/location gracefully fall back.

9. Location denied
   - Expected: no crash; weather cells and map mood use local fallback context.

10. Location allowed
   - Expected: app may improve local time/weather context, but the Daily Capture loop still behaves the same.

11. Low light photo
   - Expected: low-confidence or dark photo produces a mood-based Today Trace, not an error or raw label dump.

12. Very bright photo
   - Expected: bright palette influences Today's Trace and accent/map mood without replacing the whole Pico form unexpectedly.

13. Photo with no recognizable labels
   - Expected: DailyLifeRecord is still saved; explanation talks about feeling, color, or map mood.

14. Seven-day debug simulation
   - Expected: DEBUG Settings button runs P0 checks and reports passed/failed plus generated DailyLifeRecords, albums, cycles, cards, eras.

15. Memory Drawer after simulation
   - Expected: Current Life shows seven slots, Life Albums appear, Cycle Records appear, Story Cards show evidence fragments.

16. Corrupt JSON fallback
   - Expected: with a deliberately corrupted local store file in a debug/dev setup, app opens with safe empty state and no crash.

17. App foreground after date boundary
   - Expected: lifecycle reconciliation runs when returning active and closes missing Life/Cycle/Era objects idempotently.

18. Reduce Motion enabled
   - Expected: app remains usable; movement/transition-heavy surfaces do not become disorienting.

19. Small iPhone screen
   - Expected: main controls, Today Trace, seven Life slots, and drawer details fit without overlapping text.

20. Larger iPhone screen
   - Expected: map, Pico, drawer, and settings scale without stretched or sparse empty states.

## Pass Notes

- Missed days should read as quiet placeholders, never punishment.
- Story Cards should feel like evidence fragments, never lore pages.
- Era Memory should remain locked or quiet until the 49-day boundary.
- Debug controls must remain DEBUG-only.
