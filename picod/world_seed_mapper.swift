import Foundation

struct WorldSeedMapper {
    static func toContext(seed: WorldSeed, base: WorldGenerationContext) -> WorldGenerationContext {
        var context = base

        context.photoTraits = WorldGenerationContext.FuturePhotoTraits(
            warmth: Double(0.5 + seed.terrainWarmBias),
            contrast: Double(seed.terrainBrightness),
            waterExpansion: Double(seed.waterExpansion),
            waterClarity: Double(seed.waterClarity),
            vegetationDensity: Double(seed.vegetationDensity),
            vineProbability: Double(seed.vineProbability),
            courtyardExpansion: Double(seed.courtyardExpansion),
            toriiBonus: Double(seed.toriiProbabilityBonus),
            pathExtension: seed.pathExtension,
            propWeights: seed.propWeights.mapValues { Double($0) },
            npcBonuses: seed.npcProbabilityBonuses.mapValues { Double($0) },
            personalityTag: seed.personalityTerrainTag.rawValue
        )

        context.participationLevel = Double(seed.participationMultiplier)

        return context
    }
}
