import Foundation
import Combine

struct PicoDailyStorySummary: Codable, Hashable, Identifiable {
    let id: UUID
    let dayKey: String
    let languageCode: String
    let createdAt: Date
    let summaryText: String

    init(
        id: UUID = UUID(),
        dayKey: String,
        languageCode: String,
        createdAt: Date = Date(),
        summaryText: String
    ) {
        self.id = id
        self.dayKey = dayKey
        self.languageCode = languageCode
        self.createdAt = createdAt
        self.summaryText = summaryText
    }
}

@MainActor
final class PicoStorySummaryDatabase: ObservableObject {
    @Published private(set) var summaries: [PicoDailyStorySummary] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        self.fileURL = Self.makeFileURL()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    // Interface intentionally prepared for later world-lore usage.
    // Not wired into UI yet by design.
    func upsertSummary(dayKey: String, languageCode: String, summaryText: String) {
        let normalized = summaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        if let index = summaries.firstIndex(where: { $0.dayKey == dayKey && $0.languageCode == languageCode }) {
            summaries[index] = PicoDailyStorySummary(
                id: summaries[index].id,
                dayKey: dayKey,
                languageCode: languageCode,
                createdAt: Date(),
                summaryText: normalized
            )
        } else {
            summaries.append(PicoDailyStorySummary(dayKey: dayKey, languageCode: languageCode, summaryText: normalized))
        }

        if summaries.count > 180 {
            summaries.sort { $0.createdAt < $1.createdAt }
            summaries.removeFirst(summaries.count - 180)
        }
        save()
    }

    func summary(dayKey: String, languageCode: String) -> PicoDailyStorySummary? {
        summaries.first { $0.dayKey == dayKey && $0.languageCode == languageCode }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([PicoDailyStorySummary].self, from: data) else {
            summaries = []
            return
        }
        summaries = decoded
    }

    private func save() {
        guard let data = try? encoder.encode(summaries) else { return }
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
        return dir.appendingPathComponent("pico_story_summaries_db.json")
    }
}
