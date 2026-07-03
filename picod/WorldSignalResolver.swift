import Foundation

@MainActor
struct WorldSignalResolver {
    func resolveToday(
        memoryStore: PicodMemoryStore,
        date: Date,
        calendar: Calendar
    ) -> WorldSignalBundle {
        let resolver = PicodCalendarResolver(timezoneIdentifier: calendar.timeZone.identifier)
        let position = resolver.timePosition(for: date)
        if let record = memoryStore.dailyRecords.first(where: { $0.localDayKey == position.localDayKey }) {
            return resolveForDailyRecord(record, memoryStore: memoryStore)
        }
        return emptyBundle(
            position: position,
            captureState: .missing,
            participationState: participationState(records: memoryStore.dailyRecords),
            memoryStore: memoryStore,
            debugSummary: "empty-today localDayKey=\(position.localDayKey.rawValue)"
        )
    }

    func resolveForDailyRecord(
        _ record: DailyLifeRecord,
        memoryStore: PicodMemoryStore
    ) -> WorldSignalBundle {
        let cycleRecord = memoryStore.cycleRecord(for: record.cycleID)
        let eraMemory = memoryStore.eraMemory(for: record.eraID)
        let cards = activeStoryCards(for: record, storyCards: memoryStore.storyCards)
        let lifeRecords = memoryStore.currentLifeRecords(lifeID: record.lifeID)
        let cycleIndex = cycleRecord?.cycleIndexInEra ?? cycleIndex(from: record.cycleID)
        let captureState: WorldCaptureState = record.didCapturePhoto ? .captured : .missing
        let evidenceIDs = evidenceIDs(for: record, storyCards: cards)
        let photoSignal = photoMoodSignal(for: record)
        let picoSignal = picoSignal(for: record)

        return WorldSignalBundle(
            id: "world-signal:\(record.id)",
            localDayKey: record.localDayKey,
            lifeID: record.lifeID,
            cycleID: record.cycleID,
            eraID: record.eraID,
            dayIndexInLife: record.dayIndexInLife,
            cycleIndexInEra: cycleIndex,
            captureState: captureState,
            participationState: participationState(records: lifeRecords),
            photoMoodSignals: [photoSignal],
            colorSignals: colorSignals(for: record, photoSignal: photoSignal),
            weatherSignals: weatherSignals(for: record),
            timeOfDaySignals: timeSignals(for: record),
            picoEvolutionSignals: picoSignal.map { [$0] } ?? [],
            storySignals: storySignals(for: cards),
            diarySignals: diarySignals(for: record, storyCards: cards),
            mapTraceSignals: record.storyTraceIDs,
            lifeAlbumSignals: lifeAlbumSignals(for: record, memoryStore: memoryStore),
            cycleSignals: cycleRecord.map { [cycleSignal(for: $0)] } ?? [],
            eraSignals: [eraSignal(for: record.eraID, eraMemory: eraMemory)],
            missingDaySignals: record.didCapturePhoto ? [] : ["missing-day:\(record.dayIndexInLife.rawValue)"],
            evidenceIDs: evidenceIDs,
            debugSummary: debugSummary(for: record, storyCards: cards)
        )
    }

    func resolveForCycle(
        _ cycle: CycleRecord,
        memoryStore: PicodMemoryStore
    ) -> WorldSignalBundle {
        let album = memoryStore.lifeAlbums.first { cycle.lifeAlbumIDs.contains($0.id) }
        let record = album?.dayRecords.last
        let eraMemory = memoryStore.eraMemory(for: cycle.eraID)
        let position = fallbackPosition(
            localDayKey: record?.localDayKey ?? PicodDayKey(rawValue: "cycle:\(cycle.id)"),
            lifeID: record?.lifeID ?? LifeID(rawValue: "\(cycle.cycleID.rawValue)-life-projection"),
            cycleID: cycle.cycleID,
            eraID: cycle.eraID,
            dayIndex: record?.dayIndexInLife ?? DayIndexInLife(7),
            cycleIndex: cycle.cycleIndexInEra
        )
        var bundle = record.map { resolveForDailyRecord($0, memoryStore: memoryStore) } ??
            emptyBundle(
                position: position,
                captureState: .closed,
                participationState: participationState(pattern: cycle.participationPattern),
                memoryStore: memoryStore,
                debugSummary: "cycle-projection \(cycle.id)"
            )
        bundle = bundle.replacing(
            cycleSignals: [cycleSignal(for: cycle)],
            eraSignals: [eraSignal(for: cycle.eraID, eraMemory: eraMemory)]
        )
        return bundle
    }

