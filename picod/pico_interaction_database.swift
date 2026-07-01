import Foundation
import Combine

struct PicoInteractionRecord: Codable, Hashable, Identifiable {
    let id: UUID
    let timestamp: Date
    let dayKey: String
    let eventType: PetEventType
    let sourceAnimal: AnimalKind?
    let sourceProp: PropKind?
    let sourcePlace: Landform?
    let summary: String

    init(
        id: UUID = UUID(),
        timestamp: Date,
        dayKey: String,
        eventType: PetEventType,
        sourceAnimal: AnimalKind?,
        sourceProp: PropKind?,
        sourcePlace: Landform?,
        summary: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.dayKey = dayKey
        self.eventType = eventType
        self.sourceAnimal = sourceAnimal
        self.sourceProp = sourceProp
        self.sourcePlace = sourcePlace
        self.summary = summary
    }
}

@MainActor
final class PicoInteractionDatabase: ObservableObject {
    @Published private(set) var records: [PicoInteractionRecord] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        self.fileURL = Self.makeFileURL()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    @discardableResult
    func record(event: PetEvent, timezoneIdentifier: String) -> Bool {
        guard event.type != .tappedByUser else { return false }

        let day = dayKey(for: event.timestamp, timezoneIdentifier: timezoneIdentifier)
        let candidate = PicoInteractionRecord(
            timestamp: event.timestamp,
            dayKey: day,
            eventType: event.type,
            sourceAnimal: event.sourceAnimal,
            sourceProp: event.sourceProp,
            sourcePlace: event.sourcePlace,
            summary: event.summary
        )

        if let last = records.last,
           last.eventType == candidate.eventType,
           last.sourceAnimal == candidate.sourceAnimal,
           last.sourceProp == candidate.sourceProp,
           last.sourcePlace == candidate.sourcePlace,
           abs(last.timestamp.timeIntervalSince(candidate.timestamp)) < 10 {
            return false
        }

        records.append(candidate)
        if records.count > 6000 {
            records.removeFirst(records.count - 6000)
        }
        save()
        return true
    }

    func records(forDay dayKey: String) -> [PicoInteractionRecord] {
        records.filter { $0.dayKey == dayKey }
    }

    func resetAll() {
        records = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func dayKey(for date: Date, timezoneIdentifier: String) -> String {
        PicodCalendar.dayKey(for: date, timezoneIdentifier: timezoneIdentifier)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([PicoInteractionRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded
    }

    private func save() {
        guard let data = try? encoder.encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func makeFileURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("picod", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("pico_interactions_db.json")
    }
}
