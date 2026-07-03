import Foundation

enum WorldElementRole: String, Codable, Hashable {
    case structure
    case flora
    case dailyProp
    case photoTrace
    case visitorAnchor
    case cycleMarker
    case eraEcho
}

enum WorldGroundingStyle: String, Codable, Hashable {
    case picoShadow
    case contactPixels
    case foundation
    case waterContact
    case canopyOcclusion
    case glowOnly
}

enum WorldOcclusionClass: String, Codable, Hashable {
    case none
    case low
    case canopy
    case tallStructure
    case foregroundOnly

    var isPicoRisk: Bool {
        switch self {
        case .canopy, .tallStructure, .foregroundOnly:
            return true
        case .none, .low:
            return false
        }
    }
}

enum WorldConnectionRequirement: String, Codable, Hashable {
    case none
    case path
    case courtyard
    case water
    case threshold
}

struct WorldFootprint: Codable, Hashable {
    let width: Int
    let height: Int

    static let one = WorldFootprint(width: 1, height: 1)

    func cells(anchor: MapCoord) -> Set<MapCoord> {
        let safeWidth = max(1, width)
        let safeHeight = max(1, height)
        let minX = safeWidth.isMultiple(of: 2) ? anchor.x - (safeWidth / 2) + 1 : anchor.x - (safeWidth / 2)
        let maxX = minX + safeWidth - 1
        let minY = anchor.y - safeHeight + 1
        let maxY = anchor.y

        var result = Set<MapCoord>()
        for y in minY...maxY {
            for x in minX...maxX {
                result.insert(MapCoord(x: x, y: y))
            }
        }
        return result
    }
}

struct WorldElementSpec: Codable, Hashable {
    let id: String
    let role: WorldElementRole
    let footprint: WorldFootprint
    let visualFootprint: WorldFootprint
    let groundingStyle: WorldGroundingStyle
    let occlusionClass: WorldOcclusionClass
    let connectionRequirements: Set<WorldConnectionRequirement>
    let compatibleTerrain: Set<Landform>
    let blocksPico: Bool
    let canOccludePico: Bool
    let requiresApproachTile: Bool

    var isMajorStructure: Bool {
        role == .structure && visualFootprint.width >= 2 && visualFootprint.height >= 2
    }
}

