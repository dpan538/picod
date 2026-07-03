# Picod P0 Real-Device QA Execution Report

## Summary

This QA pass ran on branch `p0-real-device-qa` from the productized P0 checkpoint. Simulator build, generic iOS device build, physical iPhone build/sign/install, and the P0 acceptance harness are green.

Physical iPhone execution resumed after the hardware availability unblock. `Dai Pan iPhone` is now visible to Xcode and `devicectl`, and the second-round build test confirms the app builds, installs, and launches successfully on the physical iPhone.

After hands-on screenshot review, several hardware-facing product issues were identified and hardened locally:

- initial daily capture now offers camera or photo-library choice instead of camera-only;
- the home Memory Drawer handle is less visually dominant over the map;
- the Memory Drawer current Pico now uses the same canonical current form as the home screen;
- DEBUG preview defaults no longer force real runtime into night mode;
- capture now preserves original photo data where possible and stores parsed EXIF/GPS/environment snapshots instead of relying only on a rendered `UIImage`;
- unavailable weather now remains unknown instead of being presented as cloudy.
- ambient map animation remains alive even when Reduce Motion is enabled, so water glints, wind leaves, rain, mist, and cloud shadows are no longer frozen by that preference.
- existing map animals now wander subtly, show quiet signal bubbles, and can produce calm interaction log events when Pico notices them.
- map sprites are flat by default again; Pico explicitly keeps its shadow while props and animals no longer read as floating objects.

## Baseline Verification

| Item | Result |
| --- | --- |
| Branch | `p0-real-device-qa` |
| Commit | `799fb8b90ef93400ebe7964b0312ccef9bff4e37` |
| Working tree clean before QA | Yes |
| `xcodebuild -list -project picod.xcodeproj` | Succeeded; scheme `picod` confirmed |
| Simulator Debug build | Succeeded |
| P0 acceptance harness | Passed: `passed=14 failed=0` |
| Acceptance generated counts | 49 DailyLifeRecords, 7 LifeAlbums, 7 CycleRecords, 3 StoryCards, 1 EraMemory |
| Generic iOS device build | Succeeded with `-destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO` |
| Physical iPhone build | Succeeded with `-destination id=00008110-001438E9027A201E -allowProvisioningUpdates` |
| Physical iPhone install | Succeeded via `devicectl` |
| Physical iPhone launch | Succeeded via `devicectl` in the second-round build test |

Commands run:

```sh
git status --short --branch
git log -1 --oneline
xcodebuild -list -project picod.xcodeproj
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -destination generic/platform=iOS -derivedDataPath /tmp/picod_device_build CODE_SIGNING_ALLOWED=NO build
xcrun devicectl list devices
xcodebuild -showdestinations -project picod.xcodeproj -scheme picod
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -destination id=00008110-001438E9027A201E -derivedDataPath /tmp/picod_real_device_build build
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -destination id=00008110-001438E9027A201E -derivedDataPath /tmp/picod_real_device_build -allowProvisioningUpdates build
xcrun devicectl device install app --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D /tmp/picod_real_device_build/Build/Products/Debug-iphoneos/picod.app
# First launch attempt failed before the Apple Development profile was trusted on device.
xcrun devicectl device process launch --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D dai.pan.picod
# Retry after profile trust succeeded.
xcrun devicectl device process launch --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D dai.pan.picod
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -destination id=00008110-001438E9027A201E -derivedDataPath /tmp/picod_real_device_build -allowProvisioningUpdates build
xcrun devicectl device install app --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D /tmp/picod_real_device_build/Build/Products/Debug-iphoneos/picod.app
# Latest retry blocked because the iPhone was locked.
xcrun devicectl device process launch --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D dai.pan.picod
# Second-round build test after unlocking the iPhone.
xcodebuild -list -project picod.xcodeproj
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
xcrun devicectl list devices
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -destination id=00008110-001438E9027A201E -derivedDataPath /tmp/picod_real_device_build -allowProvisioningUpdates build
xcrun devicectl device install app --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D /tmp/picod_real_device_build/Build/Products/Debug-iphoneos/picod.app
xcrun devicectl device process launch --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D dai.pan.picod
# Map ambient animation regression fix.
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -destination id=00008110-001438E9027A201E -derivedDataPath /tmp/picod_real_device_build -allowProvisioningUpdates build
xcrun devicectl device install app --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D /tmp/picod_real_device_build/Build/Products/Debug-iphoneos/picod.app
xcrun devicectl device process launch --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D dai.pan.picod
# Animal interaction, signal bubble, and flat shadow fix.
git diff --check
xcodebuild -list -project picod.xcodeproj
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/picod_build CODE_SIGNING_ALLOWED=NO build
xcrun simctl install B862520B-F900-4497-914A-DE36E90DFF3B /tmp/picod_build/Build/Products/Debug-iphonesimulator/picod.app
env SIMCTL_CHILD_PICOD_RUN_P0_ACCEPTANCE=1 xcrun simctl launch --terminate-running-process --console B862520B-F900-4497-914A-DE36E90DFF3B dai.pan.picod
xcodebuild -project picod.xcodeproj -scheme picod -configuration Debug -destination id=00008110-001438E9027A201E -derivedDataPath /tmp/picod_real_device_build -allowProvisioningUpdates build
xcrun devicectl device install app --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D /tmp/picod_real_device_build/Build/Products/Debug-iphoneos/picod.app
xcrun devicectl device process launch --device CDAA7116-223B-5BBE-A62A-20E54AFEF87D dai.pan.picod
```