    func resolveForEra(
        _ era: EraMemory,
        memoryStore: PicodMemoryStore
    ) -> WorldSignalBundle {
        let cycle = memoryStore.cycleRecords.first { era.cycleRecordIDs.contains($0.id) }
        let album = memoryStore.lifeAlbums.first { era.lifeAlbumIDs.contains($0.id) }
        let record = album?.dayRecords.last
        let position = fallbackPosition(
            localDayKey: record?.localDayKey ?? PicodDayKey(rawValue: "era:\(era.id)"),
            lifeID: record?.lifeID ?? LifeID(rawValue: "\(era.eraID.rawValue)-life-projection"),
            cycleID: cycle?.cycleID ?? CycleID(rawValue: "\(era.eraID.rawValue)-cycle-projection"),
            eraID: era.eraID,
            dayIndex: record?.dayIndexInLife ?? DayIndexInLife(7),
            cycleIndex: cycle?.cycleIndexInEra ?? CycleIndexInEra(7)
        )
        var bundle = record.map { resolveForDailyRecord($0, memoryStore: memoryStore) } ??
            emptyBundle(
                position: position,
                captureState: .closed,
                participationState: .steady,
                memoryStore: memoryStore,
                debugSummary: "era-projection \(era.id)"
            )
        bundle = bundle.replacing(
            cycleSignals: cycle.map { [cycleSignal(for: $0)] } ?? [],
            eraSignals: [eraSignal(for: era.eraID, eraMemory: era)]
        )
        return bundle
    }

    private func emptyBundle(
        position: PicodTimePosition,
        captureState: WorldCaptureState,
        participationState: WorldParticipationState,
        memoryStore: PicodMemoryStore,
        debugSummary: String
    ) -> WorldSignalBundle {
        WorldSignalBundle(
            id: "world-signal:\(position.localDayKey.rawValue)",
            localDayKey: position.localDayKey,
            lifeID: position.lifeID,
            cycleID: position.cycleID,
            eraID: position.eraID,
            dayIndexInLife: position.dayIndexInLife,
            cycleIndexInEra: position.cycleIndexInEra,
            captureState: captureState,
            participationState: participationState,
            photoMoodSignals: [
                PhotoMoodSignal(
                    dominantColorFamily: nil,
                    brightnessBand: .balanced,
                    saturationBand: .soft,
                    semanticMoodTags: ["quiet"],
                    confidenceBand: .none
                )
            ],
            colorSignals: [],
            weatherSignals: [],
            timeOfDaySignals: [],
            picoEvolutionSignals: [],
            storySignals: storySignals(for: activeStoryCards(for: nil, storyCards: memoryStore.storyCards)),
            diarySignals: ["diary:quiet-fallback"],
            mapTraceSignals: [],
            lifeAlbumSignals: [],
            cycleSignals: [],
            eraSignals: [eraSignal(for: position.eraID, eraMemory: memoryStore.eraMemory(for: position.eraID))],
            missingDaySignals: captureState == .missing ? ["missing-day:\(position.dayIndexInLife.rawValue)"] : [],
            evidenceIDs: [],
            debugSummary: debugSummary
        )
    }

    private func photoMoodSignal(for record: DailyLifeRecord) -> PhotoMoodSignal {
        let mood = record.mapMood?.lowercased() ?? "quiet"
        return PhotoMoodSignal(
            dominantColorFamily: dominantColorFamily(from: record.picoGenomeAfter),
            brightnessBand: brightnessBand(from: mood),
            saturationBand: saturationBand(confidence: record.seedMatchConfidence),
            semanticMoodTags: semanticMoodTags(for: record),
            confidenceBand: confidenceBand(record.seedMatchConfidence)
        )
    }

