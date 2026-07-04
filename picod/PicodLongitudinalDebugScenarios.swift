import Foundation

enum PicodPrePhotoMapPolicy {
    static func canShowActivePico(
        appState: AppState,
        hasPhotoToday: Bool,
        isPreviewWorkingState: Bool
    ) -> Bool {
        if isPreviewWorkingState { return true }
        return appState == .picoAlive && hasPhotoToday
    }
}

#if DEBUG
struct PicodLongitudinalAuditSummary {
    let prePhotoPassed: Bool
    let sevenDayPassed: Bool
    let npcTriggerPassed: Bool
    let trajectoryPassed: Bool
    let lineagePassed: Bool
    let prePhotoRows: [PicodPrePhotoAuditRow]
    let sevenDayRows: [PicodSevenDayAuditRow]
    let npcRows: [PicodNPCAuditRow]
    let trajectoryRows: [PicodTrajectoryAuditRow]
    let lineageRows: [PicodLineageAuditRow]

    var failedAreaCount: Int {
        [prePhotoPassed, sevenDayPassed, npcTriggerPassed, trajectoryPassed, lineagePassed]
            .filter { !$0 }
            .count
    }
}

struct PicodPrePhotoAuditRow {
    let id: String
    let appState: AppState
    let hasPhotoToday: Bool
    let projectionGateLabel: String
    let activePicoAllowed: Bool
    let picoSignalCount: Int
    let projectedPicoTraceCount: Int
    let passed: Bool
}

struct PicodSevenDayAuditRow {
    let dayIndex: Int
    let didCapturePhoto: Bool
    let selectedSeedID: String
    let renderedFormID: Int
    let genomeSummary: String
    let changedTraits: String
    let mapVariantID: String
    let projectedElementCount: Int
    let persistentElementCount: Int
    let transientElementCount: Int
    let storyTraceCount: Int
    let cycleMarkerCount: Int
    let eraEchoCount: Int
    let npcVisitorCount: Int
    let diaryFragment: String
    let worldTraceFragment: String
    let validationErrors: Int
    let validationWarnings: Int
}

struct PicodNPCAuditRow {
    let storylineID: String
    let triggerInput: String
    let expectedOutput: String
    let actualOutput: String
    let storyCardState: String
    let mapTraceEvidence: String
    let passed: Bool
}

struct PicodTrajectoryAuditRow {
    let familyID: String
    let daySeeds: String
    let reasonTags: String
    let beforeAfterSummary: String
    let changedTraits: String
    let renderedForms: String
    let oneMajorTraitRulePassed: Bool
    let coreColorPersistencePassed: Bool
    let accentColorSummary: String
    let anomalyAndScarSummary: String
    let lifeAlbumSummary: String
    let nextLifeSummary: String
    let passed: Bool
}

struct PicodLineageAuditRow {
    let cycleIndex: Int
    let lifeID: String
    let dayOneGenomeBefore: String
    let previousFinalFormID: String
    let dayOneFormID: Int
    let carryoverSummary: String
    let classification: String
    let passed: Bool
}

@MainActor
enum PicodLongitudinalDebugScenarios {
    static func printAudit() {
        let summary = runAudit()
        print(
            "[PicodLongitudinalAudit] summary prePhoto=\(status(summary.prePhotoPassed)) " +
            "sevenDay=\(status(summary.sevenDayPassed)) npc=\(status(summary.npcTriggerPassed)) " +
            "trajectories=\(status(summary.trajectoryPassed)) lineage=\(status(summary.lineagePassed)) " +
            "failedAreas=\(summary.failedAreaCount)"
        )
        for row in summary.trajectoryRows {
            print(
                "[PicodLongitudinalAudit] trajectory \(row.familyID) seeds=\(row.daySeeds) " +
                "forms=\(row.renderedForms) changes=\(row.changedTraits) " +
                "oneMajor=\(status(row.oneMajorTraitRulePassed)) coreColor=\(status(row.coreColorPersistencePassed)) " +
                "album=\(row.lifeAlbumSummary) nextLife=\(row.nextLifeSummary) result=\(status(row.passed))"
            )
        }
        for row in summary.lineageRows {
            print(
                "[PicodLongitudinalAudit] lineage cycle=\(row.cycleIndex) life=\(row.lifeID) " +
                "day1Before=\(row.dayOneGenomeBefore) previousFinal=\(row.previousFinalFormID) " +
                "day1Form=\(row.dayOneFormID) carryover=\(row.carryoverSummary) " +
                "classification=\(row.classification) result=\(status(row.passed))"
            )
        }
        for row in summary.prePhotoRows {
            print(
                "[PicodLongitudinalAudit] prePhoto \(row.id) gate=\(row.projectionGateLabel) " +
                "state=\(row.appState.rawValue) hasPhoto=\(row.hasPhotoToday) " +
                "activePicoAllowed=\(row.activePicoAllowed) picoSignals=\(row.picoSignalCount) " +
                "picoTraceElements=\(row.projectedPicoTraceCount) result=\(status(row.passed))"
            )
        }
        for row in summary.sevenDayRows {
            print(
                "[PicodLongitudinalAudit] day\(row.dayIndex) seed=\(row.selectedSeedID) " +
                "form=\(row.renderedFormID) changed=\(row.changedTraits) map=\(row.mapVariantID) " +
                "elements=\(row.projectedElementCount) persistent=\(row.persistentElementCount) " +
                "transient=\(row.transientElementCount) story=\(row.storyTraceCount) " +
                "npc=\(row.npcVisitorCount) validation=\(row.validationErrors)/\(row.validationWarnings)"
            )
        }
        for row in summary.npcRows {
            print(
                "[PicodLongitudinalAudit] npc \(row.storylineID) input=\(row.triggerInput) " +
                "expected=\(row.expectedOutput) actual=\(row.actualOutput) " +
                "card=\(row.storyCardState) evidence=\(row.mapTraceEvidence) result=\(status(row.passed))"
            )
        }
    }

