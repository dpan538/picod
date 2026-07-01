import Combine
import Foundation

enum PicodParticipationState: String, Codable, Hashable {
    case pending
    case captured
    case absent
}

struct PicodProgressRecord: Codable, Hashable, Identifiable {
    var id: String { calendarDayKey }

    let eraId: String
    let absoluteDayIndex: Int
    let cycleIndex: Int
    let dayInCycle: Int
    let calendarDayKey: String
    let dayStartAt: Date
    var generationId: String
    var photoSnapshotDayKey: String?
    var interactionRecordCount: Int
    var diarySummaryDayKey: String?
    var worldSeedGenerationId: String?
    var firedStoryBeatIds: [String]
    var participationState: PicodParticipationState
    let openedAt: Date
    var finalizedAt: Date?

    var isEraFinalDay: Bool { absoluteDayIndex == 49 }
}

@MainActor
final class PicodProgressStore: ObservableObject {
    @Published private(set) var records: [PicodProgressRecord] = []
    @Published private(set) var currentCalendarDayKey: String?

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var saveTask: Task<Void, Never>?

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.makeFileURL()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    var currentRecord: PicodProgressRecord? {
        guard let currentCalendarDayKey else { return nil }
        return records.first { $0.calendarDayKey == currentCalendarDayKey }
    }

    @discardableResult
    func ensureToday(
        now: Date,
        timezoneIdentifier: String,
        preferredGenerationId: String?
    ) -> PicodProgressRecord {
        let dayKey = PicodCalendar.dayKey(for: now, timezoneIdentifier: timezoneIdentifier)
        let dayStart = PicodCalendar.operationalDayStart(for: now, timezoneIdentifier: timezoneIdentifier)

        if let index = records.firstIndex(where: { $0.calendarDayKey == dayKey }) {
            currentCalendarDayKey = dayKey
            if records[index].generationId.isEmpty, let preferredGenerationId, !preferredGenerationId.isEmpty {
                records[index].generationId = preferredGenerationId
                scheduleSave()
            }
            return records[index]
        }

        let preferred = preferredGenerationId?.isEmpty == false ? preferredGenerationId! : UUID().uuidString
        _ = markElapsedOpenDaysAbsent(before: dayStart)

        if let last = records.sorted(by: sortProgressRecords).last {
            var previous = last
            var nextStart = PicodCalendar.addingOperationalDays(1, to: previous.dayStartAt, timezoneIdentifier: timezoneIdentifier)
            while nextStart < dayStart {
                let skipped = makeNextRecord(
                    after: previous,
                    dayStart: nextStart,
                    timezoneIdentifier: timezoneIdentifier,
                    fallbackGenerationId: preferred,
                    openedAt: nextStart,
                    participationState: .absent,
                    finalizedAt: PicodCalendar.addingOperationalDays(1, to: nextStart, timezoneIdentifier: timezoneIdentifier)
                )
                records.append(skipped)
                previous = skipped
                nextStart = PicodCalendar.addingOperationalDays(1, to: previous.dayStartAt, timezoneIdentifier: timezoneIdentifier)
            }

            let today = makeNextRecord(
                after: previous,
                dayStart: dayStart,
                timezoneIdentifier: timezoneIdentifier,
                fallbackGenerationId: preferred,
                openedAt: now,
                participationState: .pending,
                finalizedAt: nil
            )
            records.append(today)
            currentCalendarDayKey = dayKey
            sortRecords()
            scheduleSave()
            return today
        }

        let first = PicodProgressRecord(
            eraId: UUID().uuidString,
            absoluteDayIndex: 1,
            cycleIndex: 1,
            dayInCycle: 1,
            calendarDayKey: dayKey,
            dayStartAt: dayStart,
            generationId: preferred,
            photoSnapshotDayKey: nil,
            interactionRecordCount: 0,
            diarySummaryDayKey: nil,
            worldSeedGenerationId: nil,
            firedStoryBeatIds: [],
            participationState: .pending,
            openedAt: now,
            finalizedAt: nil
        )
        records.append(first)
        currentCalendarDayKey = dayKey
        sortRecords()
        scheduleSave()
        return first
    }

    @discardableResult
    func markCaptured(
        calendarDayKey: String,
        photoSnapshotDayKey: String,
        generationId: String
    ) -> Bool {
        guard let index = records.firstIndex(where: { $0.calendarDayKey == calendarDayKey }) else {
            return false
        }
        records[index].photoSnapshotDayKey = photoSnapshotDayKey
        records[index].generationId = generationId
        records[index].participationState = .captured
        scheduleSave()
        return true
    }

