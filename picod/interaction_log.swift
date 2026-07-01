import Foundation

enum LogEntryType: String, Codable {
    case movement
    case interaction
    case checkIn
}

struct PetLogEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let timestamp: Date
    let message: String
    let type: LogEntryType

    init(id: UUID = UUID(), timestamp: Date = Date(), message: String, type: LogEntryType) {
        self.id = id
        self.timestamp = timestamp
        self.message = message
        self.type = type
    }
}