    static func runAudit() -> PicodLongitudinalAuditSummary {
        let prePhotoRows = runPrePhotoAudit()
        let sevenDay = runSevenDayEnvironmentAudit()
        let npcRows = runNPCTriggerAudit()
        let trajectoryRows = TrajectoryFamily.allCases.map { runTrajectoryAudit(family: $0) }
        let lineageRows = runSevenCycleLineageAudit()

        return PicodLongitudinalAuditSummary(
            prePhotoPassed: prePhotoRows.allSatisfy(\.passed),
            sevenDayPassed: sevenDay.passed,
            npcTriggerPassed: npcRows.allSatisfy(\.passed),
            trajectoryPassed: trajectoryRows.allSatisfy(\.passed),
            lineagePassed: lineageRows.allSatisfy(\.passed),
            prePhotoRows: prePhotoRows,
            sevenDayRows: sevenDay.rows,
            npcRows: npcRows,
            trajectoryRows: trajectoryRows,
            lineageRows: lineageRows
        )
    }

    private static func runPrePhotoAudit() -> [PicodPrePhotoAuditRow] {
        let cases: [(String, Int, Int, String, AppState, Bool)] = [
            ("fresh-install-before-photo", 1, 1, "off", .empty, false),
            ("day2-before-photo", 1, 2, "off", .empty, false),
            ("day7-before-photo", 1, 7, "off", .empty, false),
            ("day8-new-life-before-photo", 2, 1, "off", .empty, false),
            ("relaunch-before-today-photo", 1, 3, "off", .empty, false),
            ("projection-off-before-photo", 1, 4, "off", .empty, false),
            ("projection-on-before-photo", 1, 4, "on", .empty, false)
        ]
        let baseMap = TestMapFactory.devMap(context: DevTestMode.worldGenerationContext)

        return cases.map { item in
            let urls = makeDebugStoreURLs(prefix: "prephoto")
            let store = makeMemoryStore(urls: urls)
            let progress = fakeProgress(
                day: item.2,
                cycle: item.1,
                eraID: "debug-prephoto-era",
                generationID: "debug-prephoto-life-\(item.1)-\(item.2)",
                participation: .pending
            )
            store.recordMissingDay(progress: progress, createdAt: progress.dayStartAt)
            let record = store.currentLifeRecords(lifeID: LifeID(rawValue: progress.generationId)).first
            let bundle = record.map { WorldSignalResolver().resolveForDailyRecord($0, memoryStore: store) }
            let projection = bundle.map {
                WorldStateProjector().project(bundle: $0, baseMap: baseMap, mapVariantID: "prePhoto:\(item.0)")
            }
            let activePicoAllowed = PicodPrePhotoMapPolicy.canShowActivePico(
                appState: item.4,
                hasPhotoToday: item.5,
                isPreviewWorkingState: false
            )
            let picoSignalCount = bundle?.picoEvolutionSignals.count ?? 0
            let picoTraceCount = projection?.allElements.filter { $0.source == .picoEvolution }.count ?? 0
            try? FileManager.default.removeItem(at: urls.directory)
            return PicodPrePhotoAuditRow(
                id: item.0,
                appState: item.4,
                hasPhotoToday: item.5,
                projectionGateLabel: item.3,
                activePicoAllowed: activePicoAllowed,
                picoSignalCount: picoSignalCount,
                projectedPicoTraceCount: picoTraceCount,
                passed: !activePicoAllowed && picoSignalCount == 0 && picoTraceCount == 0
            )
        }
    }