    @discardableResult
    func recordInteraction(calendarDayKey: String) -> Bool {
        guard let index = records.firstIndex(where: { $0.calendarDayKey == calendarDayKey }) else {
            return false
        }
        records[index].interactionRecordCount += 1
        scheduleSave()
        return true
    }

    @discardableResult
    func markDiarySummary(calendarDayKey: String, summaryDayKey: String) -> Bool {
        guard let index = records.firstIndex(where: { $0.calendarDayKey == calendarDayKey }) else {
            return false
        }
        records[index].diarySummaryDayKey = summaryDayKey
        scheduleSave()
        return true
    }

    @discardableResult
    func markWorldSeed(calendarDayKey: String, generationId: String) -> Bool {
        guard let index = records.firstIndex(where: { $0.calendarDayKey == calendarDayKey }) else {
            return false
        }
        records[index].worldSeedGenerationId = generationId
        scheduleSave()
        return true
    }

    @discardableResult
    func markStoryBeatsFired(calendarDayKey: String, beatIds: [String]) -> Bool {
        guard !beatIds.isEmpty,
              let index = records.firstIndex(where: { $0.calendarDayKey == calendarDayKey }) else {
            return false
        }
        var existing = Set(records[index].firedStoryBeatIds)
        for beatId in beatIds {
            existing.insert(beatId)
        }
        records[index].firedStoryBeatIds = existing.sorted()
        scheduleSave()
        return true
    }

    func recentParticipationStates(limit: Int) -> [PicodParticipationState] {
        records
            .sorted(by: sortProgressRecords)
            .suffix(max(0, limit))
            .map(\.participationState)
    }

    func resetAll() {
        saveTask?.cancel()
        records = []
        currentCalendarDayKey = nil
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func makeNextRecord(
        after previous: PicodProgressRecord,
        dayStart: Date,
        timezoneIdentifier: String,
        fallbackGenerationId: String,
        openedAt: Date,
        participationState: PicodParticipationState,
        finalizedAt: Date?
    ) -> PicodProgressRecord {
        let nextAbsolute = previous.absoluteDayIndex >= 49 ? 1 : previous.absoluteDayIndex + 1
        let eraId = previous.absoluteDayIndex >= 49 ? UUID().uuidString : previous.eraId
        let cycleIndex = ((nextAbsolute - 1) / 7) + 1
        let dayInCycle = ((nextAbsolute - 1) % 7) + 1
        let generationId = dayInCycle == 1 ? UUID().uuidString : previous.generationId
        let calendarDayKey = PicodCalendar.dayKey(for: dayStart, timezoneIdentifier: timezoneIdentifier)

        return PicodProgressRecord(
            eraId: eraId,
            absoluteDayIndex: nextAbsolute,
            cycleIndex: cycleIndex,
            dayInCycle: dayInCycle,
            calendarDayKey: calendarDayKey,
            dayStartAt: dayStart,
            generationId: generationId.isEmpty ? fallbackGenerationId : generationId,
            photoSnapshotDayKey: nil,
            interactionRecordCount: 0,
            diarySummaryDayKey: nil,
            worldSeedGenerationId: nil,
            firedStoryBeatIds: [],
            participationState: participationState,
            openedAt: openedAt,
            finalizedAt: finalizedAt
        )
    }

    private func markElapsedOpenDaysAbsent(before dayStart: Date) -> Bool {
        var didMutate = false
        for index in records.indices where records[index].dayStartAt < dayStart && records[index].finalizedAt == nil {
            if records[index].participationState == .pending {
                records[index].participationState = .absent
            }
            records[index].finalizedAt = dayStart
            didMutate = true
        }
        return didMutate
    }

    private func sortRecords() {
        records.sort(by: sortProgressRecords)
    }

    private func sortProgressRecords(_ lhs: PicodProgressRecord, _ rhs: PicodProgressRecord) -> Bool {
        if lhs.dayStartAt != rhs.dayStartAt { return lhs.dayStartAt < rhs.dayStartAt }
        return lhs.calendarDayKey < rhs.calendarDayKey
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([PicodProgressRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded.sorted(by: sortProgressRecords)
    }

    private func saveNow() {
        guard let data = try? encoder.encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard let self, !Task.isCancelled else { return }
            self.saveNow()
        }
    }

    private static func makeFileURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("picod", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("picod_progress_store.json")
    }
}
