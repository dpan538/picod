import Foundation

enum WorldProjectionDebugScenarioID: String, CaseIterable, Identifiable {
    case freshDay1Empty
    case day1WarmIndoorCapture
    case day4RainyUmbrellaTrace
    case day5NightLamplighterTrace
    case day7MirrorClosure
    case completedLifeAlbum
    case completedCycleRecord
    case lowParticipationLife
    case lockedEraMemory
    case unlockedEraMemory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .freshDay1Empty: return "fresh Day 1 empty"
        case .day1WarmIndoorCapture: return "Day 1 warm capture"
        case .day4RainyUmbrellaTrace: return "Day 4 rainy umbrella"
        case .day5NightLamplighterTrace: return "Day 5 lamplighter"
        case .day7MirrorClosure: return "Day 7 mirror closure"
        case .completedLifeAlbum: return "completed Life Album"
        case .completedCycleRecord: return "completed Cycle Record"
        case .lowParticipationLife: return "low participation Life"
        case .lockedEraMemory: return "locked Era Memory"
        case .unlockedEraMemory: return "unlocked Era Memory"
        }
    }

    var mapVariant: DevTestMode.MapReviewVariant {
        switch self {
        case .day4RainyUmbrellaTrace:
            return .wetlandLantern
        case .day5NightLamplighterTrace:
            return .nightGrove
        case .freshDay1Empty, .day1WarmIndoorCapture, .day7MirrorClosure,
             .completedLifeAlbum, .completedCycleRecord, .lowParticipationLife,
             .lockedEraMemory, .unlockedEraMemory:
            return .forestShrine
        }
    }

    var visualExpectation: String {
        switch self {
        case .freshDay1Empty:
            return "quiet board, Pico spawn readable, one stillness marker at most"
        case .day1WarmIndoorCapture:
            return "warm photo trace near path, Pico remains legible"
        case .day4RainyUmbrellaTrace:
            return "rain/water-edge trace, umbrella evidence present"
        case .day5NightLamplighterTrace:
            return "night path echo, lamp evidence present"
        case .day7MirrorClosure:
            return "shrine/reflection trace, final-life evidence present"
        case .completedLifeAlbum:
            return "retrospective life marker, not a second full album"
        case .completedCycleRecord:
            return "cycle marker reads as world memory"
        case .lowParticipationLife:
            return "sparse and quiet, not punitive or broken"
        case .lockedEraMemory:
            return "Era signal is locked and must create no era echo"
        case .unlockedEraMemory:
            return "rare echo appears only after unlocked Era evidence"
        }
    }
}

struct WorldProjectionDebugScenarioReport: Identifiable {
    let id: WorldProjectionDebugScenarioID
    let baseMap: TestMap
    let signalBundle: WorldSignalBundle
    let projection: WorldStateProjection
    let placementPlan: WorldElementPlacementPlan
    let validation: WorldMapValidationReport
    let actions: [WorldRichnessAction]

    var mapVariantID: String { projection.mapVariantID }
    var sourceEvidenceCount: Int { projection.sourceEvidenceIDs.count }
    var projectedElementCount: Int { projection.allElements.count }
    var storyEchoCount: Int { projection.storyTraceElements.count }
    var cycleMarkerCount: Int { projection.cycleMarkerElements.count }
    var eraEchoCount: Int { projection.eraEchoElements.count }

    var highPriorityActionCount: Int {
        actions.filter { $0.priority == .blocker || $0.priority == .high }.count
    }

    var debugSummary: String {
        "\(id.rawValue) map \(mapVariantID) elements \(projectedElementCount) story \(storyEchoCount) cycle \(cycleMarkerCount) era \(eraEchoCount) evidence \(sourceEvidenceCount) errors \(validation.errorCount) warnings \(validation.warningCount)"
    }

    var storyEchoElements: [WorldProjectedElement] {
        projection.storyTraceElements
    }
}