    private static func runSevenDayEnvironmentAudit() -> (passed: Bool, rows: [PicodSevenDayAuditRow]) {
        let urls = makeDebugStoreURLs(prefix: "seven-day")
        let store = makeMemoryStore(urls: urls)
        let baseMap = TestMapFactory.devMap(context: DevTestMode.worldGenerationContext)
        let simulation = simulateLife(
            store: store,
            family: .warmIndoorObject,
            eraID: "debug-long-loop-era",
            cycle: 1,
            generationID: "debug-long-loop-life",
            baseMap: baseMap
        )
        let dayOneCount = simulation.rows.first?.projectedElementCount ?? 0
        let daySevenCount = simulation.rows.last?.projectedElementCount ?? 0
        let hasNoPrePhotoPico = !PicodPrePhotoMapPolicy.canShowActivePico(
            appState: .empty,
            hasPhotoToday: false,
            isPreviewWorkingState: false
        )
        let storyDaysPresent = simulation.rows.contains { $0.dayIndex == 4 && $0.storyTraceCount >= 1 }
            && simulation.rows.contains { $0.dayIndex == 5 && $0.storyTraceCount >= 1 }
            && simulation.rows.contains { $0.dayIndex == 7 && $0.storyTraceCount >= 1 }
        let passed = hasNoPrePhotoPico
            && simulation.rows.count == 7
            && daySevenCount > dayOneCount
            && storyDaysPresent
            && simulation.rows.allSatisfy { $0.validationErrors == 0 }
        try? FileManager.default.removeItem(at: urls.directory)
        return (passed, simulation.rows)
    }

    private static func runNPCTriggerAudit() -> [PicodNPCAuditRow] {
        let urls = makeDebugStoreURLs(prefix: "npc")
        let store = makeMemoryStore(urls: urls)
        let baseMap = TestMapFactory.devMap(context: DevTestMode.worldGenerationContext)
        let simulation = simulateLife(
            store: store,
            family: .rainWater,
            eraID: "debug-npc-era",
            cycle: 1,
            generationID: "debug-npc-life",
            baseMap: baseMap
        )

        func eligible(day: Int, weather: PicodWeatherCondition, phase: PicodTimePhase, interactions: Int) -> [NarrativeCharacterKind] {
            let progress = fakeProgress(
                day: day,
                cycle: 1,
                eraID: "debug-npc-era",
                generationID: "debug-npc-life",
                participation: .captured,
                interactionRecordCount: interactions,
                worldSeedGenerationId: day >= 4 ? "debug-world" : nil
            )
            let context = StoryTriggerContext(
                progress: progress,
                weatherCondition: weather,
                timePhase: phase,
                localHour: phase == .night ? 22 : 14,
                recentParticipationStates: [.captured, .captured, .captured],
                alreadyFiredBeatIds: []
            )
            return StoryTriggerEngine().eligibleBeats(context: context)
                .filter(\.isP0ActiveStory)
                .map(\.characterKind)
        }

        func storyEvidence(_ kind: NarrativeCharacterKind, day: Int) -> (String, String, Bool) {
            let storylineID = kind.rawValue
            let card = store.storyCards.first { $0.storylineID == storylineID }
            let row = simulation.rows.first { $0.dayIndex == day }
            let cardState = card?.displayState.rawValue ?? "none"
            let evidence = [
                "cardEvidence:\(card?.evidenceDailyRecordIDs.count ?? 0)",
                "mapTrace:\(card?.mapTraceIDs.count ?? 0)",
                "projectedStory:\(row?.storyTraceCount ?? 0)"
            ].joined(separator: ",")
            return (cardState, evidence, card != nil && (row?.storyTraceCount ?? 0) > 0)
        }

        let nightBefore = !eligible(day: 3, weather: .clear, phase: .afternoon, interactions: 0).contains(.nightLamplighter)
        let nightActual = eligible(day: 5, weather: .clear, phase: .night, interactions: 0).contains(.nightLamplighter)
        let nightEvidence = storyEvidence(.nightLamplighter, day: 5)

        let umbrellaBefore = !eligible(day: 4, weather: .clear, phase: .afternoon, interactions: 0).contains(.umbrellaWoman)
        let umbrellaActual = eligible(day: 4, weather: .rain, phase: .dusk, interactions: 0).contains(.umbrellaWoman)
        let umbrellaEvidence = storyEvidence(.umbrellaWoman, day: 4)

        let mirrorBefore = !eligible(day: 6, weather: .clear, phase: .night, interactions: 0).contains(.mirrorMiko)
        let mirrorActual = eligible(day: 7, weather: .clear, phase: .night, interactions: 1).contains(.mirrorMiko)
        let mirrorEvidence = storyEvidence(.mirrorMiko, day: 7)
        let lockedEraLeak = simulation.rows.first(where: { $0.dayIndex == 6 })?.eraEchoCount == 0

        try? FileManager.default.removeItem(at: urls.directory)

        return [
            PicodNPCAuditRow(
                storylineID: "night_lamplighter",
                triggerInput: "day3 afternoon clear -> day5 night",
                expectedOutput: "absent before night, present on day5/6 night",
                actualOutput: "before=\(!nightBefore ? "present" : "absent") day5=\(nightActual ? "present" : "absent")",
                storyCardState: nightEvidence.0,
                mapTraceEvidence: nightEvidence.1,
                passed: nightBefore && nightActual && nightEvidence.2
            ),
            PicodNPCAuditRow(
                storylineID: "umbrella_woman",
                triggerInput: "day4 clear -> day4 rain",
                expectedOutput: "absent without rain, present with rainy signal",
                actualOutput: "clear=\(!umbrellaBefore ? "present" : "absent") rain=\(umbrellaActual ? "present" : "absent")",
                storyCardState: umbrellaEvidence.0,
                mapTraceEvidence: umbrellaEvidence.1,
                passed: umbrellaBefore && umbrellaActual && umbrellaEvidence.2
            ),
            PicodNPCAuditRow(
                storylineID: "mirror_miko",
                triggerInput: "day6 no reflection -> day7 reflection",
                expectedOutput: "absent before reflection, present on day7 closure/reflection; no locked era leak",
                actualOutput: "day6=\(!mirrorBefore ? "present" : "absent") day7=\(mirrorActual ? "present" : "absent") lockedEraLeak=\(!lockedEraLeak)",
                storyCardState: mirrorEvidence.0,
                mapTraceEvidence: mirrorEvidence.1,
                passed: mirrorBefore && mirrorActual && mirrorEvidence.2 && lockedEraLeak
            )
        ]
    }

