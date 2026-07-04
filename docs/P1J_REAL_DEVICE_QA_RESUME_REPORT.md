# P1J Real-Device QA Resume Report

Date: 2026-07-04
Branch: `p1-world-richness-integration`
Candidate commit: `b55f521 P1J production projection go-no-go review`
Decision under test: `CONDITIONAL GO` for limited internal gated projection testing; default/external projection remains `NO-GO`.

## Baseline

| Check | Command | Result |
| --- | --- | --- |
| Git status | `git status --short --branch` | Clean: `## p1-world-richness-integration` |
| HEAD | `git log -1 --oneline` | `b55f521 P1J production projection go-no-go review` |
| Diff check | `git diff --check` | Passed |
| Deleted files | `git ls-files --deleted` | None |
| Debug simulator build | `xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build` | Passed: `** BUILD SUCCEEDED **` |
| P0 acceptance | `SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod` | Passed: `passed=14 failed=0`; generated `daily=49 albums=7 cycles=7 cards=3 eras=1` |
| World audit | `SIMCTL_CHILD_PICOD_RUN_WORLD_RICHNESS_AUDIT=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod` | Passed: `errors 0 / warnings 321 / actions 321 / high 0` |
| Evidence-copy audit | Same world audit run | Passed: `checked 10 / failed 0` |
| Evidence-link audit | Same world audit run | Passed: `anchors 35 / unresolved 0 / duplicate anchors 0 / locked leaks 0 / missing evidence 0` |

## Physical iPhone Availability

| Field | Result |
| --- | --- |
| CoreDevice status | Resolved: device is available through CoreDevice/Xcode |
| Device name | `Dai Pan iPhone` |
| Device model | `iPhone 14` (`iPhone14,7`) |
| OS version | `26.0.1` (`23A355`) |
| UDID | `00008110-001438E9027A201E` |
| CoreDevice ID | `CDAA7116-223B-5BBE-A62A-20E54AFEF87D` |
| Connection | Wired, paired, tunnel connected |
| Developer Mode | Enabled |
| DDI services | Available |
| Xcode destination | Available as `{ platform:iOS, arch:arm64, id:00008110-001438E9027A201E, name:Dai Pan iPhone }` |
| Note | `xcrun xctrace list devices` still listed the device as offline, but CoreDevice and `xcodebuild -showdestinations` reported it available. QA used CoreDevice/Xcode availability. |

QA-ENV-001 is resolved for build/install/launch work. Full hands-on camera and permission QA still requires physical interaction with the unlocked iPhone.

## Device Build, Install, And Launch

| Check | Command | Result |
| --- | --- | --- |
| Device Debug build | `xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -destination id=00008110-001438E9027A201E -derivedDataPath /tmp/picod_device_build build` | Passed: `** BUILD SUCCEEDED **` |
| Signing | Device build output | Apple Development signing succeeded with `iOS Team Provisioning Profile: dai.pan.picod` |
| Install | `xcrun devicectl device install app --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D /tmp/picod_device_build/Build/Products/Debug-iphoneos/picod.app` | Passed: app installed with bundle ID `dai.pan.picod` |
| Install type | Device already had `picod` installed before this run | Upgrade/reinstall install. Fresh uninstall was not performed to avoid destructive device data loss without explicit approval. |
| Normal launch | `xcrun devicectl device process launch --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D dai.pan.picod` | Passed: app launch returned success |
| Gated projection launch | `xcrun devicectl device process launch --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D --terminate-existing --environment-variables '{"PICOD_USE_WORLD_PROJECTION_MAP":"1"}' dai.pan.picod` | Passed: app launch returned success |
| P1D preview launch | `xcrun devicectl device process launch --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D --terminate-existing --environment-variables '{"PICOD_SHOW_WORLD_PROJECTION_PREVIEW":"1"}' dai.pan.picod` | Passed: app launch returned success |
| Combined gated launch | `xcrun devicectl device process launch --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D --terminate-existing --environment-variables '{"PICOD_SHOW_WORLD_PROJECTION_PREVIEW":"1","PICOD_USE_WORLD_PROJECTION_MAP":"1"}' dai.pan.picod` | Passed: app launch returned success |

CoreDevice emitted a repeated provisioning parameter warning: `No provider was found.` The warning did not block build, install, or launch.

## Normal Mode Hardware QA

