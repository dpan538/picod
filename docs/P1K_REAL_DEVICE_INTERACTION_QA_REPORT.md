# Picod P1K Real-Device Interaction QA Report

Date: 2026-07-04

Branch: `p1-world-richness-integration`

## Hardware Status

P1K did not complete new hands-on physical iPhone interaction testing. The last hardware state remains the P1J partial resume result:

- Device: iPhone 14
- iOS: 26.0.1
- Build/install/launch: passed in P1J
- Normal launch, gated projection launch, P1D preview launch, and combined launch: passed in P1J

No uninstall, erase, reset, rebase, discard, or force push occurred during P1K.

## Completed In P1K

| Item | Result |
| --- | --- |
| Simulator normal launch screenshot | Passed: `/tmp/picod-p1k-normal.png` |
| Main screen single PHOTO button | Passed in simulator screenshot |
| Redundant `TODAY'S PHOTO` / `CHOOSE PHOTO` controls removed | Passed in simulator screenshot |
| Top status does not collide with gear on iPhone-size simulator screenshot | Passed |
| Empty pre-photo map shows no active Pico | Passed in screenshot and deterministic audit |
| Projection-gated pre-photo no-Pico rule | Passed deterministic audit |
| Debug build | Passed |
| P0 acceptance | Passed: `passed=14 failed=0` |
| World/evidence audit | Passed core gates |
| Longitudinal loop audit | Passed |

## Still Needed On Physical iPhone

| Test | Status |
| --- | --- |
| Tap the new single PHOTO button | Not completed in P1K |
| Take photo | Not completed in P1K |
| Choose from library | Not completed in P1K |
| Cancel action sheet | Not completed in P1K |
| Deny camera permission | Not completed in P1K |
| Allow camera permission | Not completed in P1K |
| Deny location permission | Not completed in P1K |
| Allow location permission | Not completed in P1K |
| Verify Today's Trace after capture | Not completed in P1K |
| Verify Memory Drawer after capture | Not completed in P1K |
| Relaunch after capture | Not completed in P1K |
| Verify no active Pico before next daily capture | Not completed in P1K |
| Gated projection mode launch after capture | Not completed in P1K |
| Normal mode remains projection-free after capture | Not completed in P1K |
| Screenshot after capture | Not completed in P1K |
| Screenshot camera UI | Not completed in P1K |
| Screenshot Memory Drawer day detail | Not completed in P1K |

## Recommendation

Run P1L as a focused physical-device interaction pass using the new P1K build. The simulator/debug validation is clean, but camera, photo-library, permission, and Memory Drawer touch flows still need hands-on iPhone evidence.
