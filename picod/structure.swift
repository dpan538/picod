import Foundation

enum StructureKind: String, CaseIterable, Codable {
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

    var propKind: PropKind {
        switch self {
        case .signpost: return .signpost
        case .bench: return .bench
        case .fenceShort: return .fenceShort
        case .crate: return .crate
        case .lantern: return .lantern
        case .mailbox: return .mailbox
        case .stoneWell: return .stoneWell
        case .bridgeShort: return .bridgeShort
        case .gate: return .gate
        case .shrineSmall: return .shrineSmall
        case .tinyShed: return .tinyShed
        case .kiosk: return .kiosk
        }
    }
}
