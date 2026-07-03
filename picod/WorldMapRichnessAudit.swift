import Foundation

enum WorldRichnessActionPriority: String, CaseIterable, Codable, Hashable {
    case blocker
    case high
    case medium
    case low

    var sortRank: Int {
        switch self {
        case .blocker: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

struct WorldRichnessAction: Identifiable, Codable, Hashable {
    let id: String
    let priority: WorldRichnessActionPriority
    let variantID: String
    let mapName: String
    let category: WorldMapValidationCategory
    let issueCode: String
    let coord: MapCoord?
    let title: String
    let guidance: String

    var coordLabel: String {
        guard let coord else { return "map" }
        return "x\(coord.x) y\(coord.y)"
    }

    var compactLine: String {
        "\(priority.rawValue) \(variantID) \(issueCode) @ \(coordLabel): \(title)"
    }
}

struct WorldMapRichnessVariantReport: Identifiable, Codable, Hashable {
    let id: String
    let mapName: String
    let validation: WorldMapValidationReport
    let actions: [WorldRichnessAction]

    var highPriorityActionCount: Int {
        actions.filter { $0.priority == .blocker || $0.priority == .high }.count
    }

    var summaryLine: String {
        "\(id): errors \(validation.errorCount), warnings \(validation.warningCount), actions \(actions.count)"
    }
}

enum WorldProjectionAuditScenarioID: String, CaseIterable, Codable, Hashable, Identifiable {
    case emptyFreshInstall
    case day1Capture
    case day4RainyUmbrellaTrace
    case day5NightLamplighterTrace
    case day7MirrorClosure
    case completedLifeAlbum
    case completedCycleRecord
    case unlockedEraMemory
    case lowParticipationLife
    case corruptPartialMemoryFallback

    var id: String { rawValue }

    var mapVariant: DevTestMode.MapReviewVariant {
        switch self {
        case .day4RainyUmbrellaTrace:
            return .wetlandLantern
        case .day5NightLamplighterTrace:
            return .nightGrove
        case .completedCycleRecord, .unlockedEraMemory, .day7MirrorClosure:
            return .forestShrine
        case .completedLifeAlbum, .day1Capture, .emptyFreshInstall, .lowParticipationLife, .corruptPartialMemoryFallback:
            return .forestShrine
        }
    }
}

struct WorldProjectionAuditScenarioReport: Identifiable, Codable, Hashable {
    let id: String
    let mapVariantID: String
    let projection: WorldStateProjection
    let validation: WorldMapValidationReport
    let actions: [WorldRichnessAction]
    let projectedElementCount: Int
    let storyEchoCount: Int
    let cycleMarkerCount: Int
    let eraEchoCount: Int
    let ungroundedElementCount: Int
    let invalidHabitatCount: Int
    let pathObstructionCount: Int
    let occlusionRiskCount: Int
    let missingEvidenceCount: Int

    var highPriorityActionCount: Int {
        actions.filter { $0.priority == .blocker || $0.priority == .high }.count
    }

    var summaryLine: String {
        "\(id): map \(mapVariantID), projection errors \(validation.errorCount), warnings \(validation.warningCount), elements \(projectedElementCount), story \(storyEchoCount), cycle \(cycleMarkerCount), era \(eraEchoCount)"
    }
}

struct WorldMapRichnessAuditReport: Codable, Hashable {
    let variantReports: [WorldMapRichnessVariantReport]
    var projectionReports: [WorldProjectionAuditScenarioReport] = []
    var evidenceLinkAudit: WorldEvidenceLinkAuditReport = .empty

    var mapCount: Int {
        variantReports.count
    }

    var projectionScenarioCount: Int {
        projectionReports.count
    }

    var staticErrorCount: Int {
        variantReports.reduce(0) { $0 + $1.validation.errorCount }
    }

    var staticWarningCount: Int {
        variantReports.reduce(0) { $0 + $1.validation.warningCount }
    }

    var projectionErrorCount: Int {
        projectionReports.reduce(0) { $0 + $1.validation.errorCount }
    }

    var projectionWarningCount: Int {
        projectionReports.reduce(0) { $0 + $1.validation.warningCount }
    }

    var totalErrorCount: Int {
        staticErrorCount + projectionErrorCount
    }

    var totalWarningCount: Int {
        staticWarningCount + projectionWarningCount
    }

    var totalActionCount: Int {
        variantReports.reduce(0) { $0 + $1.actions.count } +
            projectionReports.reduce(0) { $0 + $1.actions.count }
    }

    var highPriorityActionCount: Int {
        variantReports.reduce(0) { $0 + $1.highPriorityActionCount } +
            projectionReports.reduce(0) { $0 + $1.highPriorityActionCount }
    }

    var didPassCoreRules: Bool {
        totalErrorCount == 0
    }

    var topActions: [WorldRichnessAction] {
        (variantReports.flatMap(\.actions) + projectionReports.flatMap(\.actions))
            .sorted { lhs, rhs in
                if lhs.priority.sortRank == rhs.priority.sortRank {
                    if lhs.variantID == rhs.variantID {
                        return lhs.issueCode < rhs.issueCode
                    }
                    return lhs.variantID < rhs.variantID
                }
                return lhs.priority.sortRank < rhs.priority.sortRank
            }
    }

    var summaryLine: String {
        "static maps \(mapCount) / projection scenarios \(projectionScenarioCount) / errors \(totalErrorCount) / warnings \(totalWarningCount) / actions \(totalActionCount) / high \(highPriorityActionCount)"
    }

    var consoleLines: [String] {
        var lines = ["summary \(summaryLine)"]
        lines.append("static maps audited \(mapCount) errors \(staticErrorCount) warnings \(staticWarningCount)")
        for report in variantReports {
            lines.append(report.summaryLine)
            for action in report.actions.prefix(6) {
                lines.append("  \(action.compactLine)")
            }
            if report.actions.count > 6 {
                lines.append("  + \(report.actions.count - 6) more action(s)")
            }
        }
        lines.append("projection scenarios audited \(projectionScenarioCount) errors \(projectionErrorCount) warnings \(projectionWarningCount)")
        for report in projectionReports {
            lines.append(report.summaryLine)
            lines.append("  counts ungrounded \(report.ungroundedElementCount) invalidHabitat \(report.invalidHabitatCount) pathObstruction \(report.pathObstructionCount) occlusion \(report.occlusionRiskCount) missingEvidence \(report.missingEvidenceCount)")
            for action in report.actions.prefix(4) {
                lines.append("  \(action.compactLine)")
            }
            if report.actions.count > 4 {
                lines.append("  + \(report.actions.count - 4) more projection action(s)")
            }
        }
        if evidenceLinkAudit.scenarioCount > 0 {
            lines.append(evidenceLinkAudit.summaryLine)
            for report in evidenceLinkAudit.scenarioReports.prefix(6) {
                lines.append("  \(report.summaryLine)")
            }
            if evidenceLinkAudit.scenarioReports.count > 6 {
                lines.append("  + \(evidenceLinkAudit.scenarioReports.count - 6) more evidence scenario(s)")
            }
        }
        lines.append("top 10 priority fixes")
        for action in topActions.prefix(10) {
            lines.append("  \(action.compactLine)")
        }
        return lines
    }
}

enum WorldMapRichnessAuditor {
    static func auditAllReviewMaps(
        context: WorldGenerationContext = DevTestMode.worldGenerationContext
    ) -> WorldMapRichnessAuditReport {
        let reports = DevTestMode.MapReviewVariant.allCases.map { variant in
            audit(variant: variant, context: context)
        }
        let projectionReports = WorldProjectionAuditScenarioID.allCases.map { scenario in
            auditProjection(scenario: scenario, context: context)
        }
        return WorldMapRichnessAuditReport(
            variantReports: reports,
            projectionReports: projectionReports,
            evidenceLinkAudit: WorldEvidenceLinkAuditor.auditDebugScenarios(context: context)
        )
    }

    static func printAudit(
        context: WorldGenerationContext = DevTestMode.worldGenerationContext
    ) {
        let audit = auditAllReviewMaps(context: context)
        for line in audit.consoleLines {
            print("[WorldRichnessAudit] \(line)")
        }
    }

    private static func audit(
        variant: DevTestMode.MapReviewVariant,
        context: WorldGenerationContext
    ) -> WorldMapRichnessVariantReport {
        let map = TestMapFactory.reviewWorld(context: context, variant: variant)
        let validation = WorldMapValidator.validate(map)
        let actions = actions(for: validation, variantID: variant.rawValue)
        return WorldMapRichnessVariantReport(
            id: variant.rawValue,
            mapName: map.name,
            validation: validation,
            actions: actions
        )
    }

    private static func auditProjection(
        scenario: WorldProjectionAuditScenarioID,
        context: WorldGenerationContext
    ) -> WorldProjectionAuditScenarioReport {
        let map = TestMapFactory.reviewWorld(context: context, variant: scenario.mapVariant)
        let signal = signalBundle(for: scenario)
        let projection = WorldStateProjector().project(
            bundle: signal,
            baseMap: map,
            mapVariantID: scenario.mapVariant.rawValue
        )
        let validation = WorldMapValidator.validate(projection, baseMap: map)
        let actions = actions(for: validation, variantID: "projection:\(scenario.rawValue)")
        return WorldProjectionAuditScenarioReport(
            id: scenario.rawValue,
            mapVariantID: scenario.mapVariant.rawValue,
            projection: projection,
            validation: validation,
            actions: actions,
            projectedElementCount: projection.allElements.count,
            storyEchoCount: projection.storyTraceElements.count,
            cycleMarkerCount: projection.cycleMarkerElements.count,
            eraEchoCount: projection.eraEchoElements.count,
            ungroundedElementCount: projection.allElements.filter { PropKind(rawValue: $0.catalogElementID) == nil && AnimalKind(rawValue: $0.catalogElementID) == nil }.count,
            invalidHabitatCount: validation.issueCount(code: "animal_habitat_mismatch"),
            pathObstructionCount: validation.issues.filter { ["pico_spawn_blocked", "pico_no_reachable_tiles", "pico_no_path_connection"].contains($0.code) }.count,
            occlusionRiskCount: validation.picoOcclusionRiskCount,
            missingEvidenceCount: validation.issues.filter { $0.code.contains("missing_evidence") || $0.code.contains("missing_source") }.count
        )
    }

    static func actions(
        for report: WorldMapValidationReport,
        variantID: String
    ) -> [WorldRichnessAction] {
        report.issues.enumerated().map { index, issue in
            action(for: issue, mapName: report.mapName, variantID: variantID, index: index)
        }
    }

    private static func signalBundle(for scenario: WorldProjectionAuditScenarioID) -> WorldSignalBundle {
        switch scenario {
        case .emptyFreshInstall:
            return baseSignal(
                key: "projection-empty-day1",
                day: 1,
                capture: .missing,
                participation: .unknown,
                moodTags: ["quiet"],
                evidence: []
            )
        case .day1Capture:
            return baseSignal(
                key: "projection-day1-capture",
                day: 1,
                capture: .captured,
                participation: .minimal,
                colorFamily: "warm",
                moodTags: ["warm", "indoor", "captured"],
                pico: picoSignal(day: 1, changed: ["hatch"], memoryScar: nil),
                evidence: ["projection-life:day1", "photo:warm-indoor"]
            )
        case .day4RainyUmbrellaTrace:
            return baseSignal(
                key: "projection-day4-rain",
                day: 4,
                capture: .captured,
                participation: .partial,
                colorFamily: "cool",
                weather: ["rain"],
                moodTags: ["rain", "wet", "trace"],
                pico: picoSignal(day: 4, changed: ["anomalyMark"], memoryScar: nil),
                stories: [
                    storySignal(
                        storylineID: "umbrella_woman",
                        state: .traceSeen,
                        recurrence: 1,
                        evidence: ["projection-life:day4"],
                        traces: ["trace:umbrella-woman:rain"]
                    )
                ],
                evidence: ["projection-life:day4", "photo:rainy-window", "trace:umbrella-woman:rain"]
            )
        case .day5NightLamplighterTrace:
            return baseSignal(
                key: "projection-day5-night",
                day: 5,
                capture: .captured,
                participation: .partial,
                colorFamily: "warm",
                time: ["night"],
                moodTags: ["night", "lamp", "remembered"],
                pico: picoSignal(day: 5, changed: ["memoryScar"], memoryScar: "small-warm-mark"),
                stories: [
                    storySignal(
                        storylineID: "night_lamplighter",
                        state: .encountered,
                        recurrence: 1,
                        evidence: ["projection-life:day5"],
                        traces: ["trace:night-lamplighter:lamp"]
                    )
                ],
                evidence: ["projection-life:day5", "photo:night-lamp", "trace:night-lamplighter:lamp"]
            )
        case .day7MirrorClosure:
            return baseSignal(
                key: "projection-day7-mirror",
                day: 7,
                capture: .closed,
                participation: .steady,
                colorFamily: "neutral",
                moodTags: ["final", "reflection", "return"],
                pico: picoSignal(day: 7, changed: ["returnToEgg"], memoryScar: "life-returned"),
                stories: [
                    storySignal(
                        storylineID: "mirror_miko",
                        state: .encountered,
                        recurrence: 1,
                        evidence: ["projection-life:day7"],
                        traces: ["trace:mirror-miko:return"]
                    )
                ],
                evidence: ["projection-life:day7", "trace:mirror-miko:return"]
            )
        case .completedLifeAlbum:
            return baseSignal(
                key: "projection-life-album",
                day: 7,
                capture: .closed,
                participation: .steady,
                colorFamily: "green",
                moodTags: ["album", "quiet", "completed"],
                pico: picoSignal(day: 7, changed: ["ageLayer"], memoryScar: "life-returned"),
                lifeAlbumSignals: ["lifeAlbum:projection-life", "dominantMood:quiet", "trait:soft-color"],
                evidence: ["lifeAlbum:projection-life"]
            )
        case .completedCycleRecord:
            return baseSignal(
                key: "projection-cycle-record",
                day: 7,
                capture: .closed,
                participation: .steady,
                moodTags: ["cycle", "marker"],
                cycleSignals: [
                    CycleWorldSignal(
                        cycleID: CycleID(rawValue: "projection-era-cycle-1"),
                        toriiCount: 1,
                        visitorSummary: "small repeated visitors",
                        weatherPatternSummary: "rain then clear",
                        participationPattern: "steady",
                        unresolvedAnomalyIDs: []
                    )
                ],
                evidence: ["projection-era-cycle-1"]
            )
        case .unlockedEraMemory:
            return baseSignal(
                key: "projection-era-memory",
                day: 7,
                cycle: 7,
                capture: .closed,
                participation: .steady,
                moodTags: ["era", "remembered"],
                stories: [
                    storySignal(
                        storylineID: "mirror_miko",
                        state: .remembered,
                        recurrence: 3,
                        evidence: ["projection-life:day7", "projection-era-1"],
                        traces: ["trace:mirror-miko:return", "trace:mirror-miko:echo"]
                    )
                ],
                eraSignals: [
                    EraWorldSignal(
                        eraID: EraID(rawValue: "projection-era-1"),
                        isLocked: false,
                        hasUnlockedMemory: true,
                        resetEchoLevel: 2,
                        persistentStoryCardIDs: ["story:mirror_miko"],
                        vanishedStoryCardIDs: []
                    )
                ],
                evidence: ["projection-era-1", "story:mirror_miko"]
            )
        case .lowParticipationLife:
            return baseSignal(
                key: "projection-low-participation",
                day: 5,
                capture: .missing,
                participation: .minimal,
                moodTags: ["still", "quiet"],
                missing: ["missing-day:2", "missing-day:4", "missing-day:5"],
                evidence: []
            )
        case .corruptPartialMemoryFallback:
            return baseSignal(
                key: "projection-corrupt-fallback",
                day: 1,
                capture: .missing,
                participation: .unknown,
                moodTags: ["fallback", "quiet"],
                missing: ["store-fallback"],
                evidence: []
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
        let eraID = EraID(rawValue: "projection-era-1")
        return WorldSignalBundle(
            id: "projection-signal:\(key)",
            localDayKey: PicodDayKey(rawValue: key),
            lifeID: LifeID(rawValue: "projection-life-1"),
            cycleID: CycleID(rawValue: "projection-era-cycle-\(cycle)"),
            eraID: eraID,
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
            diarySignals: capture == .missing ? ["diary:quiet-fallback"] : ["diary:\(key)"],
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
            debugSummary: "projection scenario \(key)"
        )
    }

    private static func picoSignal(day: Int, changed: [String], memoryScar: String?) -> PicoWorldSignal {
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
            anomalyMark: day >= 4 ? "faint-mark" : nil,
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

    private static func action(
        for issue: WorldMapValidationIssue,
        mapName: String,
        variantID: String,
        index: Int
    ) -> WorldRichnessAction {
        let recipe = recipe(for: issue)
        return WorldRichnessAction(
            id: "\(variantID)-\(issue.id)-action-\(index)",
            priority: recipe.priority,
            variantID: variantID,
            mapName: mapName,
            category: issue.category,
            issueCode: issue.code,
            coord: issue.coord,
            title: recipe.title,
            guidance: recipe.guidance
        )
    }

    private static func recipe(
        for issue: WorldMapValidationIssue
    ) -> (priority: WorldRichnessActionPriority, title: String, guidance: String) {
        switch issue.code {
        case "pico_spawn_off_map":
            return (
                .blocker,
                "Move Pico spawn back onto the board.",
                "Choose a readable path or clearing tile with nearby open movement space."
            )
        case "pico_spawn_blocked":
            return (
                .blocker,
                "Clear Pico spawn.",
                "Move blocking props away from spawn, or move spawn to a connected clear tile."
            )
        case "pico_no_reachable_tiles":
            return (
                .blocker,
                "Restore Pico movement.",
                "Open at least one connected walking region from spawn before adding more scenery."
            )
        case "pico_no_path_connection":
            return (
                .high,
                "Connect Pico to a path rhythm.",
                "Add a short wornPath, dirt, or stoneGround run from spawn toward the main memory board."
            )
        case "pico_spawn_occlusion_risk":
            return (
                .high,
                "Protect Pico spawn readability.",
                "Move tall canopy or structure sprites farther from spawn, or reduce their foreground overlap."
            )
        case "pico_route_occlusion_risk":
            return (
                .high,
                "Protect common Pico route.",
                "Move tall structures and canopy away from high-traffic path tiles, or keep them behind the route."
            )
        case "perimeter_forest_sparse":
            return (
                .medium,
                "Densify the outer forest edge.",
                "Add existing trees, bushes, logs, and flower pockets near the edge without crowding Pico paths."
            )
        case "water_connection_missing":
            return (
                .high,
                "Repair water contact.",
                "Move bridges, docks, reeds, or water props onto wetBank/shallowWater edges so they touch water."
            )
        case "disconnected_structure":
            return (
                .medium,
                "Give the structure a map connection.",
                "Add path, courtyard, threshold terrain, or support props so the building belongs to the board."
            )
        case "missing_approach_tile":
            return (
                .medium,
                "Add an approach tile.",
                "Keep one reachable tile beside the structure entrance so Pico and the diary can point to it."
            )
        case "terrain_mismatch":
            return (
                .low,
                "Align terrain under the object.",
                "Change the anchor terrain or move the object to its preferred terrain family."
            )
        case "animal_habitat_mismatch":
            return (
                .low,
                "Return visitor to matching habitat.",
                "Keep water visitors in water-like terrain and land visitors on readable land tiles."
            )
        default:
            return (
                issue.severity == .error ? .high : .low,
                "Review placement issue.",
                issue.message
            )
        }
    }
}

private extension WorldMapValidationReport {
    func issueCount(code: String) -> Int {
        issues.filter { $0.code == code }.count
    }
}