    private static func runTrajectoryAudit(family: TrajectoryFamily) -> PicodTrajectoryAuditRow {
        let urls = makeDebugStoreURLs(prefix: "trajectory-\(family.rawValue)")
        let store = makeMemoryStore(urls: urls)
        let baseMap = TestMapFactory.devMap(context: DevTestMode.worldGenerationContext)
        let simulation = simulateLife(
            store: store,
            family: family,
            eraID: "debug-trajectory-era-\(family.rawValue)",
            cycle: 1,
            generationID: "debug-trajectory-\(family.rawValue)",
            baseMap: baseMap
        )
        let decisions = simulation.decisions
        let album = store.lifeAlbums.first { $0.lifeID.rawValue == "debug-trajectory-\(family.rawValue)" }
        let nextLife = simulateFirstDay(
            store: store,
            family: family,
            eraID: "debug-trajectory-era-\(family.rawValue)",
            cycle: 2,
            generationID: "debug-trajectory-\(family.rawValue)-next",
            previousGenome: nil
        )

        let daySeeds = simulation.seedMatches.map(\.selectedSeedID).joined(separator: " -> ")
        let reasonTags = simulation.seedMatches
            .map { Array(($0.semanticReasonTags + $0.colorReasonTags + $0.timeWeatherReasonTags).prefix(3)).joined(separator: "+") }
            .joined(separator: " | ")
        let beforeAfter = decisions.map {
            "\($0.genomeBefore?.renderedFormID.description ?? "nil")>\($0.genomeAfter.renderedFormID)"
        }.joined(separator: ",")
        let changes = decisions.map { $0.changedMajorTrait ?? "none" }.joined(separator: ",")
        let forms = decisions.map { String($0.renderedFormID) }.joined(separator: ",")
        let day1Hatched = decisions.first?.changedMajorTrait == "hatch"
        let inherited = (1..<min(6, decisions.count)).allSatisfy { index in
            decisions[index].genomeBefore == decisions[index - 1].genomeAfter
        }
        let oneMajor = decisions.enumerated().allSatisfy { index, decision in
            if index == 0 { return decision.changedMajorTrait == "hatch" }
            return (decision.debugSnapshot.changedTraits?.count ?? 0) <= 1
        }
        let core = decisions.first?.genomeAfter.coreColor
        let corePersisted = decisions.dropFirst().allSatisfy { $0.genomeAfter.coreColor == core }
        let noFullReplacement = decisions.dropFirst().allSatisfy {
            $0.genomeBefore?.baseBody == $0.genomeAfter.baseBody
        }
        let albumOK = album?.dayRecords.count == 7 && album?.finalGenome != nil
        let nextLifeClean = nextLife.decision.genomeBefore == nil
            && nextLife.decision.genomeAfter.ageLayer == 1
            && nextLife.decision.changedMajorTrait == "hatch"
        let passed = day1Hatched
            && inherited
            && oneMajor
            && corePersisted
            && noFullReplacement
            && albumOK
            && nextLifeClean

        let accentValues = Array(Set(decisions.map { $0.genomeAfter.accentColor })).sorted()
        let anomalyScar = decisions.map {
            "d\($0.debugSnapshot.dayIndexInLife):\($0.genomeAfter.anomalyMark ?? "none")/\($0.genomeAfter.memoryScar ?? "none")"
        }.joined(separator: ",")

        try? FileManager.default.removeItem(at: urls.directory)
        return PicodTrajectoryAuditRow(
            familyID: family.rawValue,
            daySeeds: daySeeds,
            reasonTags: reasonTags,
            beforeAfterSummary: beforeAfter,
            changedTraits: changes,
            renderedForms: forms,
            oneMajorTraitRulePassed: oneMajor,
            coreColorPersistencePassed: corePersisted,
            accentColorSummary: accentValues.joined(separator: ","),
            anomalyAndScarSummary: anomalyScar,
            lifeAlbumSummary: "slots=\(album?.dayRecords.count ?? 0) final=\(album?.finalRenderedFormID.map(String.init) ?? "nil")",
            nextLifeSummary: "before=\(nextLife.decision.genomeBefore?.renderedFormID.description ?? "nil") lineage=\(nextLife.decision.genomeAfter.seedLineageIDs.joined(separator: ","))",
            passed: passed
        )
    }

