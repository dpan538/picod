import Foundation

enum DevTestMode {
    private static var environment: [String: String] {
        ProcessInfo.processInfo.environment
    }

    enum MapReviewVariant: String, CaseIterable {
        case forestShrine
        case wetlandLantern
        case villageMarket
        case nightGrove
        case aprilDense
    }

    enum TimeOfDayReviewState: String {
        case morning
        case afternoon
        case dusk
        case night

        var ambientProgress: Double {
            switch self {
            case .morning: return 0.08
            case .afternoon: return 0.14
            case .dusk: return 0.46
            case .night: return 0.72
            }
        }

        var representativeHour: Int {
            switch self {
            case .morning: return 8
            case .afternoon: return 14
            case .dusk: return 18
            case .night: return 21
            }
        }
    }

    // Toggle for world/map development. When true, app boots with full handcrafted test world.
    static let useFullTestMap = true
    /// Xcode Canvas 会设置 `XCODE_RUNNING_FOR_PLAYGROUNDS`。`true` 时仍尝试完整 `fullWorld`；若生成/校验失败会 **自动退回草地占位图** 并 `print`，不再 `fatalError` 杀预览。
    /// `false` 时预览 **直接** 用占位图（省一次生成）。正式 `Run` 不受此项影响；非 Preview 下失败仍会 `fatalError`。
    static let renderFullMapInXcodePreview = true
    // Toggle to inspect single-object readability before returning to full-map iteration.
    static let showObjectGalleryDebug = false
    static let showMockSeed = false
    static let runPhotoPipelineMockValidation = false
    static let showPhotoPipelineDebug = false
    static let enableStorySidePanel = true
    static var runWorldRichnessAudit: Bool {
        environment["PICOD_RUN_WORLD_RICHNESS_AUDIT"] == "1"
    }
    static var previewWorkingStateWhenEmpty: Bool {
        environment["PICOD_PREVIEW_WORKING_STATE"] == "1" ||
            environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ||
            environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
    }
    static let freezePreviewReferenceMovement = true

    static var previewFormId: Int {
        max(0, intEnvironmentValue("PICOD_PREVIEW_FORM_ID") ?? 16)
    }

    // Optional keyframe review state: switch among .morning / .afternoon / .dusk / .night.
    // Set to nil to follow the live system clock.
    static var timeOfDayReviewState: TimeOfDayReviewState? {
        guard let raw = environment["PICOD_TIME_VARIANT"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty
        else {
            return nil
        }
        if raw == "live" || raw == "system" || raw == "none" {
            return nil
        }
        return TimeOfDayReviewState(rawValue: raw) ?? .night
    }

    // Legacy hard night override (kept for quick checks, usually keep false during keyframe review).
    static let forceNightMood = false

    static var locationPreset: LocationTraitPreset {
        if let raw = environment["PICOD_LOCATION_PRESET"],
           let preset = LocationTraitPreset(rawValue: raw) {
            return preset
        }
        return .parkLike
    }

    static var mapReviewVariant: MapReviewVariant {
        if let raw = environment["PICOD_MAP_VARIANT"] {
            if raw == "auto" {
                return inferredMapReviewVariant
            }
            if let variant = MapReviewVariant(rawValue: raw) {
                return variant
            }
        }
        if environment["PICOD_LOCATION_PRESET"] != nil ||
            environment["PICOD_WEATHER_CONDITION"] != nil ||
            environment["PICOD_TIME_VARIANT"] != nil {
            return inferredMapReviewVariant
        }
        return .forestShrine
    }

    private static var inferredMapReviewVariant: MapReviewVariant {
        switch (locationPreset, reviewWeatherCondition, timeOfDayReviewState) {
        case (.urbanLike, _, _):
            return .villageMarket
        case (.watersideLike, _, _):
            return .wetlandLantern
        case (_, .rainy, _), (_, .stormy, _), (_, .foggy, _):
            return .wetlandLantern
        case (_, _, .night):
            return .nightGrove
        default:
            return .forestShrine
        }
    }

    static var reviewWeather: (tempText: String, humidText: String, condition: WeatherCondition) {
        let temp = intEnvironmentValue("PICOD_TEMP_C") ?? defaultTemperatureCelsius
        let humid = intEnvironmentValue("PICOD_HUMIDITY") ?? defaultHumidityPercent
        return ("\(temp)°", "\(humid)%", reviewWeatherCondition)
    }

    static var mapReviewSummary: String {
        [
            "map=\(mapReviewVariant.rawValue)",
            "time=\(timeOfDayReviewState?.rawValue ?? "live")",
            "weather=\(reviewWeatherCondition.reviewName)",
            "temp=\(reviewWeather.tempText)",
            "humidity=\(reviewWeather.humidText)",
            "location=\(locationPreset.rawValue)"
        ].joined(separator: " ")
    }

    static var worldGenerationContext: WorldGenerationContext {
        WorldSeedMapper.toContext(seed: WorldSeedEngine.mockGenerate(), base: .devPreset(locationPreset))
    }

    static var mapMoodProgressOverride: Double? {
        if forceNightMood { return 0.72 }
        return timeOfDayReviewState?.ambientProgress
    }

    static var hourOverride: Int? {
        if forceNightMood { return 21 }
        return timeOfDayReviewState?.representativeHour
    }

    private static var reviewWeatherCondition: WeatherCondition {
        if let raw = environment["PICOD_WEATHER_CONDITION"],
           let condition = WeatherCondition.reviewValue(raw) {
            return condition
        }
        return .sunny
    }

    private static var defaultTemperatureCelsius: Int {
        switch timeOfDayReviewState {
        case .morning:
            return 18
        case .afternoon:
            return 24
        case .dusk:
            return 21
        case .night:
            return 16
        case nil:
            return 24
        }
    }

    private static var defaultHumidityPercent: Int {
        switch reviewWeatherCondition {
        case .rainy, .stormy:
            return 88
        case .foggy:
            return 81
        case .cloudy, .partlyCloudy:
            return 66
        case .snowy:
            return 74
        case .sunny, .night, .unknown:
            return locationPreset == .watersideLike ? 72 : 59
        }
    }

    private static func intEnvironmentValue(_ key: String) -> Int? {
        guard let raw = environment[key],
              let value = Int(raw)
        else {
            return nil
        }
        return value
    }
}

private extension WeatherCondition {
    static func reviewValue(_ raw: String) -> WeatherCondition? {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "sunny", "clear":
            return .sunny
        case "cloudy", "cloud":
            return .cloudy
        case "partlycloudy", "partly_cloudy", "partly-cloudy", "cloudsun", "cloud_sun":
            return .partlyCloudy
        case "rainy", "rain":
            return .rainy
        case "stormy", "storm":
            return .stormy
        case "snowy", "snow":
            return .snowy
        case "foggy", "fog":
            return .foggy
        case "night":
            return .night
        default:
            return nil
        }
    }

    var reviewName: String {
        switch self {
        case .sunny:
            return "sunny"
        case .cloudy:
            return "cloudy"
        case .partlyCloudy:
            return "partlyCloudy"
        case .rainy:
            return "rainy"
        case .stormy:
            return "stormy"
        case .snowy:
            return "snowy"
        case .foggy:
            return "foggy"
        case .night:
            return "night"
        case .unknown:
            return "unknown"
        }
    }
}
