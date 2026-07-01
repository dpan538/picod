import Foundation
import Combine

struct WorldSeed: Codable, Equatable {
    let generationId: String
    let dayKey: String

    // Day1
    var terrainWarmBias: Float
    var terrainBrightness: Float
    var personalityTerrainTag: PicoPersonality

    // Day2
    var waterExpansion: Float
    var waterClarity: Float

    // Day3
    var vegetationDensity: Float
    var vineProbability: Float

    // Day4
    var courtyardExpansion: Float
    var toriiProbabilityBonus: Float

    // Day5
    var pathExtension: Int
    var pathCondition: Float

    // Day6
    var propWeights: [String: Float]

    // Day7
    var npcProbabilityBonuses: [String: Float]

    // Global
    var participationMultiplier: Float
}

struct WorldSeedEngine {
    static func mockGenerate() -> WorldSeed {
        WorldSeed(
            generationId: "mock_generation",
            dayKey: "mock_generation_day7",
            terrainWarmBias: 0.1,
            terrainBrightness: 0.62,
            personalityTerrainTag: .natural,
            waterExpansion: 0.12,
            waterClarity: 0.58,
            vegetationDensity: 1.1,
            vineProbability: 0.08,
            courtyardExpansion: 0.05,
            toriiProbabilityBonus: 0.1,
            pathExtension: 1,
            pathCondition: 0.9,
            propWeights: [
                "cherryTree": 0.3,
                "stoneLantern": 0.2,
                "reed": 0.15
            ],
            npcProbabilityBonuses: [
                "animal": 0.2,
                "shrineMaiden": 0.1
            ],
            participationMultiplier: 1.0
        )
    }

