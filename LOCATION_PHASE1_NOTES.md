# Picod Location Phase 1 Notes

## Permission Scope
- Phase 1 uses **When-In-Use** authorization only.
- API: `requestWhenInUseAuthorization()`.

## Required Info.plist Keys
Add these keys to the app target configuration:
- `NSLocationWhenInUseUsageDescription`
  - Suggested value: "Picod uses your location while the app is open to personalize world mood, weather context, and map style."

If WeatherKit is enabled in your target capabilities, also ensure Weather entitlement/capability is configured in Xcode.

## State Machine
Location/weather state is intentionally explicit:
- Authorization:
  - `notDetermined`
  - `denied`
  - `restricted`
  - `authorizedWhenInUse`
- Location data:
  - `idle`
  - `resolving`
  - `resolved`
  - `unavailable`
- Weather data:
  - `idle`
  - `resolving`
  - `resolved`
  - `unavailable`

## Refresh Policy
No continuous tracking for Phase 1.
- Launch: one-shot refresh
- Foreground return: one-shot refresh
- Manual user refresh: one-shot refresh

## Seed Policy
- `worldSeed` is generated from **quantized coordinates** only.
- Quantization step is fixed to `0.006°` (~300-800m class behavior depending on latitude).
- Small movement should not churn world identity.
- `instanceSeed` is derived from `worldSeed + timePhase + weather + session`.

## Reverse Geocode Fallback Chain
Weak place identity fallback order:
- `locality`
- `subAdministrativeArea`
- `administrativeArea`
- `country`
- `nil`

## Weather Cache
- Cached by quantized coordinate key.
- TTL: 20 minutes.
- If weather fetch fails, last cache is reused if available.

## Fallback UX Intent
- Permission denied/restricted:
  - app still works with fallback world profile
- Authorized but location unresolved:
  - fallback world profile, retry on next refresh
- Authorized but weather unavailable:
  - location-driven world profile + weather fallback