    private static func runSevenCycleLineageAudit() -> [PicodLineageAuditRow] {
        let urls = makeDebugStoreURLs(prefix: "lineage")
        let store = makeMemoryStore(urls: urls)
        let baseMap = TestMapFactory.devMap(context: DevTestMode.worldGenerationContext)
        var rows: [PicodLineageAuditRow] = []
        var previousFinal: PicoGenome?

        for cycle in 1...7 {
            let generationID = "debug-lineage-cycle-\(cycle)"
            let simulation = simulateLife(
                store: store,
                family: TrajectoryFamily.allCases[(cycle - 1) % TrajectoryFamily.allCases.count],
                eraID: "debug-lineage-era",
                cycle: cycle,
                generationID: generationID,
                baseMap: baseMap
            )
            let firstDecision = simulation.decisions.first
            let album = store.lifeAlbums.first { $0.lifeID.rawValue == generationID }
            let dayOneGenome = firstDecision?.genomeAfter
            let leakage = firstDecision?.genomeBefore != nil
            let carryover = carryoverSummary(previous: previousFinal, current: dayOneGenome)
            let classification = leakage
                ? "accidental active-body leakage"
                : "fresh hatch; world/cycle/era echoes remain retrospective only"
            rows.append(
                PicodLineageAuditRow(
                    cycleIndex: cycle,
                    lifeID: generationID,
                    dayOneGenomeBefore: firstDecision?.genomeBefore?.renderedFormID.description ?? "nil",
                    previousFinalFormID: previousFinal?.renderedFormID.description ?? "nil",
                    dayOneFormID: dayOneGenome?.renderedFormID ?? -1,
                    carryoverSummary: carryover,
                    classification: classification,
                    passed: !leakage
                )
            )
            previousFinal = album?.finalGenome
        }

        let finalProgress = fakeProgress(
            day: 7,
            cycle: 7,
            eraID: "debug-lineage-era",
            generationID: "debug-lineage-cycle-7",
            participation: .captured
        )
        _ = store.closeEraIfReady(
            progress: finalProgress,
            now: finalProgress.dayStartAt.addingTimeInterval(20 * 60 * 60)
        )
        try? FileManager.default.removeItem(at: urls.directory)
        return rows
    }