enum WorldProjectionDebugScenarios {
    static func allReports(
        context: WorldGenerationContext = DevTestMode.worldGenerationContext
    ) -> [WorldProjectionDebugScenarioReport] {
        WorldProjectionDebugScenarioID.allCases.map { report(for: $0, context: context) }
    }

    static func report(
        for scenario: WorldProjectionDebugScenarioID,
        context: WorldGenerationContext = DevTestMode.worldGenerationContext
    ) -> WorldProjectionDebugScenarioReport {
        let baseMap = TestMapFactory.reviewWorld(context: context, variant: scenario.mapVariant)
        let signal = signalBundle(for: scenario)
        let projection = WorldStateProjector().project(
            bundle: signal,
            baseMap: baseMap,
            mapVariantID: scenario.mapVariant.rawValue
        )
        let validation = WorldMapValidator.validate(projection, baseMap: baseMap)
        return WorldProjectionDebugScenarioReport(
            id: scenario,
            baseMap: baseMap,
            signalBundle: signal,
            projection: projection,
            placementPlan: WorldProjectionMapAdapter.placementPlan(for: projection),
            validation: validation,
            actions: WorldMapRichnessAuditor.actions(for: validation, variantID: "preview:\(scenario.rawValue)")
        )
    }

    private static func signalBundle(for scenario: WorldProjectionDebugScenarioID) -> WorldSignalBundle {
        switch scenario {
        case .freshDay1Empty:
            return baseSignal(
                key: "p1d-fresh-day1-empty",
                day: 1,
                capture: .missing,
                participation: .unknown,
                moodTags: ["quiet", "fresh"],
                missing: [],
                evidence: []
            )
        case .day1WarmIndoorCapture:
            return baseSignal(
                key: "p1d-day1-warm-indoor",
                day: 1,
                capture: .captured,
                participation: .minimal,
                colorFamily: "warm",
                moodTags: ["warm", "indoor", "captured"],
                pico: picoSignal(day: 1, changed: ["hatch"], anomalyMark: nil, memoryScar: nil),
                evidence: ["debug-daily:day1", "debug-photo:warm-indoor"]
            )
        case .day4RainyUmbrellaTrace:
            return baseSignal(
                key: "p1d-day4-rainy-umbrella",
                day: 4,
                capture: .captured,
                participation: .partial,
                colorFamily: "cool",
                weather: ["rain", "wet-path"],
                moodTags: ["rain", "umbrella", "trace"],
                pico: picoSignal(day: 4, changed: ["anomalyMark"], anomalyMark: "rain-edge", memoryScar: nil),
                stories: [
                    storySignal(
                        storylineID: "umbrella_woman",
                        state: .traceSeen,
                        recurrence: 1,
                        evidence: ["debug-daily:day4"],
                        traces: ["debug-maptrace:umbrella-woman:rain"]
                    )
                ],
                evidence: ["debug-daily:day4", "debug-photo:rain", "debug-maptrace:umbrella-woman:rain"]
            )
        case .day5NightLamplighterTrace:
            return baseSignal(
                key: "p1d-day5-night-lamplighter",
                day: 5,
                capture: .captured,
                participation: .partial,
                colorFamily: "warm",
                time: ["night"],
                moodTags: ["night", "lamp", "remembered"],
                pico: picoSignal(day: 5, changed: ["memoryScar"], anomalyMark: "rain-edge", memoryScar: "small-warm-mark"),
                stories: [
                    storySignal(
                        storylineID: "night_lamplighter",
                        state: .encountered,
                        recurrence: 1,
                        evidence: ["debug-daily:day5"],
                        traces: ["debug-maptrace:night-lamplighter:lamp"]
                    )
                ],
                evidence: ["debug-daily:day5", "debug-photo:night-lamp", "debug-maptrace:night-lamplighter:lamp"]
            )
        case .day7MirrorClosure:
            return baseSignal(
                key: "p1d-day7-mirror-closure",
                day: 7,
                capture: .closed,
                participation: .steady,
                colorFamily: "neutral",
                moodTags: ["final", "reflection", "return"],
                pico: picoSignal(day: 7, changed: ["returnToEgg"], anomalyMark: "mirror-return", memoryScar: "life-returned"),
                stories: [
                    storySignal(
                        storylineID: "mirror_miko",
                        state: .encountered,
                        recurrence: 1,
                        evidence: ["debug-daily:day7"],
                        traces: ["debug-maptrace:mirror-miko:return"]
                    )
                ],
                evidence: ["debug-daily:day7", "debug-maptrace:mirror-miko:return"]
            )
        case .completedLifeAlbum:
            return baseSignal(
                key: "p1d-completed-life-album",
                day: 7,
                capture: .closed,
                participation: .steady,
                colorFamily: "green",
                moodTags: ["album", "quiet", "completed"],
                pico: picoSignal(day: 7, changed: ["ageLayer"], anomalyMark: nil, memoryScar: "life-returned"),
                lifeAlbumSignals: ["lifeAlbum:debug-life-1", "dominantMood:quiet", "trait:soft-color"],
                evidence: ["lifeAlbum:debug-life-1"]
            )
        case .completedCycleRecord:
            return baseSignal(
                key: "p1d-completed-cycle-record",
                day: 7,
                capture: .closed,
                participation: .steady,
                moodTags: ["cycle", "marker", "world-record"],
                cycleSignals: [
                    CycleWorldSignal(
                        cycleID: CycleID(rawValue: "debug-era-cycle-1"),
                        toriiCount: 1,
                        visitorSummary: "small repeated visitors",
                        weatherPatternSummary: "rain then clear",
                        participationPattern: "steady",
                        unresolvedAnomalyIDs: []
                    )
                ],
                evidence: ["cycleRecord:debug-era-cycle-1"]
            )
        case .lowParticipationLife:
            return baseSignal(
                key: "p1d-low-participation-life",
                day: 5,
                capture: .missing,
                participation: .minimal,
                moodTags: ["still", "quiet", "low-participation"],
                missing: ["missing-day:2", "missing-day:4", "missing-day:5"],
                evidence: []
            )
        case .lockedEraMemory:
            return baseSignal(
                key: "p1d-locked-era-memory",
                day: 7,
                cycle: 6,
                capture: .closed,
                participation: .steady,
                moodTags: ["era", "locked", "quiet"],
                eraSignals: [
                    EraWorldSignal(
                        eraID: EraID(rawValue: "debug-era-locked"),
                        isLocked: true,
                        hasUnlockedMemory: false,
                        resetEchoLevel: 0,
                        persistentStoryCardIDs: ["story:mirror_miko"],
                        vanishedStoryCardIDs: []
                    )
                ],
                evidence: ["eraBoundary:locked-preview"]
            )
        case .unlockedEraMemory:
            return baseSignal(
                key: "p1d-unlocked-era-memory",
                day: 7,
                cycle: 7,
                capture: .closed,
                participation: .steady,
                moodTags: ["era", "remembered", "echo"],
                stories: [
                    storySignal(
                        storylineID: "mirror_miko",
                        state: .remembered,
                        recurrence: 3,
                        evidence: ["debug-daily:day7", "debug-era-1"],
                        traces: ["debug-maptrace:mirror-miko:return", "debug-maptrace:mirror-miko:echo"]
                    )
                ],
                eraSignals: [
                    EraWorldSignal(
                        eraID: EraID(rawValue: "debug-era-1"),
                        isLocked: false,
                        hasUnlockedMemory: true,
                        resetEchoLevel: 2,
                        persistentStoryCardIDs: ["story:mirror_miko"],
                        vanishedStoryCardIDs: []
                    )
                ],
                evidence: ["debug-era-1", "story:mirror_miko"]
            )
        }
    }