    func generate(
        snapshots: [PhotoTraitSnapshot],
        participation: GenerationParticipation,
        previousSeed: WorldSeed?
    ) -> WorldSeed {
        if participation.level == .absent, var inherited = previousSeed {
            inherited.participationMultiplier = 0.0
            return inherited
        }

        let ordered = snapshots.sorted { lhs, rhs in
            if lhs.dayIndex != rhs.dayIndex { return lhs.dayIndex < rhs.dayIndex }
            return lhs.timestamp < rhs.timestamp
        }
        let generationId = ordered.first?.generationId ?? previousSeed?.generationId ?? "unknown_generation"
        let dayKey = ordered.last?.dayKey ?? previousSeed?.dayKey ?? "\(generationId)_day0"

        var seed = WorldSeed(
            generationId: generationId,
            dayKey: dayKey,
            terrainWarmBias: 0.0,
            terrainBrightness: 0.5,
            personalityTerrainTag: .natural,
            waterExpansion: 0.0,
            waterClarity: 0.5,
            vegetationDensity: 1.0,
            vineProbability: 0.0,
            courtyardExpansion: 0.0,
            toriiProbabilityBonus: 0.0,
            pathExtension: 0,
            pathCondition: 1.0,
            propWeights: [:],
            npcProbabilityBonuses: [:],
            participationMultiplier: 1.0
        )

        // Day1
        if let day1 = ordered.first(where: { $0.dayIndex == 1 }) {
            if let hsb = dominantHSB(from: day1.colorPalette) {
                if isWarmHue(hsb.hue) {
                    seed.terrainWarmBias += 0.2
                } else if (180...270).contains(hsb.hue) {
                    seed.terrainWarmBias -= 0.2
                }

                if hsb.brightness > 0.7 {
                    seed.terrainBrightness = 0.85
                } else if hsb.brightness < 0.3 {
                    seed.terrainBrightness = 0.2
                }
            }
            seed.personalityTerrainTag = MappingDatabase.personality(for: day1.chosenFormId)
        } else if participation.level == .absent, let previousSeed {
            seed.terrainWarmBias = previousSeed.terrainWarmBias
        }

        // Day2
        if let day2 = ordered.first(where: { $0.dayIndex == 2 }) {
            if containsAnyLabel(day2.normalizedLabels, keywords: ["water", "rain", "river", "ocean", "stream", "waterfall"]) {
                seed.waterExpansion += 0.2
            }
            if let hsb = dominantHSB(from: day2.colorPalette), (180...250).contains(hsb.hue) {
                seed.waterClarity += 0.2
            }
        } else if participation.level == .absent {
            seed.waterExpansion -= 0.05
        }

        // Day3
        if let day3 = ordered.first(where: { $0.dayIndex == 3 }) {
            if containsAnyLabel(day3.normalizedLabels, keywords: ["plant", "tree", "flower", "grass", "leaf", "moss"]) {
                seed.vegetationDensity += 0.15
            } else {
                seed.vegetationDensity -= 0.05
            }
            if let hsb = dominantHSB(from: day3.colorPalette), (80...160).contains(hsb.hue) {
                seed.vineProbability += 0.1
            }
        } else if participation.level == .absent {
            seed.vineProbability += 0.1
            seed.vegetationDensity -= 0.05
        }

        // Day4
        if let day4 = ordered.first(where: { $0.dayIndex == 4 }) {
            if containsAnyLabel(day4.normalizedLabels, keywords: ["building", "indoor", "architecture", "room", "furniture"]) {
                seed.courtyardExpansion += 0.1
            } else {
                seed.courtyardExpansion -= 0.05
            }
        }
        if participation.level == .minimal || participation.level == .absent {
            seed.toriiProbabilityBonus += 0.15
        }

        // Day5
        if let day5 = ordered.first(where: { $0.dayIndex == 5 }) {
            if containsAnyLabel(day5.normalizedLabels, keywords: ["horizon_line", "horizon line", "horizon"]) {
                seed.pathExtension += 2
            }
            if containsAnyLabel(day5.normalizedLabels, keywords: ["road", "path", "street", "pavement"]) {
                seed.pathExtension += 1
            }
        }
        if participation.level == .partial {
            seed.pathCondition -= 0.1
        }

        // Day6
        if let day6 = ordered.first(where: { $0.dayIndex == 6 }), participation.level != .absent {
            for label in day6.normalizedLabels {
                if contains(label, in: ["stone", "rock", "lantern"]) {
                    seed.propWeights["stoneLantern", default: 0] += 0.3
                } else if contains(label, in: ["flower", "blossom", "sakura"]) {
                    seed.propWeights["cherryTree", default: 0] += 0.3
                } else if contains(label, in: ["bamboo", "reed"]) {
                    seed.propWeights["bamboo", default: 0] += 0.3
                } else if contains(label, in: ["water", "pond", "river"]) {
                    seed.propWeights["reed", default: 0] += 0.3
                } else if contains(label, in: ["wooden", "wood"]) {
                    seed.propWeights["woodFence", default: 0] += 0.3
                } else {
                    seed.propWeights["smallDecor", default: 0] += 0.1
                }
            }
        }

        // Day7
        if let day7 = ordered.first(where: { $0.dayIndex == 7 }) {
            for label in day7.normalizedLabels {
                if contains(label, in: animalKeywords) {
                    seed.npcProbabilityBonuses["animal", default: 0] += 0.15
                }
                if contains(label, in: ["human", "face", "person"]) {
                    seed.npcProbabilityBonuses["human", default: 0] += 0.1
                }
                if contains(label, in: ["night", "dark", "moon"]) {
                    seed.npcProbabilityBonuses["nightSpirit", default: 0] += 0.15
                }
                if contains(label, in: ["plant", "tree", "nature"]) {
                    seed.npcProbabilityBonuses["forestSpirit", default: 0] += 0.1
                }
            }
        }
        if participation.level == .full {
            seed.npcProbabilityBonuses["truckDriver", default: 0] += 0.2
        }
        if participation.level == .minimal {
            seed.npcProbabilityBonuses["shrineMaiden", default: 0] += 0.2
        }

        // Global participation multiplier (last)
        switch participation.level {
        case .full:
            seed.participationMultiplier = 1.2
            scaleSeed(&seed, by: 1.2)
        case .partial:
            seed.participationMultiplier = 1.0
            scaleSeed(&seed, by: 1.0)
        case .minimal:
            seed.participationMultiplier = 0.6
            scaleSeed(&seed, by: 0.6)
        case .absent:
            seed.participationMultiplier = 0.0
            if var inherited = previousSeed {
                inherited.participationMultiplier = 0.0
                return inherited
            }
        }

        seed.terrainWarmBias = clamp(seed.terrainWarmBias, -1.0, 1.0)
        seed.terrainBrightness = clamp(seed.terrainBrightness, 0.0, 1.0)
        seed.waterExpansion = clamp(seed.waterExpansion, -1.0, 1.0)
        seed.waterClarity = clamp(seed.waterClarity, 0.0, 1.0)
        seed.vegetationDensity = clamp(seed.vegetationDensity, 0.0, 2.0)
        seed.vineProbability = clamp(seed.vineProbability, 0.0, 1.0)
        seed.courtyardExpansion = clamp(seed.courtyardExpansion, -1.0, 1.0)
        seed.pathExtension = max(-2, min(2, seed.pathExtension))
        seed.pathCondition = clamp(seed.pathCondition, 0.0, 1.0)

        return seed
    }