enum WorldElementCatalog {
    static func spec(for kind: PropKind) -> WorldElementSpec {
        switch kind {
        case .tree, .roundTree, .sacredEvergreen, .gardenPine, .dwarfPine:
            return flora(kind, footprint: .one, visual: .init(width: 3, height: 4), occlusion: .canopy)
        case .tallTree, .tallPine:
            return flora(kind, footprint: .init(width: 1, height: 2), visual: .init(width: 3, height: 4), occlusion: .canopy)
        case .bigTree:
            return flora(kind, footprint: .init(width: 2, height: 2), visual: .init(width: 4, height: 5), occlusion: .canopy)
        case .cherryTree, .weepingCherry, .cherryClump:
            return flora(kind, footprint: .one, visual: .init(width: 3, height: 4), occlusion: .canopy)

        case .bush, .smallBush:
            return flora(kind, footprint: .one, visual: .init(width: 2, height: 1), occlusion: .low, blocksPico: false)
        case .denseBush, .bushDense:
            return flora(kind, footprint: .init(width: 2, height: 1), visual: .init(width: 3, height: 2), occlusion: .low)
        case .flower, .pinkFlower, .yellowFlower, .flowerBed, .mushroomPatch:
            return dailyProp(kind, footprint: .one, visual: .init(width: 1, height: 1), grounding: .contactPixels, blocksPico: false)
        case .reed, .reedCluster:
            return dailyProp(
                kind,
                footprint: .one,
                visual: .init(width: 2, height: 2),
                grounding: .waterContact,
                connections: [.water],
                terrain: waterEdgeTerrain,
                blocksPico: false
            )
        case .stump, .log, .fallenLog, .rock, .smallRock:
            return dailyProp(kind, footprint: .one, visual: .init(width: 1, height: 1), grounding: .contactPixels, blocksPico: kind.isBlockingForPet)
        case .largeRock:
            return dailyProp(kind, footprint: .init(width: 2, height: 1), visual: .init(width: 3, height: 2), grounding: .contactPixels)

        case .house, .japaneseHouse:
            return structure(kind, footprint: .init(width: 4, height: 4), visual: .init(width: 4, height: 5), connections: [.path, .threshold])
        case .mansion:
            return structure(kind, footprint: .init(width: 5, height: 4), visual: .init(width: 4, height: 5), connections: [.courtyard, .threshold])
        case .japaneseSmallHouse, .tinyShed:
            return structure(kind, footprint: .init(width: 2, height: 2), visual: .init(width: 3, height: 3), connections: [.path])
        case .kiosk:
            return structure(kind, footprint: .init(width: 2, height: 2), visual: .init(width: 2, height: 2), connections: [.path])
        case .shrineSmall:
            return structure(kind, footprint: .init(width: 3, height: 3), visual: .init(width: 3, height: 3), connections: [.threshold])
        case .pagoda:
            return structure(kind, footprint: .init(width: 2, height: 3), visual: .init(width: 2, height: 3), connections: [.threshold])
        case .torii:
            return WorldElementSpec(
                id: kind.rawValue,
                role: .cycleMarker,
                footprint: .init(width: 2, height: 2),
                visualFootprint: .init(width: 2, height: 3),
                groundingStyle: .contactPixels,
                occlusionClass: .low,
                connectionRequirements: [.threshold],
                compatibleTerrain: pathTerrain.union(courtyardTerrain),
                blocksPico: true,
                canOccludePico: false,
                requiresApproachTile: true
            )
        case .gate:
            return structure(kind, footprint: .init(width: 2, height: 2), visual: .init(width: 2, height: 2), connections: [.path, .threshold])
        case .stoneWell:
            return structure(kind, footprint: .init(width: 2, height: 2), visual: .init(width: 2, height: 2), connections: [.path], terrain: courtyardTerrain.union(waterEdgeTerrain))
        case .bridgeShort:
            return structure(kind, footprint: .init(width: 2, height: 1), visual: .init(width: 2, height: 1), grounding: .waterContact, connections: [.water, .path], terrain: waterEdgeTerrain)
        case .japaneseBridge:
            return structure(kind, footprint: .init(width: 3, height: 2), visual: .init(width: 3, height: 2), grounding: .waterContact, connections: [.water, .path], terrain: waterEdgeTerrain)
        case .dock:
            return structure(kind, footprint: .init(width: 2, height: 1), visual: .init(width: 2, height: 1), grounding: .waterContact, connections: [.water], terrain: waterEdgeTerrain)
        case .lowWall, .fence, .fenceShort:
            return WorldElementSpec(
                id: kind.rawValue,
                role: .structure,
                footprint: .one,
                visualFootprint: .one,
                groundingStyle: .contactPixels,
                occlusionClass: .low,
                connectionRequirements: [.threshold],
                compatibleTerrain: courtyardTerrain.union(pathTerrain),
                blocksPico: true,
                canOccludePico: false,
                requiresApproachTile: false
            )

        case .sign, .signpost:
            return dailyProp(kind, footprint: .one, visual: .init(width: 1, height: 2), grounding: .contactPixels, connections: [.path])
        case .bench, .crate, .mailbox:
            return dailyProp(kind, footprint: .one, visual: .init(width: 1, height: 1), grounding: .contactPixels, connections: [.path])
        case .lantern, .stoneLanternJp:
            return WorldElementSpec(
                id: kind.rawValue,
                role: .dailyProp,
                footprint: .one,
                visualFootprint: .init(width: 1, height: 2),
                groundingStyle: .glowOnly,
                occlusionClass: .low,
                connectionRequirements: [.path],
                compatibleTerrain: pathTerrain.union(courtyardTerrain),
                blocksPico: kind.isBlockingForPet,
                canOccludePico: false,
                requiresApproachTile: false
            )
        case .car, .orangeTruck:
            return structure(kind, footprint: .init(width: 3, height: 2), visual: .init(width: 3, height: 2), connections: [.path])
        case .billboard:
            return structure(kind, footprint: .init(width: 2, height: 2), visual: .init(width: 2, height: 3), connections: [.path])
        case .windmill:
            return structure(kind, footprint: .init(width: 3, height: 4), visual: .init(width: 3, height: 5), connections: [.path])
        }
    }

