import Foundation

struct WorldGenerationContext: Codable, Equatable {
    enum Style: String, Codable {
        case retroMeadow
    }

    struct FuturePhotoTraits: Codable, Equatable {
        // Placeholder only. Photo traits will be wired in a later phase.
        var warmth: Double
        var contrast: Double

        static let neutral = FuturePhotoTraits(warmth: 0.5, contrast: 0.5)
    }

    var seed: UInt64
    var style: Style
    var locationTraits: LocationTraits?
    var photoTraits: FuturePhotoTraits?

    init(
        seed: UInt64,
        style: Style = .retroMeadow,
        locationTraits: LocationTraits? = nil,
        photoTraits: FuturePhotoTraits? = nil
    ) {
        self.seed = seed
        self.style = style
        self.locationTraits = locationTraits
        self.photoTraits = photoTraits
    }

    var resolvedLocationTraits: LocationTraits {
        locationTraits ?? .neutral
    }

    var resolvedPhotoTraits: FuturePhotoTraits {
        photoTraits ?? .neutral
    }

    static func devPreset(_ preset: LocationTraitPreset, seed: UInt64 = 0xA11CE_2026) -> WorldGenerationContext {
        WorldGenerationContext(seed: seed, style: .retroMeadow, locationTraits: preset.traits)
    }
}