    private func picoSignal(for record: DailyLifeRecord) -> PicoWorldSignal? {
        guard let genome = record.picoGenomeAfter else { return nil }
        return PicoWorldSignal(
            renderedFormID: record.renderedFormID ?? genome.renderedFormID,
            genomeTraits: [
                "baseBody": genome.baseBody,
                "coreColor": genome.coreColor,
                "accentColor": genome.accentColor,
                "headTrait": genome.headTrait,
                "appendageTrait": genome.appendageTrait,
                "eyeTrait": genome.eyeTrait,
                "textureTrait": genome.textureTrait
            ],
            changedTraits: changedTraits(before: record.picoGenomeBefore, after: genome),
            anomalyMark: genome.anomalyMark,
            memoryScar: genome.memoryScar,
            ageLayer: genome.ageLayer
        )
    }

    private func activeStoryCards(for record: DailyLifeRecord?, storyCards: [StoryCard]) -> [StoryCard] {
        storyCards.filter { card in
            guard Self.p0StorylineIDs.contains(card.storylineID) else { return false }
            guard let record else { return card.displayState != .locked }
            return card.evidenceDailyRecordIDs.contains(record.id) ||
                !Set(card.mapTraceIDs).isDisjoint(with: Set(record.storyTraceIDs)) ||
                record.storyBeatIDs.contains { $0.contains(card.storylineID) }
        }
    }

    private func storySignals(for cards: [StoryCard]) -> [StoryWorldSignal] {
        cards.map { card in
            StoryWorldSignal(
                storylineID: card.storylineID,
                storyCardID: card.id,
                displayState: card.displayState,
                recurrenceCount: card.recurrenceCount,
                evidenceDailyRecordIDs: Array(card.evidenceDailyRecordIDs.suffix(12)),
                mapTraceIDs: Array(card.mapTraceIDs.suffix(12)),
                suggestedWorldEcho: suggestedWorldEcho(for: card.storylineID),
                subtletyLevel: card.recurrenceCount >= 2 ? .clear : .subtle
            )
        }
    }

    private func cycleSignal(for cycle: CycleRecord) -> CycleWorldSignal {
        CycleWorldSignal(
            cycleID: cycle.cycleID,
            toriiCount: cycle.toriiCount,
            visitorSummary: cycle.visitorSummary,
            weatherPatternSummary: cycle.weatherPatternSummary,
            participationPattern: cycle.participationPattern.joined(separator: ","),
            unresolvedAnomalyIDs: cycle.unresolvedAnomalyIDs
        )
    }

    private func eraSignal(for eraID: EraID, eraMemory: EraMemory?) -> EraWorldSignal {
        EraWorldSignal(
            eraID: eraID,
            isLocked: eraMemory == nil,
            hasUnlockedMemory: eraMemory != nil,
            resetEchoLevel: eraMemory?.mikoTraceLevel ?? 0,
            persistentStoryCardIDs: eraMemory?.persistentStoryCardIDs ?? [],
            vanishedStoryCardIDs: eraMemory?.vanishedStoryCardIDs ?? []
        )
    }

    private func evidenceIDs(for record: DailyLifeRecord, storyCards: [StoryCard]) -> [String] {
        unique(
            [record.id, record.photoSnapshotID, record.diaryEntryID].compactMap { $0 } +
                record.storyBeatIDs +
                record.storyTraceIDs +
                storyCards.map(\.id) +
                storyCards.flatMap(\.mapTraceIDs)
        )
    }

    private func colorSignals(for record: DailyLifeRecord, photoSignal: PhotoMoodSignal) -> [String] {
        unique([
            photoSignal.dominantColorFamily.map { "dominant:\($0)" },
            record.picoGenomeAfter.map { "core:\($0.coreColor)" },
            record.picoGenomeAfter.map { "accent:\($0.accentColor)" }
        ].compactMap { $0 })
    }

