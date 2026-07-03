import Foundation

struct WorldEvidenceAnchorResolver {
    func resolveAnchors(
        projection: WorldStateProjection,
        memoryStore: PicodMemoryStore
    ) -> [WorldEvidenceAnchor] {
        resolveAnchors(projection: projection, memoryIndex: MemoryIndex(memoryStore: memoryStore))
    }

    func resolveAnchors(projection: WorldStateProjection) -> [WorldEvidenceAnchor] {
        resolveAnchors(projection: projection, memoryIndex: .empty)
    }

    func linkDailyRecord(
        _ record: DailyLifeRecord,
        anchors: [WorldEvidenceAnchor]
    ) -> WorldEvidenceLink {
        let evidence = unique(
            [record.id, record.photoSnapshotID, record.diaryEntryID].compactMap { $0 } +
                record.storyBeatIDs +
                record.storyTraceIDs
        )
        return link(
            sourceMemoryType: .dailyLifeRecord,
            sourceMemoryID: record.id,
            evidenceIDs: evidence,
            anchors: anchors,
            fallbackLabel: record.didCapturePhoto ? "A quiet trace stayed with this day." : "The map kept this day soft and still.",
            debugSummary: "daily record evidence \(evidence.count)"
        )
    }

    func linkStoryCard(
        _ card: StoryCard,
        anchors: [WorldEvidenceAnchor]
    ) -> WorldEvidenceLink {
        let evidence = unique(
            [card.id] +
                card.evidenceDailyRecordIDs +
                card.diaryEntryIDs +
                card.mapTraceIDs
        )
        return link(
            sourceMemoryType: .storyCard,
            sourceMemoryID: card.id,
            evidenceIDs: evidence,
            anchors: anchors.filter { $0.displayState != .hidden },
            fallbackLabel: card.displayState == .locked ? "This trace has not stepped into the world yet." : "The world only left a faint clue.",
            debugSummary: "story card \(card.storylineID) evidence \(evidence.count)"
        )
    }

    func linkLifeAlbum(
        _ album: LifeAlbum,
        anchors: [WorldEvidenceAnchor]
    ) -> WorldEvidenceLink {
        let evidence = unique(
            [album.id, "lifeAlbum:\(album.id)"] +
                album.dayRecords.map(\.id) +
                album.dayRecords.flatMap(\.storyTraceIDs) +
                album.unlockedStoryCardIDs
        )
        return link(
            sourceMemoryType: .lifeAlbum,
            sourceMemoryID: album.id,
            evidenceIDs: evidence,
            anchors: anchors,
            fallbackLabel: "A seven-day trace rests quietly in the world.",
            debugSummary: "life album evidence \(evidence.count)"
        )
    }

    func linkCycleRecord(
        _ record: CycleRecord,
        anchors: [WorldEvidenceAnchor]
    ) -> WorldEvidenceLink {
        let evidence = unique(
            [record.id, record.cycleID.rawValue] +
                record.lifeAlbumIDs +
                record.unlockedStoryCardIDs
        )
        return link(
            sourceMemoryType: .cycleRecord,
            sourceMemoryID: record.id,
            evidenceIDs: evidence,
            anchors: anchors,
            fallbackLabel: record.toriiCount > 0 ? "A world marker remembers this cycle." : "This cycle left a quiet rhythm.",
            debugSummary: "cycle record evidence \(evidence.count)"
        )
    }

    func linkEraMemory(
        _ memory: EraMemory,
        anchors: [WorldEvidenceAnchor]
    ) -> WorldEvidenceLink {
        let evidence = unique(
            [memory.id, memory.eraID.rawValue] +
                memory.cycleRecordIDs +
                memory.lifeAlbumIDs +
                memory.persistentStoryCardIDs
        )
        return link(
            sourceMemoryType: .eraMemory,
            sourceMemoryID: memory.id,
            evidenceIDs: evidence,
            anchors: anchors.filter { $0.validationState != .locked && $0.displayState != .hidden },
            fallbackLabel: "Something rare stayed after the long turn.",
            debugSummary: "era memory evidence \(evidence.count)"
        )
    }

