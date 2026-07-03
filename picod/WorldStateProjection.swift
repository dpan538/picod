import Foundation

enum WorldMoodLayer: String, Codable, Hashable {
    case quiet
    case warm
    case cool
    case rainy
    case night
    case remembered
}

enum WorldLightingLayer: String, Codable, Hashable {
    case morning
    case day
    case dusk
    case night
    case softGlow
}

enum WorldWeatherLayer: String, Codable, Hashable {
    case clear
    case cloudy
    case rain
    case fog
    case snow
    case unknown
}

enum WorldParticipationLayer: String, Codable, Hashable {
    case unknown
    case still
    case sparse
    case steady
    case dense
}

enum WorldPlacementIntent: String, Codable, Hashable {
    case base
    case pathEdge
    case waterEdge
    case shrineEdge
    case picoNearby
    case perimeter
    case courtyard
    case hiddenEcho
}

enum WorldVisualPriority: String, Codable, Hashable {
    case background
    case low
    case medium
    case high
}

enum WorldCollisionPolicy: String, Codable, Hashable {
    case passable
    case softBlock
    case blocking
}

enum WorldOcclusionPolicy: String, Codable, Hashable {
    case neverOccludePico
    case lowRisk
    case reportedRisk
}

enum WorldProjectionPersistenceScope: String, Codable, Hashable {
    case daily
    case life
    case cycle
    case era
    case permanentUntilReset
}

enum WorldProjectedElementSource: String, Codable, Hashable {
    case photoMood
    case picoEvolution
    case storyTrace
    case cycleRecord
    case eraMemory
    case participation
    case baseMap
}

struct WorldProjectedElement: Identifiable, Codable, Hashable {
    var schemaVersion: Int? = 1
    let id: String
    let catalogElementID: String
    let role: WorldElementRole
    let placementIntent: WorldPlacementIntent
    let tileOrAnchor: MapCoord
    let visualPriority: WorldVisualPriority
    let collisionPolicy: WorldCollisionPolicy
    let occlusionPolicy: WorldOcclusionPolicy
    let persistenceScope: WorldProjectionPersistenceScope
    let evidenceIDs: [String]
    let source: WorldProjectedElementSource
    let debugReason: String
}

struct WorldPicoAccessibilityZone: Codable, Hashable {
    var schemaVersion: Int? = 1
    let spawn: MapCoord
    let protectedRadius: Int
    let preferredRouteTarget: MapCoord?
}

struct WorldProjectionValidationSummary: Codable, Hashable {
    var schemaVersion: Int? = 1
    let errorCount: Int
    let warningCount: Int
    let didPassCoreRules: Bool
    let summary: String

    static let notYetValidated = WorldProjectionValidationSummary(
        errorCount: 0,
        warningCount: 0,
        didPassCoreRules: true,
        summary: "not validated"
    )
}

struct WorldStateProjection: Identifiable, Codable, Hashable {
    var schemaVersion: Int? = 1
    let id: String
    let localDayKey: PicodDayKey
    let lifeID: LifeID
    let cycleID: CycleID
    let eraID: EraID
    let mapVariantID: String
    let baseWorldSeedID: String?
    let moodLayer: WorldMoodLayer
    let lightingLayer: WorldLightingLayer
    let weatherLayer: WorldWeatherLayer
    let participationLayer: WorldParticipationLayer
    let picoAccessibilityZone: WorldPicoAccessibilityZone
    let persistentElements: [WorldProjectedElement]
    let transientElements: [WorldProjectedElement]
    let storyTraceElements: [WorldProjectedElement]
    let cycleMarkerElements: [WorldProjectedElement]
    let eraEchoElements: [WorldProjectedElement]
    let blockedZones: [MapCoord]
    let visualOcclusionRisks: [MapCoord]
    let validationSummary: WorldProjectionValidationSummary
    let sourceEvidenceIDs: [String]
    let generatedAt: Date
    let projectionVersion: Int

    var allElements: [WorldProjectedElement] {
        persistentElements + transientElements + storyTraceElements + cycleMarkerElements + eraEchoElements
    }
}

struct WorldElementPlacementPlan: Codable, Hashable {
    var schemaVersion: Int? = 1
    let projection: WorldStateProjection
    let projectedProps: [PropPlacement]
    let projectedAnimals: [AnimalPlacement]
}

enum WorldProjectionMapAdapter {
    static func placementPlan(for projection: WorldStateProjection) -> WorldElementPlacementPlan {
        WorldElementPlacementPlan(
            projection: projection,
            projectedProps: runtimeProps(from: projection),
            projectedAnimals: runtimeAnimals(from: projection)
        )
    }

    static func runtimeProps(from projection: WorldStateProjection) -> [PropPlacement] {
        projection.allElements.compactMap { element in
            guard let kind = PropKind(rawValue: element.catalogElementID) else { return nil }
            return PropPlacement(kind: kind, coord: element.tileOrAnchor)
        }
    }

    static func runtimeAnimals(from projection: WorldStateProjection) -> [AnimalPlacement] {
        projection.allElements.compactMap { element in
            guard let kind = AnimalKind(rawValue: element.catalogElementID) else { return nil }
            return AnimalPlacement(kind: kind, coord: element.tileOrAnchor)
        }
    }
}
