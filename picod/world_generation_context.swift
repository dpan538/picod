import Foundation

struct WorldGenerationContext: Codable, Equatable {
    enum Style: String, Codable {
        case retroMeadow
    }

    struct FuturePhotoTraits: Codable, Equatable {
        // Placeholder only. Photo traits will be wired in a later phase.
        var warmth: Double
        var contrast: Double
        var waterExpansion: Double
        var waterClarity: Double
        var vegetationDensity: Double
        var vineProbability: Double
        var courtyardExpansion: Double
        var toriiBonus: Double
        var pathExtension: Int
        var propWeights: [String: Double]
        var npcBonuses: [String: Double]
        var personalityTag: String

        static let neutral = FuturePhotoTraits(
            warmth: 0.5,
            contrast: 0.5,
            waterExpansion: 0.0,
            waterClarity: 0.5,
            vegetationDensity: 1.0,
            vineProbability: 0.0,
            courtyardExpansion: 0.0,
            toriiBonus: 0.0,
            pathExtension: 0,
            propWeights: [:],
            npcBonuses: [:],
            personalityTag: PicoPersonality.natural.rawValue
        )
    }

    var seed: UInt64
    var style: Style
    var locationTraits: LocationTraits?
    var photoTraits: FuturePhotoTraits?
    var participationLevel: Double

    init(
        seed: UInt64,
        style: Style = .retroMeadow,
        locationTraits: LocationTraits? = nil,
        photoTraits: FuturePhotoTraits? = nil,
        participationLevel: Double = 1.0
    ) {
        self.seed = seed
        self.style = style
        self.locationTraits = locationTraits
        self.photoTraits = photoTraits
        self.participationLevel = participationLevel
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

    static func from(worldInput: PicodWorldInput) -> WorldGenerationContext {
        let influence = worldInput.environmentalInfluence
        let traits = LocationTraits(
            watersideBias: influence.waterBias,
            greenBias: influence.greeneryBias,
            urbanBias: influence.urbanBias,
            opennessBias: 1.0 - influence.elevationBias
        )
        return WorldGenerationContext(
            seed: worldInput.volatile.instanceSeed,
            style: .retroMeadow,
            locationTraits: traits,
            photoTraits: .neutral
        )
    }
}