    private static func simulateLife(
        store: PicodMemoryStore,
        family: TrajectoryFamily,
        eraID: String,
        cycle: Int,
        generationID: String,
        baseMap: TestMap
    ) -> (rows: [PicodSevenDayAuditRow], decisions: [PicoEvolutionDecision], seedMatches: [PhotoSeedMatch]) {
        var existingSnapshots: [PhotoTraitSnapshot] = []
        var previousGenome: PicoGenome?
        var rows: [PicodSevenDayAuditRow] = []
        var decisions: [PicoEvolutionDecision] = []
        var seedMatches: [PhotoSeedMatch] = []

        for day in 1...7 {
            let result = captureDay(
                store: store,
                family: family,
                eraID: eraID,
                cycle: cycle,
                generationID: generationID,
                day: day,
                existingSnapshots: existingSnapshots,
                previousGenome: previousGenome
            )
            existingSnapshots.append(result.result.photoSnapshot)
            previousGenome = result.result.evolutionDecision.genomeAfter
            decisions.append(result.result.evolutionDecision)
            seedMatches.append(result.result.seedMatch)

            let bundle = WorldSignalResolver().resolveForDailyRecord(result.record, memoryStore: store)
            let mapVariantID = mapVariantID(for: day)
            let projection = WorldStateProjector().project(
                bundle: bundle,
                baseMap: baseMap,
                mapVariantID: mapVariantID
            )
            let validation = WorldMapValidator.validate(projection, baseMap: baseMap)
            rows.append(
                PicodSevenDayAuditRow(
                    dayIndex: day,
                    didCapturePhoto: result.record.didCapturePhoto,
                    selectedSeedID: result.result.seedMatch.selectedSeedID,
                    renderedFormID: result.result.evolutionDecision.renderedFormID,
                    genomeSummary: genomeSummary(result.result.evolutionDecision.genomeAfter),
                    changedTraits: result.result.evolutionDecision.changedMajorTrait ?? "none",
                    mapVariantID: mapVariantID,
                    projectedElementCount: projection.allElements.count,
                    persistentElementCount: projection.persistentElements.count,
                    transientElementCount: projection.transientElements.count,
                    storyTraceCount: projection.storyTraceElements.count,
                    cycleMarkerCount: projection.cycleMarkerElements.count,
                    eraEchoCount: projection.eraEchoElements.count,
                    npcVisitorCount: bundle.storySignals.count,
                    diaryFragment: result.record.diaryEntryID ?? "none",
                    worldTraceFragment: projection.allElements.first?.debugReason ?? "none",
                    validationErrors: validation.errorCount,
                    validationWarnings: validation.warningCount
                )
            )
        }

        let closeProgress = fakeProgress(
            day: 7,
            cycle: cycle,
            eraID: eraID,
            generationID: generationID,
            participation: .captured
        )
        _ = store.closeLifeIfReady(
            progress: closeProgress,
            now: closeProgress.dayStartAt.addingTimeInterval(20 * 60 * 60),
            closingDiaryText: "Pico curled back into a quiet egg shape."
        )
        _ = store.closeCycleIfReady(
            progress: closeProgress,
            now: closeProgress.dayStartAt.addingTimeInterval(20 * 60 * 60),
            worldSeed: nil
        )

        return (rows, decisions, seedMatches)
    }

    private static func simulateFirstDay(
        store: PicodMemoryStore,
        family: TrajectoryFamily,
        eraID: String,
        cycle: Int,
        generationID: String,
        previousGenome: PicoGenome?
    ) -> (record: DailyLifeRecord, decision: PicoEvolutionDecision) {
        let captured = captureDay(
            store: store,
            family: family,
            eraID: eraID,
            cycle: cycle,
            generationID: generationID,
            day: 1,
            existingSnapshots: [],
            previousGenome: previousGenome
        )
        return (captured.record, captured.result.evolutionDecision)
    }

    private static func captureDay(
        store: PicodMemoryStore,
        family: TrajectoryFamily,
        eraID: String,
        cycle: Int,
        generationID: String,
        day: Int,
        existingSnapshots: [PhotoTraitSnapshot],
        previousGenome: PicoGenome?
    ) -> (record: DailyLifeRecord, result: DailyCaptureOrchestratorResult) {
        let progress = fakeProgress(
            day: day,
            cycle: cycle,
            eraID: eraID,
            generationID: generationID,
            participation: .captured,
            interactionRecordCount: day == 7 ? 1 : 0,
            worldSeedGenerationId: day >= 4 ? "debug-world" : nil
        )
        let labels = family.labels(day: day)
        let palette = family.palette(day: day)
        let worldInput = fakeWorldInput(
            date: progress.dayStartAt,
            timePhase: timePhase(day: day, family: family),
            weather: weather(day: day, family: family)
        )
        let activeStoryBeatIDs = storyBeatIDs(day: day)
        let result = DailyCaptureOrchestrator().run(
            input: DailyCaptureOrchestratorInput(
                capturedPhoto: nil,
                rawVisionLabels: labels,
                colorPalette: palette,
                localDate: progress.dayStartAt,
                progress: progress,
                existingSnapshots: existingSnapshots,
                previousGenome: previousGenome,
                worldInput: worldInput,
                participation: GenerationParticipation(
                    daysPhotographed: max(0, day - 1),
                    consecutiveDays: max(0, day - 1),
                    firstDayParticipated: day > 1
                ),
                activeStoryBeatIDs: activeStoryBeatIDs,
                photoMetadata: nil,
                languageCode: "en",
                isNightClosure: false
            )
        )
        let record = store.recordDailyCapture(
            progress: progress,
            snapshot: result.photoSnapshot,
            seedMatch: result.seedMatch,
            evolution: result.evolutionDecision,
            worldSeed: nil,
            storyBundle: result.storyBundle,
            mapMood: result.mapMood,
            createdAt: progress.dayStartAt
        )
        return (record, result)
    }