## Real iPhone Build And Run

| Item | Result |
| --- | --- |
| Physical install/run | Second-round install and command-line launch succeeded |
| Device model | Dai Pan iPhone, iPhone 14 (`iPhone14,7`) |
| iOS version | 26.0.1 |
| Build configuration | Debug |
| Bundle ID | `dai.pan.picod` |
| Install type | Development install via `devicectl`; not a verified fresh install |
| Camera permission prompt | Not tested on hardware |
| Photo library permission prompt | Not tested on hardware; app uses system `PhotosPicker` and now includes a photo-library usage string for original asset metadata access |
| Location permission prompt | Not tested on hardware |
| Normal-use debug visibility | Not tested visually on hardware |
| Acceptance data pollution on fresh install | Not tested on hardware; simulator acceptance data is only generated through explicit DEBUG env route |

Detected physical-device records:

| Device | Reported OS | State |
| --- | --- | --- |
| Dai Pan iPhone | iOS 26.0.1 | Available/paired in `devicectl`; available Xcode destination; app installed |
| Xiaomi 15 Ultra | iOS 27.0 | Offline / unavailable |
| Sliding/iphone air device | iOS 26.3.1 | Offline / unavailable |

Static permission strings observed in project settings:

- `NSCameraUsageDescription`: present.
- `NSLocationWhenInUseUsageDescription`: present.
- `NSPhotoLibraryUsageDescription`: present after this hardening pass.

## Real Metadata, Location, And Climate Findings

This section is intentionally strict: fallback UI is not counted as real data.

### Photo EXIF / GPS

Current local code can preserve and parse real photo metadata:

- Camera capture now keeps `AVCapturePhoto.fileDataRepresentation()` instead of only retaining a `UIImage`.
- Photo-library import now first tries `PHImageManager.requestImageDataAndOrientation(... version: .original ...)` for the selected `PHAsset`, with `PhotosPickerItem.loadTransferable(Data.self)` only as fallback.
- `PhotoCaptureMetadata.fromImageData` uses ImageIO (`CGImageSourceCopyPropertiesAtIndex`) to parse EXIF, TIFF, pixel size, orientation, camera make/model, lens, exposure, f-number, ISO, focal length, original date/time, and GPS if present in the image data.
- Photo-library imports are also enriched from `PHAsset` creation date and `PHAsset.location` when the selected asset exposes them.
- `PhotoTraitSnapshot` now persists `captureMetadata`, so later QA can inspect whether a real capture had `hasEXIF` / `hasGPS`.

Remaining empirical check: a real on-device capture or library import still needs to be performed while the iPhone is unlocked, then the app container should be inspected to confirm the saved `PhotoTraitSnapshot.captureMetadata` values for that specific photo.