    private func resolveAnchors(
        projection: WorldStateProjection,
        memoryIndex: MemoryIndex
    ) -> [WorldEvidenceAnchor] {
        let anchors = projection.allElements.flatMap { element -> [WorldEvidenceAnchor] in
            let evidenceIDs = unique(element.evidenceIDs).filter { !$0.isEmpty }
            guard !evidenceIDs.isEmpty else { return [] }
            if element.source == .storyTrace && evidenceIDs.isEmpty { return [] }

            return evidenceIDs.compactMap { evidenceID in
                let sourceType = evidenceSourceType(
                    evidenceID: evidenceID,
                    element: element,
                    memoryIndex: memoryIndex
                )
                let sourceRecordID = sourceRecordID(
                    evidenceID: evidenceID,
                    sourceType: sourceType,
                    memoryIndex: memoryIndex
                )
                let storylineID = storylineID(
                    evidenceID: evidenceID,
                    element: element,
                    memoryIndex: memoryIndex
                )
                let isLockedEra = element.source == .eraMemory &&
                    sourceType == .eraMemory &&
                    memoryIndex.hasMemoryIndex &&
                    memoryIndex.eraMemories[evidenceID] == nil &&
                    memoryIndex.eraMemoryByEraID[evidenceID] == nil

                return WorldEvidenceAnchor(
                    id: anchorID(projection: projection, element: element, evidenceID: evidenceID),
                    evidenceID: evidenceID,
                    evidenceSourceType: sourceType,
                    sourceRecordID: sourceRecordID,
                    localDayKey: localDayKey(evidenceID: evidenceID, memoryIndex: memoryIndex),
                    lifeID: lifeID(evidenceID: evidenceID, memoryIndex: memoryIndex),
                    cycleID: cycleID(evidenceID: evidenceID, memoryIndex: memoryIndex) ?? projection.cycleID,
                    eraID: eraID(evidenceID: evidenceID, memoryIndex: memoryIndex) ?? projection.eraID,
                    storylineID: storylineID,
                    projectedElementID: element.id,
                    catalogElementID: element.catalogElementID,
                    mapVariantID: projection.mapVariantID,
                    anchorKind: anchorKind(for: element, storylineID: storylineID),
                    anchorPoint: element.tileOrAnchor,
                    displayState: displayState(for: element, sourceType: sourceType, isLockedEra: isLockedEra),
                    persistenceScope: element.persistenceScope,
                    userFacingLabel: userFacingLabel(for: element, sourceType: sourceType, storylineID: storylineID),
                    debugReason: "element \(element.id) evidence \(evidenceID): \(element.debugReason)",
                    validationState: isLockedEra ? .locked : .valid
                )
            }
        }
        return uniqueAnchors(anchors)
    }

    private func link(
        sourceMemoryType: WorldEvidenceMemoryType,
        sourceMemoryID: String,
        evidenceIDs: [String],
        anchors: [WorldEvidenceAnchor],
        fallbackLabel: String,
        debugSummary: String
    ) -> WorldEvidenceLink {
        let evidenceSet = Set(evidenceIDs)
        let matches = anchors.filter { anchor in
            evidenceSet.contains(anchor.evidenceID) ||
                evidenceSet.contains(anchor.sourceRecordID) ||
                (anchor.storylineID.map { evidenceSet.contains("story:\($0)") || evidenceSet.contains($0) } ?? false)
        }
        let visible = matches.filter { $0.displayState != .hidden && $0.validationState != .locked }
        let sorted = visible.sorted { lhs, rhs in
            if lhs.displayState != rhs.displayState {
                return displayRank(lhs.displayState) < displayRank(rhs.displayState)
            }
            return lhs.id < rhs.id
        }
        let anchorIDs = unique(sorted.map(\.id))
        let primary = sorted.first
        return WorldEvidenceLink(
            sourceMemoryType: sourceMemoryType,
            sourceMemoryID: sourceMemoryID,
            anchorIDs: anchorIDs,
            primaryAnchorID: primary?.id,
            fallbackLabel: primary?.userFacingLabel ?? fallbackLabel,
            canHighlightOnMap: primary?.anchorPoint != nil && primary?.projectedElementID != nil,
            canOpenDetail: !anchorIDs.isEmpty,
            debugSummary: "\(debugSummary), anchors \(anchorIDs.count)"
        )
    }