    private static func baseSignal(
        key: String,
        day: Int,
        cycle: Int = 1,
        capture: WorldCaptureState,
        participation: WorldParticipationState,
        colorFamily: String? = nil,
        weather: [String] = [],
        time: [String] = [],
        moodTags: [String],
        pico: PicoWorldSignal? = nil,
        stories: [StoryWorldSignal] = [],
        lifeAlbumSignals: [String] = [],
        cycleSignals: [CycleWorldSignal] = [],
        eraSignals: [EraWorldSignal]? = nil,
        missing: [String] = [],
        evidence: [String]
    ) -> WorldSignalBundle {
        let eraID = EraID(rawValue: "debug-era-1")
        return WorldSignalBundle(
            id: "debug-world-signal:\(key)",
            localDayKey: PicodDayKey(rawValue: key),
            lifeID: LifeID(rawValue: "debug-life-1"),
            cycleID: CycleID(rawValue: "debug-era-cycle-\(cycle)"),
            eraID: eraSignals?.first?.eraID ?? eraID,
            dayIndexInLife: DayIndexInLife(day),
            cycleIndexInEra: CycleIndexInEra(cycle),
            captureState: capture,
            participationState: participation,
            photoMoodSignals: [
                PhotoMoodSignal(
                    dominantColorFamily: colorFamily,
                    brightnessBand: time.contains("night") ? .dark : (weather.contains("rain") ? .dim : .balanced),
                    saturationBand: colorFamily == nil ? .soft : .vivid,
                    semanticMoodTags: moodTags,
                    confidenceBand: capture == .captured ? .high : .none
                )
            ],
            colorSignals: colorFamily.map { ["dominant:\($0)"] } ?? [],
            weatherSignals: weather,
            timeOfDaySignals: time,
            picoEvolutionSignals: pico.map { [$0] } ?? [],
            storySignals: stories,
            diarySignals: capture == .missing ? ["debug-diary:quiet-fallback"] : ["debug-diary:\(key)"],
            mapTraceSignals: stories.flatMap(\.mapTraceIDs),
            lifeAlbumSignals: lifeAlbumSignals,
            cycleSignals: cycleSignals,
            eraSignals: eraSignals ?? [
                EraWorldSignal(
                    eraID: eraID,
                    isLocked: true,
                    hasUnlockedMemory: false,
                    resetEchoLevel: 0,
                    persistentStoryCardIDs: [],
                    vanishedStoryCardIDs: []
                )
            ],
            missingDaySignals: missing,
            evidenceIDs: evidence,
            debugSummary: "DEBUG-only synthetic memory scenario \(key)"
        )
    }