    static func spec(for kind: AnimalKind) -> WorldElementSpec {
        let footprint = kind == .deer ? WorldFootprint(width: 2, height: 2) : .one
        let role: WorldElementRole
        switch kind {
        case .bird, .duck, .rabbit, .cat, .dog, .deer, .frog, .butterfly, .snail, .fishShadow, .cow, .sheep, .horse:
            role = .visitorAnchor
        default:
            role = .visitorAnchor
        }

        return WorldElementSpec(
            id: kind.rawValue,
            role: role,
            footprint: footprint,
            visualFootprint: footprint,
            groundingStyle: kind == .fishShadow ? .waterContact : .contactPixels,
            occlusionClass: .none,
            connectionRequirements: kind == .fishShadow ? [.water] : [],
            compatibleTerrain: kind == .fishShadow ? waterTerrain : Set(Landform.allCases),
            blocksPico: false,
            canOccludePico: false,
            requiresApproachTile: false
        )
    }

    static let pathTerrain: Set<Landform> = [.dirt, .wornPath, .stoneGround, .stone, .sand]
    static let courtyardTerrain: Set<Landform> = [.dirt, .stoneGround, .wornPath, .clearing, .grass, .mossGround]
    static let waterTerrain: Set<Landform> = [.water, .pond, .shallowWater, .deepWater]
    static let waterEdgeTerrain: Set<Landform> = waterTerrain.union([.wetBank, .reedsEdge, .sand, .mud])
    static let forestTerrain: Set<Landform> = [.forestEdge, .groveFloor, .mossGround, .tallGrass, .grass, .clearing]

    private static func flora(
        _ kind: PropKind,
        footprint: WorldFootprint,
        visual: WorldFootprint,
        occlusion: WorldOcclusionClass,
        blocksPico: Bool = true
    ) -> WorldElementSpec {
        WorldElementSpec(
            id: kind.rawValue,
            role: .flora,
            footprint: footprint,
            visualFootprint: visual,
            groundingStyle: .canopyOcclusion,
            occlusionClass: occlusion,
            connectionRequirements: [],
            compatibleTerrain: forestTerrain,
            blocksPico: blocksPico,
            canOccludePico: false,
            requiresApproachTile: false
        )
    }

    private static func dailyProp(
        _ kind: PropKind,
        footprint: WorldFootprint,
        visual: WorldFootprint,
        grounding: WorldGroundingStyle,
        connections: Set<WorldConnectionRequirement> = [],
        terrain: Set<Landform> = Set(Landform.allCases),
        blocksPico: Bool = true
    ) -> WorldElementSpec {
        WorldElementSpec(
            id: kind.rawValue,
            role: .dailyProp,
            footprint: footprint,
            visualFootprint: visual,
            groundingStyle: grounding,
            occlusionClass: .low,
            connectionRequirements: connections,
            compatibleTerrain: terrain,
            blocksPico: blocksPico,
            canOccludePico: false,
            requiresApproachTile: false
        )
    }

    private static func structure(
        _ kind: PropKind,
        footprint: WorldFootprint,
        visual: WorldFootprint,
        grounding: WorldGroundingStyle = .foundation,
        connections: Set<WorldConnectionRequirement>,
        terrain: Set<Landform> = courtyardTerrain.union(pathTerrain)
    ) -> WorldElementSpec {
        WorldElementSpec(
            id: kind.rawValue,
            role: .structure,
            footprint: footprint,
            visualFootprint: visual,
            groundingStyle: grounding,
            occlusionClass: visual.height >= 3 ? .tallStructure : .low,
            connectionRequirements: connections,
            compatibleTerrain: terrain,
            blocksPico: kind.isBlockingForPet,
            canOccludePico: false,
            requiresApproachTile: true
        )
    }
}

extension PropKind {
    var worldElementSpec: WorldElementSpec {
        WorldElementCatalog.spec(for: self)
    }
}

extension AnimalKind {
    var worldElementSpec: WorldElementSpec {
        WorldElementCatalog.spec(for: self)
    }
}