    private static func storyBeatIDs(day: Int) -> [String] {
        switch day {
        case 4:
            return ["\(NarrativeCharacterKind.umbrellaWoman.rawValue):debug:day4:rain_or_fog"]
        case 5:
            return ["\(NarrativeCharacterKind.nightLamplighter.rawValue):debug:day5:dusk_or_night"]
        case 6:
            return ["\(NarrativeCharacterKind.nightLamplighter.rawValue):debug:day6:dusk_or_night"]
        case 7:
            return ["\(NarrativeCharacterKind.mirrorMiko.rawValue):debug:day7:reflection"]
        default:
            return []
        }
    }

    private static func timePhase(day: Int, family: TrajectoryFamily) -> PicodTimePhase {
        if family == .nightLampDark || day == 5 || day == 6 || day == 7 { return .night }
        if day == 4 { return .dusk }
        return .afternoon
    }

    private static func weather(day: Int, family: TrajectoryFamily) -> PicodWeatherCondition {
        if family == .rainWater || day == 4 { return .rain }
        return .clear
    }

    private static func mapVariantID(for day: Int) -> String {
        switch day {
        case 4:
            return "wetlandLantern"
        case 5, 6:
            return "nightGrove"
        case 7:
            return "forestShrine"
        default:
            return "forestShrine"
        }
    }

    private static func fakeWorldInput(
        date: Date,
        timePhase: PicodTimePhase,
        weather: PicodWeatherCondition
    ) -> PicodWorldInput {
        let hour: Int
        switch timePhase {
        case .morning: hour = 9
        case .afternoon: hour = 14
        case .dusk: hour = 18
        case .night: hour = 22
        }
        let stable = PicodStableWorldInput(
            quantizedLatitude: 0,
            quantizedLongitude: 0,
            localityName: nil,
            regionName: nil,
            timezoneIdentifier: "Asia/Shanghai",
            worldSeed: 0xA11CE_2026
        )
        let volatile = PicodVolatileWorldInput(
            localDate: date,
            localHour: hour,
            timePhase: timePhase,
            weather: PicodWeatherContext(
                temperatureCelsius: nil,
                humidityPercent: weather == .rain ? 82 : 48,
                precipitationChance: weather == .rain ? 0.7 : 0.0,
                condition: weather,
                fetchedAt: date
            ),
            instanceSeed: stable.worldSeed ^ UInt64(hour)
        )
        return PicodWorldInput(stable: stable, volatile: volatile, environmentalInfluence: .neutral)
    }

    private static func fakeProgress(
        day: Int,
        cycle: Int,
        eraID: String,
        generationID: String,
        participation: PicodParticipationState,
        interactionRecordCount: Int = 0,
        worldSeedGenerationId: String? = nil
    ) -> PicodProgressRecord {
        let absolute = (cycle - 1) * 7 + day
        let start = Date(timeIntervalSince1970: 1_767_247_200 + Double((absolute - 1) * 86_400))
        return PicodProgressRecord(
            eraId: eraID,
            absoluteDayIndex: absolute,
            cycleIndex: cycle,
            dayInCycle: day,
            calendarDayKey: "debug-\(cycle)-\(day)-\(generationID)",
            dayStartAt: start,
            generationId: generationID,
            photoSnapshotDayKey: nil,
            interactionRecordCount: interactionRecordCount,
            diarySummaryDayKey: nil,
            worldSeedGenerationId: worldSeedGenerationId,
            firedStoryBeatIds: [],
            participationState: participation,
            openedAt: start,
            finalizedAt: day == 7 ? start.addingTimeInterval(20 * 60 * 60) : nil
        )
    }

    private static func makeMemoryStore(urls: DebugStoreURLs) -> PicodMemoryStore {
        PicodMemoryStore(
            fileURL: urls.index,
            lifeAlbumStore: LifeAlbumStore(fileURL: urls.lifeAlbums),
            cycleRecordStore: CycleRecordStore(fileURL: urls.cycleRecords),
            storyCardStore: StoryCardStore(fileURL: urls.storyCards),
            eraMemoryStore: EraMemoryStore(fileURL: urls.eraMemories)
        )
    }