    private static func picoSignal(
        day: Int,
        changed: [String],
        anomalyMark: String?,
        memoryScar: String?
    ) -> PicoWorldSignal {
        PicoWorldSignal(
            renderedFormID: 1,
            genomeTraits: [
                "baseBody": "round",
                "coreColor": "D9B84F",
                "accentColor": "8BAE62",
                "headTrait": "small",
                "appendageTrait": day >= 3 ? "tiny-feet" : "none",
                "eyeTrait": day >= 6 ? "steady" : "soft",
                "textureTrait": day >= 2 ? "soft-grain" : "plain"
            ],
            changedTraits: changed,
            anomalyMark: anomalyMark,
            memoryScar: memoryScar,
            ageLayer: day
        )
    }

    private static func storySignal(
        storylineID: String,
        state: StoryCardDisplayState,
        recurrence: Int,
        evidence: [String],
        traces: [String]
    ) -> StoryWorldSignal {
        StoryWorldSignal(
            storylineID: storylineID,
            storyCardID: "story:\(storylineID)",
            displayState: state,
            recurrenceCount: recurrence,
            evidenceDailyRecordIDs: evidence,
            mapTraceIDs: traces,
            suggestedWorldEcho: nil,
            subtletyLevel: recurrence >= 2 ? .clear : .subtle
        )
    }
}
