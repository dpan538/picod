import Foundation

enum PicodMemoryExporter {
    static func makeLifeAlbum(
        ids: PicodMemoryIDs,
        records: [DailyLifeRecord],
        endedAt: Date,
        storyCards: [StoryCard],
        closingDiaryText: String?
    ) -> LifeAlbum {
        let ordered = records.sorted { $0.dayIndexInLife < $1.dayIndexInLife }
        let firstDate = ordered.first?.createdAt ?? endedAt
        let hatchSeedID = ordered.first(where: { $0.didCapturePhoto })?.selectedSeedID
        let finalRecord = ordered.last(where: { $0.picoGenomeAfter != nil }) ?? ordered.last
        let traits = recurringTraits(from: ordered)
        let unlockedStoryCardIDs = storyCards
            .filter { $0.displayState != .locked }
            .map(\.id)
            .sorted()

        return LifeAlbum(
            id: "album:\(ids.lifeID.rawValue)",
            lifeID: ids.lifeID,
            cycleID: ids.cycleID,
            eraID: ids.eraID,
            startedAt: firstDate,
            endedAt: endedAt,
            dayRecords: fillSevenSlots(records: ordered, ids: ids, fallbackDate: endedAt),
            hatchSeedID: hatchSeedID,
            finalRenderedFormID: finalRecord?.renderedFormID,
            finalGenome: finalRecord?.picoGenomeAfter,
            dominantLifeMood: dominantMood(from: ordered),
            recurringTraits: traits,
            unlockedStoryCardIDs: unlockedStoryCardIDs,
            closingDiaryText: closingDiaryText,
            returnToEggRecord: finalRecord,
            coverSnapshot: LifeAlbumCoverSnapshot(
                photoSnapshotID: finalRecord?.photoSnapshotID,
                renderedFormID: finalRecord?.renderedFormID,
                accentHex: finalRecord?.picoGenomeAfter?.accentColor,
                title: "Life \(ids.lifeID.rawValue)"
            )
        )
    }

    static func makeCycleRecord(
        ids: PicodMemoryIDs,
        albums: [LifeAlbum],
        endedAt: Date,
        worldSeed: WorldSeed?,
        storyCards: [StoryCard]
    ) -> CycleRecord {
        let ordered = albums.sorted { $0.startedAt < $1.startedAt }
        let startedAt = ordered.first?.startedAt ?? endedAt
        let participation = ordered.map { album in
            "\(album.dayRecords.filter(\.didCapturePhoto).count)/7"
        }
        let toriiCount = max(0, ordered.count - 1) + Int((worldSeed?.toriiProbabilityBonus ?? 0) * 3)
        let unlocked = storyCards
            .filter { $0.displayState != .locked }
            .map(\.id)
            .sorted()
        let unresolved = storyCards
            .filter { $0.displayState == .traceSeen || $0.displayState == .encountered }
            .map(\.id)
            .sorted()

        return CycleRecord(
            id: "cycle-record:\(ids.cycleID.rawValue)",
            cycleID: ids.cycleID,
            eraID: ids.eraID,
            cycleIndexInEra: ids.cycleIndexInEra,
            startedAt: startedAt,
            endedAt: endedAt,
            lifeAlbumIDs: ordered.map(\.id),
            participationPattern: participation,
            worldSeedID: worldSeed?.generationId,
            mapTemplateID: worldSeed.map { "template:\($0.personalityTerrainTag.rawValue)" },
            toriiCount: toriiCount,
            weatherPatternSummary: weatherSummary(from: ordered),
            timeOfDayPatternSummary: "The week kept a local daily rhythm.",
            visitorSummary: visitorSummary(from: ordered),
            unlockedStoryCardIDs: unlocked,
            unresolvedAnomalyIDs: unresolved,
            cycleSummaryText: cycleSummary(from: ordered, toriiCount: toriiCount)
        )
    }

