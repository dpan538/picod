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
    case cow
    case sheep
    case horse
    case child
    case shrineMaiden
    case caretaker
    case fisher
    case edgeTraveler
    case forestSpirit
    case truckDriver
    case nightLamplighter
    case lostBackpacker
    case umbrellaWoman
    case toriiBetweenLight
    case doorKnocker
    case mirrorMiko
}

struct AnimalPlacement: Hashable, Codable {
    let kind: AnimalKind
    let coord: MapCoord
}