    private let animalKeywords: [String] = [
        "cat", "dog", "bird", "rabbit", "fox", "deer", "fish", "frog", "crab", "boar", "crow", "heron", "dragonfly", "cicada"
    ]

    private func dominantHSB(from palette: [PhotoPaletteColor]) -> HSBColor? {
        guard let first = palette.first else { return nil }
        return hsb(from: first)
    }

    private func hsb(from color: PhotoPaletteColor) -> HSBColor {
        let r = Float(color.red)
        let g = Float(color.green)
        let b = Float(color.blue)
        let maxV = max(r, g, b)
        let minV = min(r, g, b)
        let delta = maxV - minV

        var hue: Float = 0
        if delta != 0 {
            if maxV == r {
                hue = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
            } else if maxV == g {
                hue = 60 * (((b - r) / delta) + 2)
            } else {
                hue = 60 * (((r - g) / delta) + 4)
            }
        }
        if hue < 0 { hue += 360 }

        let saturation: Float = maxV == 0 ? 0 : (delta / maxV)
        let brightness: Float = maxV

        return HSBColor(hue: hue, saturation: saturation, brightness: brightness)
    }

    private func isWarmHue(_ hue: Float) -> Bool {
        (0...60).contains(hue) || (300...360).contains(hue)
    }

    private func containsAnyLabel(_ labels: [String], keywords: [String]) -> Bool {
        labels.contains { label in contains(label, in: keywords) }
    }

    private func contains(_ label: String, in keywords: [String]) -> Bool {
        let normalized = label.lowercased()
        return keywords.contains { normalized.contains($0.lowercased()) }
    }

    private func scaleSeed(_ seed: inout WorldSeed, by multiplier: Float) {
        seed.terrainWarmBias *= multiplier
        seed.waterExpansion *= multiplier
        seed.waterClarity *= multiplier
        seed.vegetationDensity = 1.0 + (seed.vegetationDensity - 1.0) * multiplier
        seed.vineProbability *= multiplier
        seed.courtyardExpansion *= multiplier
        seed.toriiProbabilityBonus *= multiplier
        seed.pathCondition *= multiplier
        seed.pathExtension = Int((Float(seed.pathExtension) * multiplier).rounded())

        seed.propWeights = seed.propWeights.mapValues { $0 * multiplier }
        seed.npcProbabilityBonuses = seed.npcProbabilityBonuses.mapValues { $0 * multiplier }
    }

    private func clamp(_ value: Float, _ minValue: Float, _ maxValue: Float) -> Float {
        max(minValue, min(maxValue, value))
    }
}

@MainActor
final class WorldSeedDatabase: ObservableObject {
    @Published private(set) var seedsByGenerationId: [String: WorldSeed] = [:]

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var saveTask: Task<Void, Never>?

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.makeFileURL()
        load()
    }

    func save(_ seed: WorldSeed) {
        seedsByGenerationId[seed.generationId] = seed
        scheduleSave()
    }

    func load(generationId: String) -> WorldSeed? {
        seedsByGenerationId[generationId]
    }

    func resetAll() {
        saveTask?.cancel()
        seedsByGenerationId = [:]
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([String: WorldSeed].self, from: data) else {
            seedsByGenerationId = [:]
            return
        }
        seedsByGenerationId = decoded
    }

    private func saveNow() {
        guard let data = try? encoder.encode(seedsByGenerationId) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard let self, !Task.isCancelled else { return }
            self.saveNow()
        }
    }

    private static func makeFileURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("picod", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("world_seed_db.json")
    }
}