Important limitation: photos taken through Picod's custom camera should be expected to include camera EXIF, but iOS does not automatically inject GPS into the photo EXIF. Picod stores physical location separately through the capture environment snapshot.

### Physical Location

Current local code can read physical location when the user grants location permission:

- `PicodWorldInputService` uses `CLLocationManager.requestLocation()` with When-In-Use authorization.
- Resolved latitude/longitude are quantized into `PicodStableWorldInput`.
- Reverse geocoding provides locality/region/timezone where available.
- `PhotoCaptureEnvironmentSnapshot` now persists timezone, local hour, time phase, quantized location, weather condition, temperature, humidity, precipitation chance, and whether a resolved location was used.

Remaining empirical check: location permission must be allowed on the unlocked iPhone and a capture must be made; then the stored `captureEnvironment.usedResolvedLocation` and quantized coordinates should be inspected.

### Real Weather / Climate

Current local code can request real climate data through WeatherKit when the app is signed with a provisioning profile that includes the WeatherKit capability:

- `WeatherKitPicodProvider` requests `WeatherService.shared.weather(for:)` at the resolved device coordinate.
- It stores real temperature, humidity, current/hourly condition, and hourly precipitation chance.
- Conditions now treat high precipitation chance (`>= 0.5`) as rain and no longer label unknown weather as cloudy.

Current blocker: the available Apple Personal Development Team cannot provision the WeatherKit capability. A test build with `com.apple.developer.weatherkit` failed with:

```text
Personal development teams, including "Jarl Ey", do not support the WeatherKit capability.
Provisioning profile "iOS Team Provisioning Profile: dai.pan.picod" doesn't include the WeatherKit capability.
```

Therefore, real rain / humidity / precipitation cannot be honestly marked verified on this signing setup yet. The app should display unknown/fallback weather rather than pretending cloudy weather is real. To verify actual local rain and precipitation probability, Picod needs either a paid Apple Developer team with WeatherKit enabled for `dai.pan.picod`, or an explicit product decision to use another weather provider, which would be a new network dependency and is outside this P0 scope.

## Manual QA Checklist

| # | Scenario | Status | Notes | Screenshot |
| --- | --- | --- | --- | --- |
| 1 | Fresh install | Partial | Device install and launch succeeded; install was not confirmed as a clean uninstall/reinstall. | N/A |
| 2 | Camera permission allowed | Not tested | Requires hands-on camera permission flow on the iPhone. | N/A |
| 3 | Camera permission denied | Not tested | Requires hands-on permission reset/denial on the iPhone. | N/A |
| 4 | Photo library fallback | Not tested | Requires hands-on system picker flow on the iPhone. | N/A |
| 5 | One successful capture | Not tested | Requires hands-on camera or picker capture on the iPhone. | N/A |
| 6 | Same-day duplicate capture / replacement behavior | Partial | Idempotence covered by acceptance harness; hardware UX not tested. | N/A |
| 7 | Relaunch after capture | Partial | Store reload covered by acceptance harness; hardware relaunch not tested. | N/A |
| 8 | Airplane mode / no network | Not tested | Requires hands-on device-settings scenario. | N/A |
| 9 | Location denied | Not tested | Requires hands-on location permission flow on the iPhone. | N/A |
| 10 | Location allowed | Not tested | Requires hands-on location permission flow on the iPhone. | N/A |
| 11 | Low light photo | Not tested | Requires hands-on image capture or picker selection. | N/A |
| 12 | Very bright photo | Not tested | Requires hands-on image capture or picker selection. | N/A |
| 13 | Photo with no recognizable labels | Not tested | Requires hands-on image capture or picker selection. | N/A |
| 14 | Seven-day debug simulation | Pass | Simulator acceptance route passed `14/14`; DEBUG Settings route not manually tapped on hardware. | N/A |
| 15 | Memory Drawer after simulation | Partial | Memory objects generated by acceptance harness; visual hardware audit not run. | N/A |
| 16 | Corrupt JSON fallback | Pass | Acceptance harness passed corrupt JSON fallback scenario. | N/A |
| 17 | App foreground after date boundary | Pass | Acceptance harness passed passive lifecycle reconciliation scenario. | N/A |
| 18 | Reduce Motion enabled | Not tested | Requires hands-on accessibility setting change. | N/A |
| 19 | Small iPhone screen | Partial | Dai Pan iPhone is available as an iPhone 14-sized screen; visual small-screen pass still requires manual inspection. | N/A |
| 20 | Larger iPhone screen | Not tested | Larger hardware records remain unavailable. | N/A |

