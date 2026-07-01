import Foundation

enum PropKind: String, CaseIterable, Codable {
    // Flora / natural props
    case roundTree
    case tallTree
    case smallBush
    case denseBush
    case pinkFlower
    case yellowFlower
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
}

struct PropPlacement: Hashable, Codable {
    let kind: PropKind
    let coord: MapCoord
}

extension PropKind {
    var isBlockingForPet: Bool {
        switch self {
        case .roundTree, .tallTree, .denseBush, .stump, .fallenLog, .largeRock,
             .bench, .fenceShort, .crate, .mailbox, .stoneWell, .bridgeShort,
             .gate, .shrineSmall, .tinyShed, .kiosk:
            return true
        default:
            return false
        }
    }

    var isTreeLike: Bool {
        self == .roundTree || self == .tallTree
    }

    var isSignLike: Bool {
        self == .signpost
    }

    var isMushroomLike: Bool {
        self == .mushroomPatch
    }
}
