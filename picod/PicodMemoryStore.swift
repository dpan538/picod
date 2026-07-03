import Combine
import Foundation

struct PicodAtomicJSON {
    static func appSupportDirectory() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("picod", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func fileURL(named filename: String) -> URL {
        appSupportDirectory().appendingPathComponent(filename)
    }

    static func load<T: Decodable>(
        _ type: T.Type,
        from url: URL,
        decoder: JSONDecoder = PicodAtomicJSON.decoder()
    ) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    static func save<T: Encodable>(
        _ value: T,
        to url: URL,
        encoder: JSONEncoder = PicodAtomicJSON.encoder()
    ) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

struct PicodMemoryIndexEnvelope: Codable, Hashable {
    var schemaVersion: Int? = 1
    var index: PicodMemoryIndex
    var dailyRecords: [DailyLifeRecord]
}

@MainActor
final class PicodMemoryStore: ObservableObject {
    @Published private(set) var index = PicodMemoryIndex()
    @Published private(set) var dailyRecords: [DailyLifeRecord] = []

    let lifeAlbumStore: LifeAlbumStore
    let cycleRecordStore: CycleRecordStore
    let storyCardStore: StoryCardStore
    let eraMemoryStore: EraMemoryStore

    private let fileURL: URL

    init(
        fileURL: URL? = nil,
        lifeAlbumStore: LifeAlbumStore? = nil,
        cycleRecordStore: CycleRecordStore? = nil,
        storyCardStore: StoryCardStore? = nil,
        eraMemoryStore: EraMemoryStore? = nil
    ) {
        self.fileURL = fileURL ?? PicodAtomicJSON.fileURL(named: "picod_memory_index.json")
        self.lifeAlbumStore = lifeAlbumStore ?? LifeAlbumStore()
        self.cycleRecordStore = cycleRecordStore ?? CycleRecordStore()
        self.storyCardStore = storyCardStore ?? StoryCardStore()
        self.eraMemoryStore = eraMemoryStore ?? EraMemoryStore()
        load()
    }

    var lifeAlbums: [LifeAlbum] { lifeAlbumStore.albums }
    var cycleRecords: [CycleRecord] { cycleRecordStore.records }
    var storyCards: [StoryCard] { storyCardStore.cards }
    var eraMemories: [EraMemory] { eraMemoryStore.memories }

    func currentLifeRecords(lifeID: LifeID) -> [DailyLifeRecord] {
        dailyRecords
            .filter { $0.lifeID == lifeID }
            .sorted { $0.dayIndexInLife < $1.dayIndexInLife }
    }

    func lifeAlbum(for lifeID: LifeID) -> LifeAlbum? {
        lifeAlbumStore.albums.first { $0.lifeID == lifeID }
    }

    func cycleRecord(for cycleID: CycleID) -> CycleRecord? {
        cycleRecordStore.records.first { $0.cycleID == cycleID }
    }

    func eraMemory(for eraID: EraID) -> EraMemory? {
        eraMemoryStore.memories.first { $0.eraID == eraID }
    }

    @discardableResult
    func recordDailyCapture(
        progress: PicodProgressRecord,
        snapshot: PhotoTraitSnapshot,
        seedMatch: PhotoSeedMatch,
        evolution: PicoEvolutionDecision,
        worldSeed: WorldSeed?,
        storyBundle: PicodStoryEventBundle,
        mapMood: String?,
        createdAt: Date
    ) -> DailyLifeRecord {
        let ids = Self.ids(from: progress)
        let recordID = "\(ids.lifeID.rawValue):day\(progress.dayInCycle)"
        let record = DailyLifeRecord(
            id: recordID,
            localDayKey: PicodDayKey(rawValue: progress.calendarDayKey),
            lifeID: ids.lifeID,
            cycleID: ids.cycleID,
            eraID: ids.eraID,
            dayIndexInLife: DayIndexInLife(progress.dayInCycle),
            didCapturePhoto: true,
            photoSnapshotID: snapshot.dayKey,
            selectedSeedID: seedMatch.selectedSeedID,
            seedMatchConfidence: seedMatch.confidence,
            picoGenomeBefore: evolution.genomeBefore,
            picoGenomeAfter: evolution.genomeAfter,
            renderedFormID: evolution.renderedFormID,
            mapSeedID: worldSeed?.generationId,
            mapMood: mapMood,
            diaryEntryID: "diary:\(recordID)",
            storyBeatIDs: storyBundle.beats.map(\.id),
            storyTraceIDs: storyBundle.mapTraces.map(\.id),
            createdAt: createdAt
        )
        upsertDailyRecord(record)
        storyCardStore.apply(progressions: storyBundle.cardProgressions, fallbackRecordID: record.id, at: createdAt)
        refreshIndex()
        save()
        objectWillChange.send()
        return record
    }

    func recordMissingDay(progress: PicodProgressRecord, createdAt: Date) {
        let ids = Self.ids(from: progress)
        let recordID = "\(ids.lifeID.rawValue):day\(progress.dayInCycle)"
        if dailyRecords.contains(where: { $0.id == recordID && $0.didCapturePhoto }) {
            return
        }
        let record = Self.makeMissingRecord(
            id: recordID,
            localDayKey: PicodDayKey(rawValue: progress.calendarDayKey),
            ids: ids,
            day: progress.dayInCycle,
            createdAt: createdAt
        )
        upsertDailyRecord(record)
        refreshIndex()
        save()
        objectWillChange.send()
    }

    @discardableResult
    func ensureLifePlaceholders(progress: PicodProgressRecord, now: Date) -> [DailyLifeRecord] {
        let ids = Self.ids(from: progress)
        let desired = sevenDayRecords(for: ids, endingAt: now)
        var didAddPlaceholder = false
        for record in desired where !dailyRecords.contains(where: { $0.id == record.id }) {
            upsertDailyRecord(record)
            didAddPlaceholder = true
        }
        if didAddPlaceholder {
            refreshIndex()
            save()
            objectWillChange.send()
        }
        return currentLifeRecords(lifeID: ids.lifeID)
    }

    func closeLifeIfReady(
        progress: PicodProgressRecord,
        now: Date,
        closingDiaryText: String?
    ) -> LifeAlbum? {
        guard progress.dayInCycle == 7 else { return nil }
        let ids = Self.ids(from: progress)
        let records = ensureLifePlaceholders(progress: progress, now: now)
        guard records.count == 7 else { return nil }
        if let existing = lifeAlbum(for: ids.lifeID) {
            return existing
        }

        let album = PicodMemoryExporter.makeLifeAlbum(
            ids: ids,
            records: records,
            endedAt: now,
            storyCards: storyCardStore.cards,
            closingDiaryText: closingDiaryText
        )
        lifeAlbumStore.upsert(album)
        refreshIndex()
        save()
        objectWillChange.send()
        return album
    }

    func closeCycleIfReady(progress: PicodProgressRecord, now: Date, worldSeed: WorldSeed?) -> CycleRecord? {
        guard progress.dayInCycle == 7 else { return nil }
        let ids = Self.ids(from: progress)
        if let existing = cycleRecord(for: ids.cycleID) {
            return existing
        }
        let albums = lifeAlbumStore.albums
            .filter { $0.cycleID == ids.cycleID }
            .sorted { $0.startedAt < $1.startedAt }
        guard !albums.isEmpty else { return nil }

        let record = PicodMemoryExporter.makeCycleRecord(
            ids: ids,
            albums: albums,
            endedAt: now,
            worldSeed: worldSeed,
            storyCards: storyCardStore.cards
        )
        cycleRecordStore.upsert(record)
        refreshIndex()
        save()
        objectWillChange.send()
        return record
    }

    func closeEraIfReady(progress: PicodProgressRecord, now: Date) -> EraMemory? {
        guard progress.isEraFinalDay, progress.dayInCycle == 7 else { return nil }
        let ids = Self.ids(from: progress)
        if let existing = eraMemory(for: ids.eraID) {
            return existing
        }
        let cycleRecords = cycleRecordStore.records.filter { $0.eraID == ids.eraID }
        guard cycleRecords.count >= 7 else { return nil }
        let albums = lifeAlbumStore.albums.filter { $0.eraID == ids.eraID }
        let memory = PicodMemoryExporter.makeEraMemory(
            eraID: ids.eraID,
            cycleRecords: cycleRecords,
            albums: albums,
            storyCards: storyCardStore.cards,
            endedAt: now
        )
        eraMemoryStore.upsert(memory)
        refreshIndex()
        save()
        objectWillChange.send()
        return memory
    }

    func resetAll() {
        index = PicodMemoryIndex()
        dailyRecords = []
        lifeAlbumStore.resetAll()
        cycleRecordStore.resetAll()
        storyCardStore.resetAll()
        eraMemoryStore.resetAll()
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func upsertDailyRecord(_ record: DailyLifeRecord) {
        if let index = dailyRecords.firstIndex(where: { $0.id == record.id }) {
            dailyRecords[index] = record
        } else {
            dailyRecords.append(record)
        }
        dailyRecords.sort {
            if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
            return $0.id < $1.id
        }
        if dailyRecords.count > 420 {
            dailyRecords.removeFirst(dailyRecords.count - 420)
        }
    }

    private func sevenDayRecords(for ids: PicodMemoryIDs, endingAt now: Date) -> [DailyLifeRecord] {
        let existing = Dictionary(uniqueKeysWithValues: dailyRecords.filter { $0.lifeID == ids.lifeID }.map { ($0.dayIndexInLife.rawValue, $0) })
        return (1...7).map { day in
            if let record = existing[day] { return record }
            return Self.makeMissingRecord(
                id: "\(ids.lifeID.rawValue):day\(day)",
                localDayKey: PicodDayKey(rawValue: "\(ids.lifeID.rawValue)-missing-\(day)"),
                ids: ids,
                day: day,
                createdAt: now
            )
        }
    }

    private static func makeMissingRecord(
        id: String,
        localDayKey: PicodDayKey,
        ids: PicodMemoryIDs,
        day: Int,
        createdAt: Date
    ) -> DailyLifeRecord {
        DailyLifeRecord(
            id: id,
            localDayKey: localDayKey,
            lifeID: ids.lifeID,
            cycleID: ids.cycleID,
            eraID: ids.eraID,
            dayIndexInLife: DayIndexInLife(day),
            didCapturePhoto: false,
            photoSnapshotID: nil,
            selectedSeedID: nil,
            seedMatchConfidence: nil,
            picoGenomeBefore: nil,
            picoGenomeAfter: nil,
            renderedFormID: nil,
            mapSeedID: nil,
            mapMood: "quiet",
            diaryEntryID: nil,
            storyBeatIDs: [],
            storyTraceIDs: [],
            createdAt: createdAt
        )
    }

    private func load() {
        guard let envelope = PicodAtomicJSON.load(PicodMemoryIndexEnvelope.self, from: fileURL) else {
            index = PicodMemoryIndex()
            dailyRecords = []
            return
        }
        index = envelope.index
        dailyRecords = envelope.dailyRecords
    }

    private func save() {
        refreshIndex()
        PicodAtomicJSON.save(PicodMemoryIndexEnvelope(index: index, dailyRecords: dailyRecords), to: fileURL)
    }

    private func refreshIndex() {
        index = PicodMemoryIndex(
            dailyRecordIDs: dailyRecords.map(\.id),
            lifeAlbumIDs: lifeAlbumStore.albums.map(\.id),
            cycleRecordIDs: cycleRecordStore.records.map(\.id),
            storyCardIDs: storyCardStore.cards.map(\.id),
            eraMemoryIDs: eraMemoryStore.memories.map(\.id),
            lastUpdatedAt: Date()
        )
    }

    static func ids(from progress: PicodProgressRecord) -> PicodMemoryIDs {
        let eraID = EraID(rawValue: progress.eraId)
        let cycleID = CycleID(rawValue: "\(progress.eraId)-cycle-\(progress.cycleIndex)")
        let lifeID = LifeID(rawValue: progress.generationId.isEmpty ? "\(cycleID.rawValue)-life-\(progress.dayInCycle)" : progress.generationId)
        return PicodMemoryIDs(
            lifeID: lifeID,
            cycleID: cycleID,
            eraID: eraID,
            cycleIndexInEra: CycleIndexInEra(progress.cycleIndex)
        )
    }
}

struct PicodMemoryIDs: Hashable {
    let lifeID: LifeID
    let cycleID: CycleID
    let eraID: EraID
    let cycleIndexInEra: CycleIndexInEra
}