| Scenario | Status | Notes |
| --- | --- | --- |
| Launch | Passed | Normal mode launch returned success on physical iPhone. |
| Fresh install state | Pending manual/destructive setup | Not executed because uninstalling would erase existing app data on the device. |
| Camera permission allowed | Pending manual | Requires tapping permission UI and taking a real photo on device. |
| Camera permission denied | Pending manual/destructive setup | Requires resetting app permission state or reinstalling/resetting privacy permissions. |
| Photo picker fallback | Pending manual | Requires hands-on UI interaction. |
| One successful capture | Pending manual | Requires camera/photo picker interaction. |
| Today's Trace after capture | Pending manual | Depends on successful capture. |
| Memory Drawer after capture | Pending manual | Depends on successful capture. |
| Relaunch after capture | Pending manual | Depends on successful capture. |
| Location allowed | Pending manual | Requires permission prompt interaction. |
| Location denied | Pending manual/destructive setup | Requires permission reset or settings changes. |
| Airplane mode / no network | Pending manual | Requires hardware settings change. |
| Low-light photo | Pending manual | Requires real-world capture setup. |
| Bright photo | Pending manual | Requires real-world capture setup. |
| No-recognizable-label photo | Pending manual | Requires real-world capture setup. |
| Reduce Motion | Pending manual | Requires device accessibility setting change. |
| Small/large screen layout | Partial | Current physical device covers iPhone 14 class only; no second screen size was available in this run. |

## Internal Gated Projection Hardware QA

| Scenario | Status | Notes |
| --- | --- | --- |
| App launches with `PICOD_USE_WORLD_PROJECTION_MAP=1` | Passed | Device launch returned success. |
| Current-memory projection renders without crash | Partial pass | Launch succeeded. Visual confirmation still requires observing the device screen. |
| DEBUG badge appears only in gated/internal mode | Pending visual confirmation | Requires hands-on screen inspection. |
| Pico remains readable | Pending visual confirmation | Requires screen inspection. |
| Map remains calm | Pending visual confirmation | Requires screen inspection. |
| Projection fallback works if invalid | Not executed | No invalid projection was injected in this hardware run. Simulator/world audit fallback remains green. |
| Memory Drawer evidence copy remains non-technical | Pending manual | Requires UI navigation. |
| No raw IDs/debug terms in normal surfaces | Pending manual | Requires UI navigation. |
| Performance during basic navigation | Pending manual | Requires interactive navigation. |

## Screenshot Audit

No automated physical-device screenshot command was available through `devicectl device`. Screenshots remain manual capture items.

| Screenshot | Status |
| --- | --- |
| Normal fresh state | Pending manual |
| Post-capture Today's Trace | Pending manual |
| Memory Drawer Current Life | Pending manual |
| StoryCard detail with world trace | Pending manual |
| LifeAlbum detail | Pending manual |
| CycleRecord detail | Pending manual |
| Locked EraMemory | Pending manual |
| Gated projection map | Pending manual |
| P1D projection preview, DEBUG only | Pending manual |

## Bug Triage

| ID | Severity | Area | Repro steps | Expected | Actual | Screenshot | Fix recommendation | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| QA-ENV-001 | Blocker | Hardware availability | Connect trusted iPhone and query CoreDevice/Xcode destinations | Physical iPhone is available for build/install/launch | Resolved: CoreDevice and Xcode destination available; device build/install/launch passed | Not captured | None | Resolved |
| QA-HW-001 | Low | Tooling noise | Run `devicectl` commands | No warning noise | CoreDevice prints `No provider was found` provisioning parameter warning, but commands succeed | Not captured | Document only unless it begins blocking install/launch | Deferred |
| QA-MANUAL-001 | Medium | Manual coverage | Attempt camera/photo/permission/screenshot checklist through CLI only | Full hardware checklist can be completed | CLI can build/install/launch, but cannot complete camera/photo permission flows or physical screenshots without hands-on interaction | Not captured | Continue with tester-driven manual pass on the unlocked iPhone | Deferred |

No Blocker or High product defect was found in the build/install/launch portion of hardware QA.

## Decision

Current decision: `PARTIAL HARDWARE PASS / MANUAL QA STILL REQUIRED`.

The physical iPhone blocker is resolved for build, install, and launch. The current candidate remains a `CONDITIONAL GO` for limited internal gated projection testing, with projection still off by default and gated through internal flags.

The candidate is not ready for external handoff from this report alone because the camera/photo path, permission-denied path, post-capture Today's Trace, Memory Drawer capture reflection, persistence after capture, and physical screenshots were not yet manually executed on the device.

## Follow-Up Checklist

1. Run the app normally on the unlocked iPhone.
2. Execute one real capture through camera permission allowed.
3. Verify Today's Trace and Memory Drawer update after capture.
4. Relaunch and verify memory persistence.
5. Reset permissions or use Settings to test denied camera/location paths.
6. Launch with `PICOD_USE_WORLD_PROJECTION_MAP=1` and visually inspect map readability.
7. Capture manual screenshots for the screenshot audit table.
8. Record any Blocker/High product issues and fix only those before retesting.