    private func evidenceSourceType(
        evidenceID: String,
        element: WorldProjectedElement,
        memoryIndex: MemoryIndex
    ) -> WorldEvidenceSourceType {
        if memoryIndex.dailyRecords[evidenceID] != nil { return .dailyLifeRecord }
        if memoryIndex.diaryEntryIDs.contains(evidenceID) { return .diaryEntry }
        if memoryIndex.storyCards[evidenceID] != nil { return .storyCard }
        if memoryIndex.mapTraceToStoryCard[evidenceID] != nil { return .mapTrace }
        if memoryIndex.lifeAlbums[evidenceID] != nil || evidenceID.hasPrefix("lifeAlbum:") { return .lifeAlbum }
        if memoryIndex.cycleRecords[evidenceID] != nil || memoryIndex.cycleRecordByCycleID[evidenceID] != nil { return .cycleRecord }
        if memoryIndex.eraMemories[evidenceID] != nil || memoryIndex.eraMemoryByEraID[evidenceID] != nil { return .eraMemory }
        if evidenceID.hasPrefix("photo:") || evidenceID.contains("photo") { return .photoMood }
        if evidenceID.hasPrefix("trace:") || evidenceID.contains("maptrace") || evidenceID.contains("trace") { return .mapTrace }
        if evidenceID.hasPrefix("story:") { return .storyCard }
        switch element.source {
        case .photoMood: return .photoMood
        case .picoEvolution: return .picoEvolution
        case .storyTrace: return .mapTrace
        case .cycleRecord: return .cycleRecord
        case .eraMemory: return .eraMemory
        case .participation: return .dailyLifeRecord
        case .baseMap: return .unknown
        }
    }

    private func sourceRecordID(
        evidenceID: String,
        sourceType: WorldEvidenceSourceType,
        memoryIndex: MemoryIndex
    ) -> String {
        switch sourceType {
        case .dailyLifeRecord:
            return memoryIndex.dailyRecords[evidenceID]?.id ?? evidenceID
        case .diaryEntry:
            return memoryIndex.diaryEntryToDailyRecord[evidenceID]?.id ?? evidenceID
        case .storyCard:
            return memoryIndex.storyCards[evidenceID]?.id ??
                memoryIndex.storyCardByStorylineID[evidenceID.replacingOccurrences(of: "story:", with: "")]?.id ??
                evidenceID
        case .mapTrace:
            return memoryIndex.mapTraceToStoryCard[evidenceID]?.id ?? evidenceID
        case .lifeAlbum:
            let clean = evidenceID.replacingOccurrences(of: "lifeAlbum:", with: "")
            return memoryIndex.lifeAlbums[clean]?.id ?? memoryIndex.lifeAlbums[evidenceID]?.id ?? clean
        case .cycleRecord:
            return memoryIndex.cycleRecords[evidenceID]?.id ?? memoryIndex.cycleRecordByCycleID[evidenceID]?.id ?? evidenceID
        case .eraMemory:
            return memoryIndex.eraMemories[evidenceID]?.id ?? memoryIndex.eraMemoryByEraID[evidenceID]?.id ?? evidenceID
        case .photoMood, .picoEvolution, .unknown:
            return evidenceID
        }
    }

    private func storylineID(
        evidenceID: String,
        element: WorldProjectedElement,
        memoryIndex: MemoryIndex
    ) -> String? {
        if let card = memoryIndex.storyCards[evidenceID] { return card.storylineID }
        if let card = memoryIndex.mapTraceToStoryCard[evidenceID] { return card.storylineID }
        if evidenceID.hasPrefix("story:") {
            return evidenceID.replacingOccurrences(of: "story:", with: "")
        }
        for storyline in ["night_lamplighter", "umbrella_woman", "mirror_miko"] where evidenceID.contains(storyline) || element.id.contains(storyline) {
            return storyline
        }
        return nil
    }

    private func localDayKey(evidenceID: String, memoryIndex: MemoryIndex) -> PicodDayKey? {
        memoryIndex.dailyRecords[evidenceID]?.localDayKey ??
            memoryIndex.diaryEntryToDailyRecord[evidenceID]?.localDayKey ??
            memoryIndex.mapTraceToDailyRecord[evidenceID]?.localDayKey
    }

    private func lifeID(evidenceID: String, memoryIndex: MemoryIndex) -> LifeID? {
        memoryIndex.dailyRecords[evidenceID]?.lifeID ??
            memoryIndex.diaryEntryToDailyRecord[evidenceID]?.lifeID ??
            memoryIndex.mapTraceToDailyRecord[evidenceID]?.lifeID
    }

    private func cycleID(evidenceID: String, memoryIndex: MemoryIndex) -> CycleID? {
        memoryIndex.dailyRecords[evidenceID]?.cycleID ??
            memoryIndex.diaryEntryToDailyRecord[evidenceID]?.cycleID ??
            memoryIndex.mapTraceToDailyRecord[evidenceID]?.cycleID ??
            memoryIndex.cycleRecordByCycleID[evidenceID]?.cycleID
    }

    private func eraID(evidenceID: String, memoryIndex: MemoryIndex) -> EraID? {
        memoryIndex.dailyRecords[evidenceID]?.eraID ??
            memoryIndex.diaryEntryToDailyRecord[evidenceID]?.eraID ??
            memoryIndex.mapTraceToDailyRecord[evidenceID]?.eraID ??
            memoryIndex.eraMemoryByEraID[evidenceID]?.eraID
    }

