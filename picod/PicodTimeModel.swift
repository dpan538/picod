import Foundation

struct LifeID: RawRepresentable, Codable, Hashable, Identifiable, CustomStringConvertible {
    let rawValue: String
    var id: String { rawValue }
    var description: String { rawValue }
}

struct CycleID: RawRepresentable, Codable, Hashable, Identifiable, CustomStringConvertible {
    let rawValue: String
    var id: String { rawValue }
    var description: String { rawValue }
}

struct EraID: RawRepresentable, Codable, Hashable, Identifiable, CustomStringConvertible {
    let rawValue: String
    var id: String { rawValue }
    var description: String { rawValue }
}

struct PicodDayKey: RawRepresentable, Codable, Hashable, Identifiable, Comparable, CustomStringConvertible {
    let rawValue: String
    var id: String { rawValue }
    var description: String { rawValue }

    static func < (lhs: PicodDayKey, rhs: PicodDayKey) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct DayIndexInLife: RawRepresentable, Codable, Hashable, Comparable, CustomStringConvertible {
    let rawValue: Int
    var description: String { "\(rawValue)" }

    init(_ value: Int) {
        rawValue = min(7, max(1, value))
    }

    init(rawValue: Int) {
        self.init(rawValue)
    }

    static func < (lhs: DayIndexInLife, rhs: DayIndexInLife) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct CycleIndexInEra: RawRepresentable, Codable, Hashable, Comparable, CustomStringConvertible {
    let rawValue: Int
    var description: String { "\(rawValue)" }

    init(_ value: Int) {
        rawValue = min(7, max(1, value))
    }

    init(rawValue: Int) {
        self.init(rawValue)
    }

    static func < (lhs: CycleIndexInEra, rhs: CycleIndexInEra) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct EraDayIndex: RawRepresentable, Codable, Hashable, Comparable, CustomStringConvertible {
    let rawValue: Int
    var description: String { "\(rawValue)" }

    init(_ value: Int) {
        rawValue = min(49, max(1, value))
    }

    init(rawValue: Int) {
        self.init(rawValue)
    }

    static func < (lhs: EraDayIndex, rhs: EraDayIndex) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct PicodTimePosition: Codable, Hashable {
    var schemaVersion: Int? = 1
    let localDayKey: PicodDayKey
    let lifeID: LifeID
    let cycleID: CycleID
    let eraID: EraID
    let dayIndexInLife: DayIndexInLife
    let cycleIndexInEra: CycleIndexInEra
    let eraDayIndex: EraDayIndex
}
