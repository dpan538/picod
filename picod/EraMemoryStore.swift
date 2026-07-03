import Combine
import Foundation

@MainActor
final class EraMemoryStore: ObservableObject {
    @Published private(set) var memories: [EraMemory] = []

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? PicodAtomicJSON.fileURL(named: "era_memories_db.json")
        load()
    }

    func upsert(_ memory: EraMemory) {
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[index] = memory
        } else {
            memories.append(memory)
        }
        memories.sort { $0.endedAt < $1.endedAt }
        if memories.count > 12 {
            memories.removeFirst(memories.count - 12)
        }
        save()
    }

    func resetAll() {
        memories = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func load() {
        memories = PicodAtomicJSON.load([EraMemory].self, from: fileURL) ?? []
    }

    private func save() {
        PicodAtomicJSON.save(memories, to: fileURL)
    }
}
