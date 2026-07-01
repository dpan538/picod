import Foundation

enum ParticipationLevel: String, Codable {
    case full
    case partial
    case minimal
    case absent
}

struct GenerationParticipation: Equatable {
    let daysPhotographed: Int
    let consecutiveDays: Int
    let firstDayParticipated: Bool

    var level: ParticipationLevel {
        if daysPhotographed == 7 { return .full }
        if daysPhotographed >= 2 { return .partial }
        if firstDayParticipated { return .minimal }
        return .absent
    }
}

struct ParticipationHistoryEntry: Equatable {
    let cycleId: Int
    let roundIndex: Int
    let generationId: String?
    let participation: GenerationParticipation

    var level: ParticipationLevel { participation.level }
}

@MainActor
struct WorldParticipationEngine {
    let snapshotDatabase: PhotoTraitSnapshotDatabase

    init(snapshotDatabase: PhotoTraitSnapshotDatabase) {
        self.snapshotDatabase = snapshotDatabase
    }

    func participation(for generationId: String) -> GenerationParticipation {
        let generationSnapshots = snapshotDatabase.snapshots(for: generationId)
        let daySet = Set(
            generationSnapshots
                .map(\.dayIndex)
                .filter { (1...7).contains($0) }
        )

        return GenerationParticipation(
            daysPhotographed: daySet.count,
            consecutiveDays: longestConsecutiveDays(in: daySet),
            firstDayParticipated: daySet.contains(1)
        )
    }

    // A cycle consists of 7 generations. This returns 7 slots for the requested cycle.
    // Missing future/empty slots are represented as .absent with nil generationId.
    func participationHistory(for cycleId: Int) -> [ParticipationHistoryEntry] {
        let normalizedCycleId = max(1, cycleId)
        let orderedGenerationIds = generationIdsOrderedByRecencyAscending()
        let cycleStart = (normalizedCycleId - 1) * 7

        return (0..<7).map { index in
            let generationIndex = cycleStart + index
            let generationId = generationIndex < orderedGenerationIds.count
                ? orderedGenerationIds[generationIndex]
                : nil

            let participation = generationId.map { self.participation(for: $0) }
                ?? GenerationParticipation(
                    daysPhotographed: 0,
                    consecutiveDays: 0,
                    firstDayParticipated: false
                )

            return ParticipationHistoryEntry(
                cycleId: normalizedCycleId,
                roundIndex: index + 1,
                generationId: generationId,
                participation: participation
            )
        }
    }

    private func generationIdsOrderedByRecencyAscending() -> [String] {
        let grouped = Dictionary(grouping: snapshotDatabase.snapshots, by: \.generationId)
        return grouped.keys.sorted { lhs, rhs in
            let lhsTime = grouped[lhs]?.map(\.timestamp).max() ?? .distantPast
            let rhsTime = grouped[rhs]?.map(\.timestamp).max() ?? .distantPast
            if lhsTime == rhsTime {
                return lhs < rhs
            }
            return lhsTime < rhsTime
        }
    }

    private func longestConsecutiveDays(in daySet: Set<Int>) -> Int {
        guard !daySet.isEmpty else { return 0 }

        var longest = 0
        var current = 0
        for day in 1...7 {
            if daySet.contains(day) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }
        return longest
    }
}
