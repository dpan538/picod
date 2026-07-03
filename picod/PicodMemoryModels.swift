import Foundation

struct DailyLifeRecord: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: String
    let localDayKey: PicodDayKey
    let lifeID: LifeID
    let cycleID: CycleID
    let eraID: EraID
    let dayIndexInLife: DayIndexInLife
    let didCapturePhoto: Bool
    let photoSnapshotID: String?
    let selectedSeedID: String?
    let seedMatchConfidence: Double?
    let picoGenomeBefore: PicoGenome?
    let picoGenomeAfter: PicoGenome?
    let renderedFormID: Int?
    let mapSeedID: String?
    let mapMood: String?
    let diaryEntryID: String?
    let storyBeatIDs: [String]
    let storyTraceIDs: [String]
    let createdAt: Date
}

struct LifeAlbumCoverSnapshot: Codable, Hashable {
    var schemaVersion: Int? = 1
    let photoSnapshotID: String?
    let renderedFormID: Int?
    let accentHex: String?
    let title: String
}

struct LifeAlbum: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: String
    let lifeID: LifeID
    let cycleID: CycleID
    let eraID: EraID
    let startedAt: Date
    let endedAt: Date
    let dayRecords: [DailyLifeRecord]
    let hatchSeedID: String?
    let finalRenderedFormID: Int?
    let finalGenome: PicoGenome?
    let dominantLifeMood: String
    let recurringTraits: [String]
    let unlockedStoryCardIDs: [String]
    let closingDiaryText: String?
    let returnToEggRecord: DailyLifeRecord?
    let coverSnapshot: LifeAlbumCoverSnapshot?
}

struct CycleRecord: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: String
    let cycleID: CycleID
    let eraID: EraID
    let cycleIndexInEra: CycleIndexInEra
    let startedAt: Date
    let endedAt: Date
    let lifeAlbumIDs: [String]
    let participationPattern: [String]
    let worldSeedID: String?
    let mapTemplateID: String?
    let toriiCount: Int
    let weatherPatternSummary: String
    let timeOfDayPatternSummary: String
    let visitorSummary: String
    let unlockedStoryCardIDs: [String]
    let unresolvedAnomalyIDs: [String]
    let cycleSummaryText: String
}

enum StoryCardDisplayState: String, Codable, Hashable, CaseIterable {
    case locked
    case traceSeen
    case encountered
    case recurring
    case remembered
}

struct StoryCard: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: String
    let storylineID: String
    var displayState: StoryCardDisplayState
    var title: String
    var hiddenTitle: String
    var shortDescription: String
    var firstSeenAt: Date?
    var lastSeenAt: Date?
    var firstSeenLifeID: LifeID?
    var firstSeenCycleID: CycleID?
    var evidenceDailyRecordIDs: [String]
    var diaryEntryIDs: [String]
    var mapTraceIDs: [String]
    var unlockedVisualLevel: Int
    var recurrenceCount: Int
    var isEraRelevant: Bool
}

struct EraMemory: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: String
    let eraID: EraID
    let startedAt: Date
    let endedAt: Date
    let cycleRecordIDs: [String]
    let lifeAlbumIDs: [String]
    let persistentStoryCardIDs: [String]
    let vanishedStoryCardIDs: [String]
    let worldResetSignature: String
    let mikoTraceLevel: Int
    let memoryText: String
    let postResetEchoes: [String]
}

struct PicodMemoryIndex: Codable, Hashable {
    var schemaVersion: Int? = 1
    var dailyRecordIDs: [String] = []
    var lifeAlbumIDs: [String] = []
    var cycleRecordIDs: [String] = []
    var storyCardIDs: [String] = []
    var eraMemoryIDs: [String] = []
    var lastUpdatedAt: Date? = nil
}
