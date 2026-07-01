import Foundation

enum AnimalKind: String, CaseIterable, Codable {
    case bird
    case duck
    case rabbit
    case cat
    case dog
    case deer
    case frog
    case butterfly
    case snail
    case fishShadow
}

struct AnimalPlacement: Hashable, Codable {
    let kind: AnimalKind
    let coord: MapCoord
}