    static func makeEraMemory(
        eraID: EraID,
        cycleRecords: [CycleRecord],
        albums: [LifeAlbum],
        storyCards: [StoryCard],
        endedAt: Date
    ) -> EraMemory {
        let orderedCycles = cycleRecords.sorted { $0.startedAt < $1.startedAt }
        let startedAt = orderedCycles.first?.startedAt ?? albums.map(\.startedAt).min() ?? endedAt
        let persistent = storyCards
            .filter { $0.isEraRelevant || $0.displayState == .recurring || $0.displayState == .remembered }
            .map(\.id)
            .sorted()
        let vanished = storyCards
            .filter { $0.displayState == .traceSeen || $0.displayState == .encountered }
            .map(\.id)
            .sorted()
        let mikoTraceLevel = storyCards.first(where: { $0.storylineID == NarrativeCharacterKind.mirrorMiko.rawValue })?.unlockedVisualLevel ?? 0

        return EraMemory(
            id: "era-memory:\(eraID.rawValue)",
            eraID: eraID,
            startedAt: startedAt,
            endedAt: endedAt,
            cycleRecordIDs: orderedCycles.map(\.id),
            lifeAlbumIDs: albums.sorted { $0.startedAt < $1.startedAt }.map(\.id),
            persistentStoryCardIDs: persistent,
            vanishedStoryCardIDs: vanished,
            worldResetSignature: resetSignature(eraID: eraID, cycleRecords: orderedCycles),
            mikoTraceLevel: mikoTraceLevel,
            memoryText: "The map kept more than it said. A few traces remained after the last light changed.",
            postResetEchoes: persistent.prefix(4).map { "echo:\($0)" }
        )
    }

    private static func fillSevenSlots(records: [DailyLifeRecord], ids: PicodMemoryIDs, fallbackDate: Date) -> [DailyLifeRecord] {
        let keyed = Dictionary(records.map { ($0.dayIndexInLife.rawValue, $0) }, uniquingKeysWith: { first, _ in first })
        return (1...7).map { day in
            keyed[day] ?? DailyLifeRecord(
                id: "\(ids.lifeID.rawValue):day\(day)",
                localDayKey: PicodDayKey(rawValue: "\(ids.lifeID.rawValue)-missed-\(day)"),
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
                createdAt: fallbackDate
            )
        }
    }

    private static func recurringTraits(from records: [DailyLifeRecord]) -> [String] {
        var counts: [String: Int] = [:]
        for genome in records.compactMap(\.picoGenomeAfter) {
            counts[genome.baseBody, default: 0] += 1
            counts[genome.textureTrait, default: 0] += 1
            if let scar = genome.memoryScar {
                counts[scar, default: 0] += 1
            }
        }
        return counts
            .sorted {
                if $0.value != $1.value { return $0.value > $1.value }
                return $0.key < $1.key
            }
            .prefix(5)
            .map(\.key)
    }

    private static func dominantMood(from records: [DailyLifeRecord]) -> String {
        let moods = records.compactMap(\.mapMood)
        guard !moods.isEmpty else { return "quiet" }
        let counts = Dictionary(grouping: moods, by: { $0 }).mapValues(\.count)
        return counts.sorted {
            if $0.value != $1.value { return $0.value > $1.value }
            return $0.key < $1.key
        }.first?.key ?? "quiet"
    }

    private static func weatherSummary(from albums: [LifeAlbum]) -> String {
        let moods = albums.flatMap { $0.dayRecords.compactMap(\.mapMood) }
        if moods.contains(where: { $0.contains("rain") }) {
            return "Rain or mist returned more than once."
        }
        if moods.contains(where: { $0.contains("night") }) {
            return "Night traces shaped the world rhythm."
        }
        return "The weather stayed quiet enough for small changes to show."
    }

    private static func visitorSummary(from albums: [LifeAlbum]) -> String {
        let storyIDs = albums.flatMap(\.unlockedStoryCardIDs)
        guard !storyIDs.isEmpty else {
            return "No visitor became loud; the map kept only small marks."
        }
        return "Recurring traces: " + Array(Set(storyIDs)).sorted().prefix(3).joined(separator: ", ")
    }

    private static func cycleSummary(from albums: [LifeAlbum], toriiCount: Int) -> String {
        let captures = albums.flatMap(\.dayRecords).filter(\.didCapturePhoto).count
        return "This cycle held \(captures) captured days and \(toriiCount) quiet world marker(s)."
    }

    private static func resetSignature(eraID: EraID, cycleRecords: [CycleRecord]) -> String {
        let basis = ([eraID.rawValue] + cycleRecords.map(\.id)).joined(separator: "|")
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in basis.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }
}
