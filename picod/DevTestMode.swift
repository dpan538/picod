import Foundation

enum DevTestMode {
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

    // Optional keyframe review state: switch among .morning / .afternoon / .dusk / .night.
    // Set to nil to follow the live system clock.
    static let timeOfDayReviewState: TimeOfDayReviewState? = .afternoon

    // Legacy hard night override (kept for quick checks, usually keep false during keyframe review).
    static let forceNightMood = false

    static let locationPreset: LocationTraitPreset = .parkLike
    static let worldGenerationContext = WorldGenerationContext.devPreset(locationPreset)

    static var mapMoodProgressOverride: Double? {
        if forceNightMood { return 0.72 }
        return timeOfDayReviewState?.ambientProgress
    }

    static var hourOverride: Int? {
        if forceNightMood { return 21 }
        return timeOfDayReviewState?.representativeHour
    }
}
