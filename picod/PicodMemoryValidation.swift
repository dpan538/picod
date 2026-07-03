import Foundation

enum PicodMemoryValidation {
    static func validateLifeAlbum(_ album: LifeAlbum) -> [String] {
        var issues: [String] = []
        let days = album.dayRecords.map(\.dayIndexInLife.rawValue)
        if album.dayRecords.count != 7 {
            issues.append("LifeAlbum \(album.id) has \(album.dayRecords.count) day records, expected 7")
        }
        if Set(days) != Set(1...7) {
            issues.append("LifeAlbum \(album.id) does not contain exactly day slots 1...7")
        }
        if album.dayRecords.contains(where: { $0.lifeID != album.lifeID || $0.cycleID != album.cycleID || $0.eraID != album.eraID }) {
            issues.append("LifeAlbum \(album.id) contains records from another Life/Cycle/Era")
        }
        if album.finalGenome == nil, album.dayRecords.contains(where: \.didCapturePhoto) {
            issues.append("LifeAlbum \(album.id) captured photos but has no final genome")
        }
        return issues
    }

    static func validateCycleRecord(_ record: CycleRecord, albums: [LifeAlbum]) -> [String] {
        var issues: [String] = []
        let expectedAlbumIDs = albums
            .filter { $0.cycleID == record.cycleID }
            .map(\.id)
            .sorted()
        if record.lifeAlbumIDs.sorted() != expectedAlbumIDs {
            issues.append("CycleRecord \(record.id) album IDs do not match completed albums")
        }
        if record.lifeAlbumIDs.isEmpty {
            issues.append("CycleRecord \(record.id) has no LifeAlbum IDs")
        }
        if record.cycleIndexInEra.rawValue < 1 || record.cycleIndexInEra.rawValue > 7 {
            issues.append("CycleRecord \(record.id) cycleIndexInEra is outside 1...7")
        }
        return issues
    }

    static func validateStoryCard(_ card: StoryCard) -> [String] {
        var issues: [String] = []
        if Set(card.evidenceDailyRecordIDs).count != card.evidenceDailyRecordIDs.count {
            issues.append("StoryCard \(card.id) has duplicate daily evidence IDs")
        }
        if Set(card.diaryEntryIDs).count != card.diaryEntryIDs.count {
            issues.append("StoryCard \(card.id) has duplicate diary entry IDs")
        }
        if Set(card.mapTraceIDs).count != card.mapTraceIDs.count {
            issues.append("StoryCard \(card.id) has duplicate map trace IDs")
        }
        if card.recurrenceCount < 0 {
            issues.append("StoryCard \(card.id) has a negative recurrence count")
        }
        return issues
    }

    static func validateEraMemory(_ memory: EraMemory, cycleRecords: [CycleRecord]) -> [String] {
        var issues: [String] = []
        let matchingCycles = cycleRecords.filter { $0.eraID == memory.eraID }
        if matchingCycles.count < 7 {
            issues.append("EraMemory \(memory.id) unlocked with fewer than 7 cycle records")
        }
        if memory.cycleRecordIDs.count < 7 {
            issues.append("EraMemory \(memory.id) stores fewer than 7 cycle record IDs")
        }
        return issues
    }

    static func validateMemoryIndex(
        _ index: PicodMemoryIndex,
        dailyRecords: [DailyLifeRecord],
        albums: [LifeAlbum],
        cycleRecords: [CycleRecord],
        storyCards: [StoryCard],
        eraMemories: [EraMemory]
    ) -> [String] {
        var issues: [String] = []
        if index.dailyRecordIDs != dailyRecords.map(\.id) {
            issues.append("Memory index dailyRecordIDs are stale")
        }
        if index.lifeAlbumIDs != albums.map(\.id) {
            issues.append("Memory index lifeAlbumIDs are stale")
        }
        if index.cycleRecordIDs != cycleRecords.map(\.id) {
            issues.append("Memory index cycleRecordIDs are stale")
        }
        if index.storyCardIDs != storyCards.map(\.id) {
            issues.append("Memory index storyCardIDs are stale")
        }
        if index.eraMemoryIDs != eraMemories.map(\.id) {
            issues.append("Memory index eraMemoryIDs are stale")
        }
        return issues
    }
}