    private func anchorKind(for element: WorldProjectedElement, storylineID: String?) -> WorldEvidenceAnchorKind {
        if element.role == .cycleMarker { return .cycleMarker }
        if element.role == .eraEcho { return .eraEcho }
        if AnimalKind(rawValue: element.catalogElementID) != nil { return .animal }
        if element.catalogElementID.contains("lantern") || storylineID == "night_lamplighter" { return .light }
        if storylineID == "umbrella_woman" || element.placementIntent == .waterEdge { return .waterEdge }
        if storylineID == "mirror_miko" || element.placementIntent == .shrineEdge { return .shrine }
        switch element.placementIntent {
        case .pathEdge: return .path
        case .waterEdge: return .waterEdge
        case .shrineEdge: return .shrine
        case .hiddenEcho: return .eraEcho
        case .picoNearby, .courtyard, .perimeter, .base: return .object
        }
    }

    private func displayState(
        for element: WorldProjectedElement,
        sourceType: WorldEvidenceSourceType,
        isLockedEra: Bool
    ) -> WorldEvidenceAnchorDisplayState {
        if isLockedEra { return .hidden }
        if sourceType == .eraMemory || element.role == .eraEcho { return .remembered }
        if element.source == .participation || element.visualPriority == .background { return .hinted }
        return .visible
    }

    private func userFacingLabel(
        for element: WorldProjectedElement,
        sourceType: WorldEvidenceSourceType,
        storylineID: String?
    ) -> String {
        if storylineID == "night_lamplighter" { return "A small light remembered the path." }
        if storylineID == "umbrella_woman" { return "The rain stayed near the edge of the path." }
        if storylineID == "mirror_miko" { return "A quiet reflection stayed near the shrine." }
        if element.role == .cycleMarker || sourceType == .cycleRecord { return "A world marker remembers this cycle." }
        if element.role == .eraEcho || sourceType == .eraMemory { return "A rare echo stayed where the world turned." }
        switch element.source {
        case .photoMood:
            return "A trace from the photo settled near the path."
        case .picoEvolution:
            return "Pico kept this change close."
        case .storyTrace:
            return "A story trace touched the map."
        case .participation:
            return "The quiet day left a soft place."
        case .cycleRecord:
            return "A world marker remembers this cycle."
        case .eraMemory:
            return "A rare echo stayed where the world turned."
        case .baseMap:
            return "The world kept a small mark."
        }
    }

    private func anchorID(
        projection: WorldStateProjection,
        element: WorldProjectedElement,
        evidenceID: String
    ) -> String {
        "anchor:\(projection.id):\(element.id):\(evidenceID)"
            .replacingOccurrences(of: " ", with: "-")
    }

    private func displayRank(_ state: WorldEvidenceAnchorDisplayState) -> Int {
        switch state {
        case .remembered: return 0
        case .visible: return 1
        case .hinted: return 2
        case .hidden: return 3
        }
    }

    private func uniqueAnchors(_ anchors: [WorldEvidenceAnchor]) -> [WorldEvidenceAnchor] {
        var seen = Set<String>()
        var result: [WorldEvidenceAnchor] = []
        for anchor in anchors where seen.insert(anchor.id).inserted {
            result.append(anchor)
        }
        return result
    }