## Screenshot Audit

No physical-device screenshots were captured in this pass. The app now launches on hardware, but the requested screenshot states require hands-on navigation, capture, and permission interactions on the iPhone. Simulator screenshot routes remain documented in `docs/P0_SCREENSHOT_AUDIT.md`.

| Screen | Status | Notes |
| --- | --- | --- |
| Fresh Day 1 | Not tested | Requires visual capture on physical device. |
| After Day 1 capture | Not tested | Requires hardware capture or picker. |
| Today's Trace | Not tested | Requires capture flow. |
| Day 4 rainy umbrella trace | Partial | Covered by acceptance logs; visual audit not captured. |
| Day 5 night lamplighter trace | Partial | Covered by acceptance logs; visual audit not captured. |
| Day 7 final form | Partial | Covered by acceptance logs; visual audit not captured. |
| Completed Life Album | Partial | Acceptance generated LifeAlbums; visual audit not captured. |
| Cycle Record | Partial | Acceptance generated CycleRecords; visual audit not captured. |
| Story Card traceSeen | Partial | StoryCard progression covered by harness; visual audit not captured. |
| Story Card recurring | Partial | Recurrence/dedup covered by harness; visual audit not captured. |
| Locked Era Memory | Partial | Era boundary lock covered by harness; visual audit not captured. |
| Unlocked Era Memory | Partial | EraMemory unlock covered by harness; visual audit not captured. |
| Permission denied state | Not tested | Requires physical permission flow. |
| No-photo empty state | Not tested | Requires visual capture on physical device. |
| Missed-day placeholder state | Partial | Low-participation placeholders covered by harness; visual audit not captured. |

## Bug Table

| ID | Severity | Area | Repro steps | Expected | Actual | Screenshot | Fix recommendation | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| QA-ENV-001 | Blocker | Other | Run physical-device discovery with Xcode/devicectl/xctrace. | At least one iPhone is online and available for install/run. | Dai Pan iPhone is now visible to Xcode/devicectl and accepted install. | N/A | None. Hardware availability blocker is resolved. | Resolved; not an app defect |
| QA-ENV-002 | Blocker | Other | Install signed Debug app via `devicectl`, then launch `dai.pan.picod`. | App launches on the iPhone after device unlock/profile trust. | Second-round launch succeeded. | N/A | None. Continue hands-on permission, capture, and screenshot QA. | Resolved; not an app defect |
| QA-UX-001 | High | Capture | On first/current day, tap the primary daily photo action. | User can choose camera or upload/library. | Initial flow went directly to camera, making upload unavailable or hidden. | User screenshot | Present a source dialog with Take Photo and Choose from Library. | Fixed locally |
| QA-UX-002 | Medium | Home map | View home screen with Memory Drawer handle visible. | Side affordance should be discoverable but quiet. | Handle was visually heavy and covered the map composition. | User screenshot | Reduce handle size/opacity and move it farther off the map. | Fixed locally |
| QA-DATA-001 | High | Memory Drawer | Compare home Pico with Memory Drawer current Pico. | Current Life Pico should match the canonical current home form. | Memory Drawer showed a different Pico than the main screen. | User screenshot | Pass the current home form ID into the Memory Drawer and prefer it for current render. | Fixed locally |
| QA-TIME-001 | High | Time/map mood | Open app around local noon without explicit debug time override. | Header/time phase and map lighting should follow local device time. | Runtime defaulted to DEBUG night variant, showing Good Night and dark map at noon. | User screenshot | Make debug time override nil unless explicitly configured; gate preview working state to preview/env. | Fixed locally |
| QA-DATA-002 | High | Photo metadata | Capture/import a daily photo. | Photo pipeline preserves real image bytes where possible and parses EXIF/GPS if present. | Pipeline mostly used `UIImage`, which can discard original EXIF; library import did not prefer original asset data. | N/A | Preserve `AVCapturePhoto.fileDataRepresentation`, prefer original `PHAsset` image data, parse with ImageIO, and persist metadata. | Fixed locally; needs unlocked-device empirical capture check |
| QA-ENV-003 | Blocker | Weather | Enable real WeatherKit climate on current Personal Development Team. | App can fetch real local temp/humidity/rain/precipitation from WeatherKit. | Provisioning rejects WeatherKit capability for current team; real weather cannot be verified. | N/A | Use paid Apple Developer team with WeatherKit enabled, or explicitly choose another weather provider outside P0 scope. | Blocked by Apple provisioning |
| QA-UX-003 | High | Home map | Turn Reduce Motion on, then view the main map. | UI transitions can be reduced, but the living map should still show subtle water/wind/weather motion. | `Reduce Motion` disabled `MapView.animateAmbient`, freezing water glints, wind leaves, rain, mist, cloud shadows, and signal bubbles. | User report | Keep map ambient animation enabled while preserving Reduce Motion for UI transitions/simulation pacing. | Fixed locally |
| QA-UX-004 | High | Home map | View the living map and watch animals/visitors, then let Pico wander near them. | Existing animals should move subtly, quiet bubbles should appear, nearby interaction logs should fire, and only Pico should cast a character shadow. | Animals were static, interaction bubbles were missing, and the shared sprite default made props/animals look like floating objects with shadows. | User report | Move existing animals within suitable local tiles, draw animal signal bubbles, emit calm nearby interaction events, default sprites to no shadow, and keep Pico shadow explicit. | Fixed locally; deployed to iPhone for hands-on confirmation |

