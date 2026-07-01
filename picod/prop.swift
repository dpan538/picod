import Foundation

enum PropKind: String, CaseIterable, Codable {
    // Legacy authored-map aliases
    case tree
    case bush
    case sign
    case log
    case reed
    case rock
    case flower
    case fence

    // Flora / natural props
    case roundTree
    case tallTree
    case bigTree
    case cherryTree
    case weepingCherry
    case cherryClump
    case sacredEvergreen
    case gardenPine
    case tallPine
    case dwarfPine
    case smallBush
    case denseBush
    case bushDense
    case pinkFlower
    case yellowFlower
    case flowerBed
    case mushroomPatch
    case reedCluster
    case stump
    case fallenLog
    case smallRock
    case largeRock

    // Structure / man-made props
    case signpost
    case bench
    case fenceShort
    case crate
    case lantern
    case mailbox
    case stoneWell
    case bridgeShort
    case gate
    case shrineSmall
    case tinyShed
    case kiosk
    case house
    case mansion
    case japaneseHouse
    case japaneseSmallHouse
    case pagoda
    case torii
    case dock
    case lowWall
    case japaneseBridge
    case stoneLanternJp
    case car
    case orangeTruck
    case billboard
    case windmill
}

struct PropPlacement: Hashable, Codable {
    let kind: PropKind
    let coord: MapCoord
}

extension PropKind {
    var isBlockingForPet: Bool {
        switch self {
        case .tree, .rock, .log, .fence,
             .roundTree, .tallTree, .bigTree, .cherryTree, .weepingCherry,
             .cherryClump, .sacredEvergreen, .gardenPine, .tallPine, .dwarfPine,
             .denseBush, .bushDense, .stump, .fallenLog, .largeRock,
             .bench, .fenceShort, .crate, .mailbox, .stoneWell, .bridgeShort,
             .gate, .shrineSmall, .tinyShed, .kiosk, .house, .mansion,
             .japaneseHouse, .japaneseSmallHouse, .pagoda, .torii, .dock,
             .lowWall, .japaneseBridge, .stoneLanternJp, .car, .orangeTruck,
             .billboard, .windmill:
            return true
        default:
            return false
        }
    }

    var isTreeLike: Bool {
        switch self {
        case .tree, .roundTree, .tallTree, .bigTree, .cherryTree, .weepingCherry,
             .cherryClump, .sacredEvergreen, .gardenPine, .tallPine, .dwarfPine:
            return true
        default:
            return false
        }
    }

    var isSignLike: Bool {
        self == .sign || self == .signpost
    }

    var isMushroomLike: Bool {
        self == .mushroomPatch
    }
}
