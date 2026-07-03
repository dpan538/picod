import Foundation

struct PicodLifecycleReconciliationResult: Codable, Hashable {
    var schemaVersion: Int? = 1
    let closedLifeAlbumIDs: [String]
    let closedCycleRecordIDs: [String]
    let closedEraMemoryIDs: [String]
    let didReturnToEgg: Bool
    let placeholderDailyRecordCount: Int
    let notes: [String]

    static let empty = PicodLifecycleReconciliationResult(
        closedLifeAlbumIDs: [],
        closedCycleRecordIDs: [],
        closedEraMemoryIDs: [],
        didReturnToEgg: false,
        placeholderDailyRecordCount: 0,
        notes: []
    )
}

@MainActor
struct PicodLifecycleReconciler {
    func reconcile(
        now: Date,
        timezoneIdentifier: String,
        languageCode: String,
        latestFormID: Int,
        progressStore: PicodProgressStore,
        memoryStore: PicodMemoryStore,
        worldSeedDatabase: WorldSeedDatabase,
        diaryDatabase: PicoDiaryDatabase,
        preferredGenerationID: String?
    ) -> PicodLifecycleReconciliationResult {
        let currentProgress = progressStore.ensureToday(
            now: now,
            timezoneIdentifier: timezoneIdentifier,
            preferredGenerationId: preferredGenerationID
        )
        let resolver = PicodCalendarResolver(timezoneIdentifier: timezoneIdentifier)
        let candidates = progressStore.records
            .sorted { lhs, rhs in
                if lhs.dayStartAt != rhs.dayStartAt { return lhs.dayStartAt < rhs.dayStartAt }
                return lhs.calendarDayKey < rhs.calendarDayKey
            }
            .filter { progress in
                guard progress.dayInCycle == 7 else { return false }
                if progress.finalizedAt != nil { return true }
                return progress.calendarDayKey == currentProgress.calendarDayKey
                    && resolver.shouldCloseLife(at: now)
            }

        guard !candidates.isEmpty else { return .empty }

        var closedLifeAlbumIDs: [String] = []
        var closedCycleRecordIDs: [String] = []
        var closedEraMemoryIDs: [String] = []
        var placeholderCount = 0
        var notes: [String] = []

        for progress in candidates {
            let ids = PicodMemoryStore.ids(from: progress)
            let beforeRecordCount = memoryStore.currentLifeRecords(lifeID: ids.lifeID).count
            _ = memoryStore.ensureLifePlaceholders(progress: progress, now: progress.finalizedAt ?? now)
            let afterRecordCount = memoryStore.currentLifeRecords(lifeID: ids.lifeID).count
            placeholderCount += max(0, afterRecordCount - beforeRecordCount)

            let didNeedLifeAlbum = memoryStore.lifeAlbum(for: ids.lifeID) == nil
            let didNeedCycleRecord = memoryStore.cycleRecord(for: ids.cycleID) == nil
            let didNeedEraMemory = progress.isEraFinalDay && memoryStore.eraMemory(for: ids.eraID) == nil

            if let album = memoryStore.closeLifeIfReady(
                progress: progress,
                now: progress.finalizedAt ?? now,
                closingDiaryText: closingDiaryText(
                    for: progress,
                    now: now,
                    timezoneIdentifier: timezoneIdentifier,
                    languageCode: languageCode,
                    latestFormID: latestFormID,
                    diaryDatabase: diaryDatabase
                )
            ), didNeedLifeAlbum {
                closedLifeAlbumIDs.append(album.id)
            }

            let worldSeed = worldSeedDatabase.load(generationId: progress.generationId)
            if let record = memoryStore.closeCycleIfReady(
                progress: progress,
                now: progress.finalizedAt ?? now,
                worldSeed: worldSeed
            ), didNeedCycleRecord {
                closedCycleRecordIDs.append(record.id)
            }

            if let era = memoryStore.closeEraIfReady(
                progress: progress,
                now: progress.finalizedAt ?? now
            ), didNeedEraMemory {
                closedEraMemoryIDs.append(era.id)
            }

            notes.append("reconciled:\(ids.lifeID.rawValue)")
        }

        return PicodLifecycleReconciliationResult(
            closedLifeAlbumIDs: closedLifeAlbumIDs,
            closedCycleRecordIDs: closedCycleRecordIDs,
            closedEraMemoryIDs: closedEraMemoryIDs,
            didReturnToEgg: !closedLifeAlbumIDs.isEmpty,
            placeholderDailyRecordCount: placeholderCount,
            notes: notes
        )
    }

    private func closingDiaryText(
        for progress: PicodProgressRecord,
        now: Date,
        timezoneIdentifier: String,
        languageCode: String,
        latestFormID: Int,
        diaryDatabase: PicoDiaryDatabase
    ) -> String? {
        diaryDatabase.story(
            for: progress.finalizedAt ?? now,
            timezoneIdentifier: timezoneIdentifier,
            languageCode: languageCode,
            formId: latestFormID
        )
    }
}
