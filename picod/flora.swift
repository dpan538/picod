import Foundation

enum FloraKind: String, CaseIterable, Codable {
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

    var propKind: PropKind {
        switch self {
        case .roundTree: return .roundTree
        case .tallTree: return .tallTree
        case .smallBush: return .smallBush
        case .denseBush: return .denseBush
        case .pinkFlower: return .pinkFlower
        case .yellowFlower: return .yellowFlower
        case .mushroomPatch: return .mushroomPatch
        case .reedCluster: return .reedCluster
        case .stump: return .stump
        case .fallenLog: return .fallenLog
        case .smallRock: return .smallRock
        case .largeRock: return .largeRock
        }
    }
}
