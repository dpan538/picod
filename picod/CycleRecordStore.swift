import Combine
import Foundation

@MainActor
final class CycleRecordStore: ObservableObject {
    @Published private(set) var records: [CycleRecord] = []

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? PicodAtomicJSON.fileURL(named: "cycle_records_db.json")
        load()
    }

    func upsert(_ record: CycleRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
        records.sort { $0.endedAt < $1.endedAt }
        if records.count > 60 {
            records.removeFirst(records.count - 60)
        }
        save()
    }

    func resetAll() {
        records = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func load() {
        records = PicodAtomicJSON.load([CycleRecord].self, from: fileURL) ?? []
    }

    private func save() {
        PicodAtomicJSON.save(records, to: fileURL)
    }
}