    private func weatherSignals(for record: DailyLifeRecord) -> [String] {
        let mood = record.mapMood?.lowercased() ?? ""
        if mood.contains("rain") || record.storyTraceIDs.contains(where: { $0.contains("umbrella") }) {
            return ["rain"]
        }
        if mood.contains("fog") {
            return ["fog"]
        }
        return []
    }

    private func timeSignals(for record: DailyLifeRecord) -> [String] {
        if record.storyTraceIDs.contains(where: { $0.contains("night") || $0.contains("lamp") }) {
            return ["night"]
        }
        return []
    }

    private func diarySignals(for record: DailyLifeRecord, storyCards: [StoryCard]) -> [String] {
        let base = record.diaryEntryID.map { [$0] } ?? []
        return unique(base + storyCards.flatMap(\.diaryEntryIDs))
    }

    private func lifeAlbumSignals(for record: DailyLifeRecord, memoryStore: PicodMemoryStore) -> [String] {
        guard let album = memoryStore.lifeAlbum(for: record.lifeID) else { return [] }
        return unique([
            "lifeAlbum:\(album.id)",
            "dominantMood:\(album.dominantLifeMood)",
            "finalForm:\(album.finalRenderedFormID.map(String.init) ?? "unknown")"
        ] + album.recurringTraits.map { "trait:\($0)" })
    }

    private func semanticMoodTags(for record: DailyLifeRecord) -> [String] {
        var tags: [String] = []
        if let mood = record.mapMood, !mood.isEmpty {
            tags.append(mood.lowercased())
        }
        if record.didCapturePhoto {
            tags.append("captured")
        } else {
            tags.append("still")
        }
        if let seed = record.selectedSeedID {
            tags.append("seed:\(seed)")
        }
        tags.append(contentsOf: record.storyTraceIDs.map { "trace:\($0)" })
        return unique(tags)
    }

    private func dominantColorFamily(from genome: PicoGenome?) -> String? {
        guard let hex = genome?.coreColor.uppercased(), hex.count >= 6 else { return nil }
        let prefix = String(hex.prefix(2))
        let green = String(hex.dropFirst(2).prefix(2))
        let blue = String(hex.dropFirst(4).prefix(2))
        let redValue = Int(prefix, radix: 16) ?? 0
        let greenValue = Int(green, radix: 16) ?? 0
        let blueValue = Int(blue, radix: 16) ?? 0
        if redValue > greenValue + 24 && redValue > blueValue + 24 { return "warm" }
        if blueValue > redValue + 24 && blueValue > greenValue + 16 { return "cool" }
        if greenValue > redValue + 12 && greenValue > blueValue + 12 { return "green" }
        return "neutral"
    }

    private func brightnessBand(from mood: String) -> WorldBrightnessBand {
        if mood.contains("night") { return .dark }
        if mood.contains("rain") || mood.contains("fog") { return .dim }
        if mood.contains("bright") || mood.contains("sun") { return .bright }
        return .balanced
    }

    private func saturationBand(confidence: Double?) -> WorldSaturationBand {
        guard let confidence else { return .soft }
        if confidence >= 0.78 { return .vivid }
        if confidence < 0.38 { return .muted }
        return .soft
    }

    private func confidenceBand(_ confidence: Double?) -> WorldSignalConfidenceBand {
        guard let confidence else { return .none }
        if confidence >= 0.78 { return .high }
        if confidence >= 0.42 { return .medium }
        return .low
    }

    private func changedTraits(before: PicoGenome?, after: PicoGenome) -> [String] {
        guard let before else { return ["hatch"] }
        var changes: [String] = []
        if before.baseBody != after.baseBody { changes.append("baseBody") }
        if before.coreColor != after.coreColor { changes.append("coreColor") }
        if before.accentColor != after.accentColor { changes.append("accentColor") }
        if before.headTrait != after.headTrait { changes.append("headTrait") }
        if before.appendageTrait != after.appendageTrait { changes.append("appendageTrait") }
        if before.eyeTrait != after.eyeTrait { changes.append("eyeTrait") }
        if before.textureTrait != after.textureTrait { changes.append("textureTrait") }
        if before.anomalyMark != after.anomalyMark { changes.append("anomalyMark") }
        if before.memoryScar != after.memoryScar { changes.append("memoryScar") }
        if before.ageLayer != after.ageLayer { changes.append("ageLayer") }
        return changes
    }