    private func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private struct MemoryIndex {
        let dailyRecords: [String: DailyLifeRecord]
        let diaryEntryToDailyRecord: [String: DailyLifeRecord]
        let mapTraceToDailyRecord: [String: DailyLifeRecord]
        let storyCards: [String: StoryCard]
        let storyCardByStorylineID: [String: StoryCard]
        let mapTraceToStoryCard: [String: StoryCard]
        let diaryEntryIDs: Set<String>
        let lifeAlbums: [String: LifeAlbum]
        let cycleRecords: [String: CycleRecord]
        let cycleRecordByCycleID: [String: CycleRecord]
        let eraMemories: [String: EraMemory]
        let eraMemoryByEraID: [String: EraMemory]
        let hasMemoryIndex: Bool

        static let empty = MemoryIndex()

        private init() {
            dailyRecords = [:]
            diaryEntryToDailyRecord = [:]
            mapTraceToDailyRecord = [:]
            storyCards = [:]
            storyCardByStorylineID = [:]
            mapTraceToStoryCard = [:]
            diaryEntryIDs = []
            lifeAlbums = [:]
            cycleRecords = [:]
            cycleRecordByCycleID = [:]
            eraMemories = [:]
            eraMemoryByEraID = [:]
            hasMemoryIndex = false
        }

        init(memoryStore: PicodMemoryStore) {
            dailyRecords = Dictionary(memoryStore.dailyRecords.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            diaryEntryToDailyRecord = Dictionary(
                memoryStore.dailyRecords.compactMap { record in
                    record.diaryEntryID.map { ($0, record) }
                },
                uniquingKeysWith: { first, _ in first }
            )
            mapTraceToDailyRecord = Dictionary(
                memoryStore.dailyRecords.flatMap { record in
                    record.storyTraceIDs.map { ($0, record) }
                },
                uniquingKeysWith: { first, _ in first }
            )
            storyCards = Dictionary(memoryStore.storyCards.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            storyCardByStorylineID = Dictionary(memoryStore.storyCards.map { ($0.storylineID, $0) }, uniquingKeysWith: { first, _ in first })
            mapTraceToStoryCard = Dictionary(
                memoryStore.storyCards.flatMap { card in
                    card.mapTraceIDs.map { ($0, card) }
                },
                uniquingKeysWith: { first, _ in first }
            )
            diaryEntryIDs = Set(memoryStore.storyCards.flatMap(\.diaryEntryIDs) + memoryStore.dailyRecords.compactMap(\.diaryEntryID))
            lifeAlbums = Dictionary(memoryStore.lifeAlbums.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            cycleRecords = Dictionary(memoryStore.cycleRecords.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            cycleRecordByCycleID = Dictionary(memoryStore.cycleRecords.map { ($0.cycleID.rawValue, $0) }, uniquingKeysWith: { first, _ in first })
            eraMemories = Dictionary(memoryStore.eraMemories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            eraMemoryByEraID = Dictionary(memoryStore.eraMemories.map { ($0.eraID.rawValue, $0) }, uniquingKeysWith: { first, _ in first })
            hasMemoryIndex = true
        }
    }
}

enum WorldEvidenceLinkAuditor {
    static func auditDebugScenarios(
        context: WorldGenerationContext = DevTestMode.worldGenerationContext
    ) -> WorldEvidenceLinkAuditReport {
        let resolver = WorldEvidenceAnchorResolver()
        let scenarioReports = WorldProjectionDebugScenarios.allReports(context: context).map { report in
            let anchors = resolver.resolveAnchors(projection: report.projection)
            let anchorIDs = anchors.map(\.id)
            let duplicateCount = anchorIDs.count - Set(anchorIDs).count
            let lockedLeakCount = report.id == .lockedEraMemory
                ? anchors.filter { $0.displayState != .hidden && $0.evidenceSourceType == .eraMemory }.count
                : anchors.filter { $0.validationState == .locked && $0.displayState != .hidden }.count
            let evidenceRequiredElements = report.projection.allElements.filter { element in
                element.source != .baseMap &&
                    element.source != .participation &&
                    !(report.id == .freshDay1Empty && element.evidenceIDs.isEmpty)
            }
            let missingEvidenceCount = evidenceRequiredElements.filter(\.evidenceIDs.isEmpty).count
            let expectedStoryMissing = report.storyEchoCount > 0 &&
                anchors.contains(where: { $0.evidenceSourceType == .storyCard || $0.evidenceSourceType == .mapTrace }) == false
            let expectsAnchors = report.projection.allElements.contains { !$0.evidenceIDs.isEmpty }
            let unresolved = (expectsAnchors && anchors.isEmpty ? 1 : 0) + (expectedStoryMissing ? 1 : 0)

            return WorldEvidenceLinkAuditScenario(
                id: report.id.rawValue,
                anchorCount: anchors.count,
                visibleAnchorCount: anchors.filter { $0.displayState == .visible || $0.displayState == .remembered }.count,
                storyAnchorCount: anchors.filter { $0.evidenceSourceType == .storyCard || $0.evidenceSourceType == .mapTrace }.count,
                cycleAnchorCount: anchors.filter { $0.evidenceSourceType == .cycleRecord || $0.anchorKind == .cycleMarker }.count,
                eraAnchorCount: anchors.filter { $0.evidenceSourceType == .eraMemory || $0.anchorKind == .eraEcho }.count,
                unresolvedLinkCount: unresolved,
                duplicateAnchorCount: max(0, duplicateCount),
                lockedLeakCount: lockedLeakCount,
                missingEvidenceCount: missingEvidenceCount
            )
        }
        return WorldEvidenceLinkAuditReport(scenarioReports: scenarioReports)
    }
}