    private static func makeDebugStoreURLs(prefix: String) -> DebugStoreURLs {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("picod_\(prefix)_debug_\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return DebugStoreURLs(
            directory: dir,
            index: dir.appendingPathComponent("picod_memory_index.json"),
            lifeAlbums: dir.appendingPathComponent("life_albums_db.json"),
            cycleRecords: dir.appendingPathComponent("cycle_records_db.json"),
            storyCards: dir.appendingPathComponent("story_cards_db.json"),
            eraMemories: dir.appendingPathComponent("era_memories_db.json")
        )
    }

    private static func carryoverSummary(previous: PicoGenome?, current: PicoGenome?) -> String {
        guard let previous, let current else { return "none" }
        let fields: [(String, Bool)] = [
            ("baseBody", previous.baseBody == current.baseBody),
            ("coreColor", previous.coreColor == current.coreColor),
            ("accentColor", previous.accentColor == current.accentColor),
            ("headTrait", previous.headTrait == current.headTrait),
            ("appendageTrait", previous.appendageTrait == current.appendageTrait),
            ("eyeTrait", previous.eyeTrait == current.eyeTrait),
            ("textureTrait", previous.textureTrait == current.textureTrait),
            ("anomalyMark", previous.anomalyMark == current.anomalyMark),
            ("memoryScar", previous.memoryScar == current.memoryScar),
            ("renderedFormID", previous.renderedFormID == current.renderedFormID),
            ("seedLineageIDs", previous.seedLineageIDs == current.seedLineageIDs)
        ]
        let equal = fields.filter(\.1).map(\.0)
        return equal.isEmpty ? "none" : equal.joined(separator: ",")
    }

    private static func genomeSummary(_ genome: PicoGenome) -> String {
        [
            "body:\(genome.baseBody)",
            "core:\(genome.coreColor)",
            "accent:\(genome.accentColor)",
            "age:\(genome.ageLayer)",
            "mark:\(genome.anomalyMark ?? "none")",
            "scar:\(genome.memoryScar ?? "none")"
        ].joined(separator: " ")
    }

    private static func status(_ passed: Bool) -> String {
        passed ? "pass" : "fail"
    }
}

private enum TrajectoryFamily: String, CaseIterable {
    case warmIndoorObject
    case plantNature
    case rainWater
    case nightLampDark
    case animalOutdoorOrPersonObject

    func labels(day: Int) -> [VisionLabel] {
        let base: [(String, Float)]
        switch self {
        case .warmIndoorObject:
            base = day == 1
                ? [("warm indoor lamp", 0.88), ("table", 0.62)]
                : [("paper book", 0.78), ("warm cloth", 0.56)]
        case .plantNature:
            base = day == 1
                ? [("green plant", 0.88), ("leaf", 0.68)]
                : [("tree flower grass", 0.82), ("garden", 0.62)]
        case .rainWater:
            base = day == 1
                ? [("water cup", 0.86), ("blue rain", 0.68)]
                : [("rain umbrella water", 0.84), ("wet street", 0.64)]
        case .nightLampDark:
            base = day == 1
                ? [("night lamp", 0.88), ("dark room", 0.66)]
                : [("lantern night window", 0.86), ("stone", 0.56)]
        case .animalOutdoorOrPersonObject:
            base = day == 1
                ? [("dog outdoor path", 0.86), ("person", 0.58)]
                : [("bird path sky", 0.82), ("road", 0.60)]
        }

        let story: [(String, Float)]
        switch day {
        case 4:
            story = [("rain umbrella", 0.90)]
        case 5, 6:
            story = [("night lantern", 0.90)]
        case 7:
            story = [("mirror reflection", 0.90)]
        default:
            story = []
        }

        return (story + base).map { VisionLabel(identifier: $0.0, confidence: $0.1) }
    }

    func palette(day: Int) -> [PhotoPaletteColor] {
        let colors: [(Double, Double, Double)]
        switch self {
        case .warmIndoorObject:
            colors = [(0.82, 0.58, 0.34), (0.96, 0.82, 0.56)]
        case .plantNature:
            colors = [(0.36, 0.62, 0.34), (0.82, 0.76, 0.45)]
        case .rainWater:
            colors = [(0.30, 0.42, 0.56), (0.50, 0.60, 0.68)]
        case .nightLampDark:
            colors = [(0.18, 0.20, 0.30), (0.92, 0.72, 0.38)]
        case .animalOutdoorOrPersonObject:
            colors = [(0.62, 0.52, 0.42), (0.74, 0.66, 0.54)]
        }
        let adjusted = day == 7 ? [(0.70, 0.78, 0.84), colors[1]] : colors
        return adjusted.map { PhotoPaletteColor(red: $0.0, green: $0.1, blue: $0.2, alpha: 1) }
    }
}

private struct DebugStoreURLs {
    let directory: URL
    let index: URL
    let lifeAlbums: URL
    let cycleRecords: URL
    let storyCards: URL
    let eraMemories: URL
}
#endif