    private func participationState(records: [DailyLifeRecord]) -> WorldParticipationState {
        guard !records.isEmpty else { return .unknown }
        let captured = records.filter(\.didCapturePhoto).count
        switch captured {
        case 0:
            return .absent
        case 1...2:
            return .minimal
        case 3...5:
            return .partial
        default:
            return .steady
        }
    }

    private func participationState(pattern: [String]) -> WorldParticipationState {
        let captured = pattern.filter { $0.lowercased().contains("capture") || $0.lowercased().contains("record") }.count
        if captured >= 5 { return .steady }
        if captured >= 3 { return .partial }
        if captured > 0 { return .minimal }
        return pattern.isEmpty ? .unknown : .absent
    }

    private func suggestedWorldEcho(for storylineID: String) -> String? {
        switch storylineID {
        case "night_lamplighter":
            return "lit-path-marker"
        case "umbrella_woman":
            return "wet-path-edge"
        case "mirror_miko":
            return "shrine-reflection"
        default:
            return nil
        }
    }

    private func cycleIndex(from cycleID: CycleID) -> CycleIndexInEra {
        let pieces = cycleID.rawValue.split(separator: "-")
        if let last = pieces.last, let value = Int(last) {
            return CycleIndexInEra(value)
        }
        return CycleIndexInEra(1)
    }

    private func fallbackPosition(
        localDayKey: PicodDayKey,
        lifeID: LifeID,
        cycleID: CycleID,
        eraID: EraID,
        dayIndex: DayIndexInLife,
        cycleIndex: CycleIndexInEra
    ) -> PicodTimePosition {
        PicodTimePosition(
            localDayKey: localDayKey,
            lifeID: lifeID,
            cycleID: cycleID,
            eraID: eraID,
            dayIndexInLife: dayIndex,
            cycleIndexInEra: cycleIndex,
            eraDayIndex: EraDayIndex(((cycleIndex.rawValue - 1) * 7) + dayIndex.rawValue)
        )
    }

    private func debugSummary(for record: DailyLifeRecord, storyCards: [StoryCard]) -> String {
        [
            "record=\(record.id)",
            "day=\(record.dayIndexInLife.rawValue)",
            "captured=\(record.didCapturePhoto)",
            "stories=\(storyCards.map(\.storylineID).joined(separator: ","))",
            "mood=\(record.mapMood ?? "none")"
        ].joined(separator: " ")
    }

    private func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private static let p0StorylineIDs: Set<String> = [
        "night_lamplighter",
        "umbrella_woman",
        "mirror_miko"
    ]
}

private extension WorldSignalBundle {
    func replacing(
        cycleSignals: [CycleWorldSignal],
        eraSignals: [EraWorldSignal]
    ) -> WorldSignalBundle {
        WorldSignalBundle(
            id: id,
            localDayKey: localDayKey,
            lifeID: lifeID,
            cycleID: cycleID,
            eraID: eraID,
            dayIndexInLife: dayIndexInLife,
            cycleIndexInEra: cycleIndexInEra,
            captureState: captureState,
            participationState: participationState,
            photoMoodSignals: photoMoodSignals,
            colorSignals: colorSignals,
            weatherSignals: weatherSignals,
            timeOfDaySignals: timeOfDaySignals,
            picoEvolutionSignals: picoEvolutionSignals,
            storySignals: storySignals,
            diarySignals: diarySignals,
            mapTraceSignals: mapTraceSignals,
            lifeAlbumSignals: lifeAlbumSignals,
            cycleSignals: cycleSignals,
            eraSignals: eraSignals,
            missingDaySignals: missingDaySignals,
            evidenceIDs: evidenceIDs,
            debugSummary: debugSummary
        )
    }
}