## Bugs Fixed

- `QA-UX-001`: primary daily photo flow now supports camera and photo-library selection.
- `QA-UX-002`: Memory Drawer handle is smaller and less visually dominant over the map.
- `QA-DATA-001`: Memory Drawer current Pico now follows the same canonical form ID as the home screen.
- `QA-TIME-001`: debug defaults no longer force night mode during normal runtime.
- `QA-DATA-002`: capture/import now preserves original image data where possible, parses EXIF/GPS metadata, and persists capture metadata/environment snapshots.
- `QA-UX-003`: map ambient animation is no longer disabled by the Reduce Motion preference.
- `QA-UX-004`: existing map animals now move, show subtle signal bubbles, can produce nearby interaction events, and no longer cast prop/animal shadows.

## Bugs Deferred

- `QA-ENV-001`: resolved; physical-device availability is unblocked for Dai Pan iPhone.
- `QA-ENV-002`: resolved; second-round install and launch succeeded on Dai Pan iPhone.
- `QA-ENV-003`: real WeatherKit climate remains blocked by Apple provisioning/capability on the current Personal Development Team.
- `QA-DATA-002`: code path is implemented and build-verified, but still needs a real unlocked-device capture/import and container inspection to prove saved `hasEXIF`, `hasGPS`, and `captureEnvironment` for that exact photo.
- Physical permission, camera, photo-library, device-settings, and manual screenshot scenarios remain deferred until hands-on QA is performed on the launched app.

## Build And Acceptance Results

- Simulator Debug build: succeeded.
- Generic iOS device build: succeeded.
- Physical iPhone Debug build/sign: succeeded after `-allowProvisioningUpdates`.
- Physical iPhone install: succeeded.
- Physical iPhone launch: succeeded via `devicectl` in the second-round build test and again after the animal/shadow hardening pass.
- P0 acceptance harness: `passed=14 failed=0`.

## Limited External Handoff Readiness

Not ready to claim real-device external handoff yet. The P0 codebase is simulator/generic-device-build verified, and it now physically builds/signs/installs/launches on Dai Pan iPhone, but the required hands-on permission, capture, relaunch-after-capture, and screenshot checklist still needs to be executed.

Recommended next step: continue the Phase 2 manual checklist on the launched iPhone, beginning with camera/photo permission and one successful daily capture.

## Safety Confirmation

- No new features were added.
- No Pico forms were added.
- No storylines were added.
- Map complexity was not expanded.
- Architecture was not rewritten.
- DEBUG-only features were not exposed to normal users.
- P0 acceptance harness was preserved.
- No content expansion was introduced.
