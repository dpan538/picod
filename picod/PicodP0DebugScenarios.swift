import Foundation

struct PicodP0DebugResult: Codable, Hashable, Identifiable {
    let id: String
    let passed: Bool
    let summary: String
}

struct PicodP0DebugSummary: Codable, Hashable {
    var schemaVersion: Int? = 1
    let ranAt: Date
    let results: [PicodP0DebugResult]
    let generatedDailyLifeRecordsCount: Int
    let generatedLifeAlbumsCount: Int
    let generatedCycleRecordsCount: Int
    let generatedStoryCardsCount: Int
    let generatedEraMemoriesCount: Int
    let logLines: [String]

    var passedScenarioCount: Int { results.filter(\.passed).count }
    var failedScenarioCount: Int { results.filter { !$0.passed }.count }
}

enum PicodP0DebugScenarios {
    @MainActor
    static func runAll() -> [PicodP0DebugResult] {
        runSummary().results
    }

    @MainActor
    static func runSummary() -> PicodP0DebugSummary {
        let urls = makeDebugStoreURLs()
        let memoryStore = makeMemoryStore(urls: urls)
        var results: [PicodP0DebugResult] = []
        var logLines: [String] = []

        let highLife = simulateSevenDayLife(
            memoryStore: memoryStore,
            eraID: "debug-era-acceptance",
            cycle: 1,
            generationID: "debug-life-high",
            capturedDays: Set(1...7),
            logLines: &logLines
        )
        results.append(contentsOf: highLife.results)

        let duplicateBefore = memoryStore.storyCards.first { $0.storylineID == NarrativeCharacterKind.nightLamplighter.rawValue }?.recurrenceCount ?? 0
        if let dayFive = highLife.records.first(where: { $0.dayIndexInLife.rawValue == 5 }) {
            memoryStore.storyCardStore.apply(
                progressions: [
                    StoryCardProgression(
                        id: "debug-duplicate-lamplighter",
                        storylineID: NarrativeCharacterKind.nightLamplighter.rawValue,
                        nextDisplayState: .encountered,
                        evidenceDailyRecordID: dayFive.id,
                        diaryEntryID: "diary:\(dayFive.id)",
                        mapTraceID: dayFive.storyTraceIDs.first,
                        recurrenceDelta: 1,
                        isEraRelevant: false
                    )
                ],
                fallbackRecordID: dayFive.id,
                at: Date()
            )
        }
        let duplicateAfter = memoryStore.storyCards.first { $0.storylineID == NarrativeCharacterKind.nightLamplighter.rawValue }?.recurrenceCount ?? 0
        results.append(PicodP0DebugResult(
            id: "story-card-evidence-dedup",
            passed: duplicateBefore == duplicateAfter,
            summary: "StoryCard evidence replay kept recurrence at \(duplicateAfter)"
        ))

        let lowLife = simulateSevenDayLife(
            memoryStore: memoryStore,
            eraID: "debug-era-acceptance",
            cycle: 2,
            generationID: "debug-life-low",
            capturedDays: [1, 4],
            logLines: &logLines
        )
        results.append(contentsOf: lowLife.results.filter { $0.id == "low-participation-placeholders" })

        results.append(simulateCorruptJSONFallback(logLines: &logLines))
        results.append(simulatePassiveLifecycleReconciliation(logLines: &logLines))
        results.append(simulateAppReload(urls: urls, original: memoryStore, logLines: &logLines))
        results.append(contentsOf: simulateEraBoundary(memoryStore: memoryStore, logLines: &logLines))

        let validationIssues = validateStores(memoryStore)
        results.append(PicodP0DebugResult(
            id: "memory-store-validation",
            passed: validationIssues.isEmpty,
            summary: validationIssues.isEmpty
                ? "memory objects validated after deterministic writes"
                : validationIssues.prefix(3).joined(separator: " | ")
        ))

        let summary = PicodP0DebugSummary(
            ranAt: Date(),
            results: results,
            generatedDailyLifeRecordsCount: memoryStore.dailyRecords.count,
            generatedLifeAlbumsCount: memoryStore.lifeAlbums.count,
            generatedCycleRecordsCount: memoryStore.cycleRecords.count,
            generatedStoryCardsCount: memoryStore.storyCards.count,
            generatedEraMemoriesCount: memoryStore.eraMemories.count,
            logLines: logLines
        )

        print("[PicodP0Debug] passed=\(summary.passedScenarioCount) failed=\(summary.failedScenarioCount)")
        print("[PicodP0Debug] daily=\(summary.generatedDailyLifeRecordsCount) albums=\(summary.generatedLifeAlbumsCount) cycles=\(summary.generatedCycleRecordsCount) cards=\(summary.generatedStoryCardsCount) eras=\(summary.generatedEraMemoriesCount)")
        for result in results {
            print("[PicodP0Debug] \(result.passed ? "PASS" : "FAIL") \(result.id): \(result.summary)")
        }
        for line in logLines {
            print("[PicodP0Debug] \(line)")
        }

        try? FileManager.default.removeItem(at: urls.directory)
        return summary
    }

    @MainActor
    private static func simulateSevenDayLife(
        memoryStore: PicodMemoryStore,
        eraID: String,
        cycle: Int,
        generationID: String,
        capturedDays: Set<Int>,
        logLines: inout [String]
    ) -> (results: [PicodP0DebugResult], records: [DailyLifeRecord], finalGenome: PicoGenome?) {
        var results: [PicodP0DebugResult] = []
        var existingSnapshots: [PhotoTraitSnapshot] = []
        var previousGenome: PicoGenome?
        var decisions: [PicoEvolutionDecision] = []
        var records: [DailyLifeRecord] = []

        for day in 1...7 {
            let progress = fakeProgress(
                day: day,
                cycle: cycle,
                eraID: eraID,
                generationID: generationID,
                participation: capturedDays.contains(day) ? .captured : .absent
            )
            if !capturedDays.contains(day) {
                memoryStore.recordMissingDay(progress: progress, createdAt: progress.dayStartAt)
                continue
            }

            let labels = debugLabels(day: day)
            let palette = debugPalette(day: day)
            let worldInput = fakeWorldInput(
                date: progress.dayStartAt,
                timePhase: debugTimePhase(day: day),
                weather: day == 4 ? .rain : .clear
            )
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
                    participation: generationParticipation(capturedDays: Set(capturedDays.filter { $0 < day })),
                    activeStoryBeatIDs: debugStoryBeatIDs(day: day),
                    photoMetadata: nil,
                    languageCode: "en",
                    isNightClosure: false
                )
            )
            let record = memoryStore.recordDailyCapture(
                progress: progress,
                snapshot: result.photoSnapshot,
                seedMatch: result.seedMatch,
                evolution: result.evolutionDecision,
                worldSeed: nil,
                storyBundle: result.storyBundle,
                mapMood: result.mapMood,
                createdAt: progress.dayStartAt
            )
            existingSnapshots.append(result.photoSnapshot)
            previousGenome = result.evolutionDecision.genomeAfter
            decisions.append(result.evolutionDecision)
            records.append(record)

            logLines.append(
                "day\(day) seed=\(result.seedMatch.selectedSeedID) form=\(result.evolutionDecision.renderedFormID) changed=\(result.evolutionDecision.changedMajorTrait ?? "none") before=\(result.evolutionDecision.genomeBefore?.renderedFormID.description ?? "nil") after=\(result.evolutionDecision.genomeAfter.renderedFormID) reasons=\(result.evolutionDecision.reasonTags.joined(separator: ","))"
            )
        }

        let closeProgress = fakeProgress(
            day: 7,
            cycle: cycle,
            eraID: eraID,
            generationID: generationID,
            participation: capturedDays.contains(7) ? .captured : .absent
        )
        let album = memoryStore.closeLifeIfReady(
            progress: closeProgress,
            now: closeProgress.dayStartAt.addingTimeInterval(20 * 60 * 60),
            closingDiaryText: "I curl back into a small quiet shape."
        )
        let cycleRecord = memoryStore.closeCycleIfReady(
            progress: closeProgress,
            now: closeProgress.dayStartAt.addingTimeInterval(20 * 60 * 60),
            worldSeed: nil
        )
        records = memoryStore.currentLifeRecords(lifeID: LifeID(rawValue: generationID))

        if generationID == "debug-life-high" {
            results.append(PicodP0DebugResult(
                id: "day1-hatch-warm-indoor",
                passed: decisions.first?.changedMajorTrait == "hatch"
                    && decisions.first?.genomeAfter.ageLayer == 1
                    && decisions.first?.reasonTags.contains("hatch:first-photo") == true,
                summary: "Day 1 hatch produced seed \(decisions.first?.genomeAfter.seedLineageIDs.first ?? "none")"
            ))
            results.append(PicodP0DebugResult(
                id: "day2-inheritance-minor-mutation",
                passed: decisions[safe: 1]?.genomeBefore == decisions[safe: 0]?.genomeAfter
                    && decisions[safe: 1]?.changedMajorTrait == "textureTrait"
                    && decisions[safe: 1]?.genomeAfter.coreColor == decisions[safe: 0]?.genomeAfter.coreColor,
                summary: "Day 2 inherited prior genome and changed \(decisions[safe: 1]?.changedMajorTrait ?? "none")"
            ))
            results.append(PicodP0DebugResult(
                id: "day3-appendage-habit-mutation",
                passed: decisions[safe: 2]?.changedMajorTrait == "appendageTrait",
                summary: "Day 3 changed \(decisions[safe: 2]?.changedMajorTrait ?? "none")"
            ))
            results.append(PicodP0DebugResult(
                id: "day4-umbrella-trace",
                passed: records.first(where: { $0.dayIndexInLife.rawValue == 4 })?.storyBeatIDs.contains(where: { $0.contains(NarrativeCharacterKind.umbrellaWoman.rawValue) }) == true
                    && memoryStore.storyCards.contains(where: { $0.storylineID == NarrativeCharacterKind.umbrellaWoman.rawValue && !$0.evidenceDailyRecordIDs.isEmpty }),
                summary: "Day 4 rainy capture attached umbrella_woman evidence"
            ))
            results.append(PicodP0DebugResult(
                id: "day5-night-lamplighter-trace",
                passed: records.first(where: { $0.dayIndexInLife.rawValue == 5 })?.storyBeatIDs.contains(where: { $0.contains(NarrativeCharacterKind.nightLamplighter.rawValue) }) == true,
                summary: "Day 5 night capture attached night_lamplighter evidence"
            ))
            let lamplighter = memoryStore.storyCards.first { $0.storylineID == NarrativeCharacterKind.nightLamplighter.rawValue }
            results.append(PicodP0DebugResult(
                id: "day6-mature-story-recurrence",
                passed: decisions[safe: 5]?.changedMajorTrait == "eyeTrait"
                    && (lamplighter?.recurrenceCount ?? 0) >= 2,
                summary: "Day 6 mature trait and lamplighter recurrence=\(lamplighter?.recurrenceCount ?? 0)"
            ))
            let closureDecision = PicoEvolutionEngine().evolve(
                input: PicoEvolutionInput(
                    date: closeProgress.dayStartAt.addingTimeInterval(20 * 60 * 60),
                    dayIndexInLife: DayIndexInLife(7),
                    seedMatch: fakeSeedMatch(renderedFormID: decisions.last?.renderedFormID ?? 1),
                    photoSnapshot: existingSnapshots.last,
                    previousGenome: decisions.last?.genomeAfter,
                    activeStoryFlags: [NarrativeCharacterKind.mirrorMiko.rawValue],
                    isNightClosure: true
                )
            )
            results.append(PicodP0DebugResult(
                id: "day7-closure-mirror-return-egg",
                passed: album != nil
                    && cycleRecord != nil
                    && decisions.last?.genomeAfter.anomalyMark == "mirror-return"
                    && closureDecision.returnsToEgg
                    && closureDecision.genomeAfter.baseBody == "egg",
                summary: "Day 7 exported album=\(album?.id ?? "nil") cycle=\(cycleRecord?.id ?? "nil") and closure returns egg"
            ))
        } else {
            let missedSlots = album?.dayRecords.filter { !$0.didCapturePhoto }.count ?? 0
            results.append(PicodP0DebugResult(
                id: "low-participation-placeholders",
                passed: album?.dayRecords.count == 7 && missedSlots == 5,
                summary: "low participation Life stored \(missedSlots) missed-day placeholders"
            ))
        }

        return (results, records, previousGenome)
    }

    @MainActor
    private static func simulateEraBoundary(
        memoryStore: PicodMemoryStore,
        logLines: inout [String]
    ) -> [PicodP0DebugResult] {
        var results: [PicodP0DebugResult] = []
        let eraID = "debug-era-acceptance"
        let beforeFinal = fakeProgress(
            day: 7,
            cycle: 6,
            eraID: eraID,
            generationID: "debug-era-cycle6",
            participation: .captured
        )
        let lockedBeforeBoundary = memoryStore.closeEraIfReady(
            progress: beforeFinal,
            now: beforeFinal.dayStartAt.addingTimeInterval(20 * 60 * 60)
        ) == nil

        for cycle in 3...7 {
            let generationID = "debug-era-cycle\(cycle)"
            _ = simulateSevenDayLife(
                memoryStore: memoryStore,
                eraID: eraID,
                cycle: cycle,
                generationID: generationID,
                capturedDays: Set(1...7),
                logLines: &logLines
            )
        }

        let finalProgress = fakeProgress(
            day: 7,
            cycle: 7,
            eraID: eraID,
            generationID: "debug-era-cycle7",
            participation: .captured
        )
        let era = memoryStore.closeEraIfReady(
            progress: finalProgress,
            now: finalProgress.dayStartAt.addingTimeInterval(20 * 60 * 60)
        )
        let secondEra = memoryStore.closeEraIfReady(
            progress: finalProgress,
            now: finalProgress.dayStartAt.addingTimeInterval(21 * 60 * 60)
        )

        results.append(PicodP0DebugResult(
            id: "era-memory-boundary",
            passed: lockedBeforeBoundary
                && era != nil
                && secondEra?.id == era?.id
                && memoryStore.eraMemories.count == 1,
            summary: "EraMemory locked before 49 days and unlocked idempotently after cycle 7"
        ))
        return results
    }

    @MainActor
    private static func simulateCorruptJSONFallback(logLines: inout [String]) -> PicodP0DebugResult {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("picod_corrupt_life_albums.json")
        try? Data("{not-json".utf8).write(to: temp, options: .atomic)
        let store = LifeAlbumStore(fileURL: temp)
        let passed = store.albums.isEmpty
        try? FileManager.default.removeItem(at: temp)
        logLines.append("corrupt-json fallback albums=\(store.albums.count)")
        return PicodP0DebugResult(
            id: "corrupt-json-fallback",
            passed: passed,
            summary: passed ? "corrupt JSON fell back to empty store" : "corrupt JSON did not fall back safely"
        )
    }

    @MainActor
    private static func simulatePassiveLifecycleReconciliation(logLines: inout [String]) -> PicodP0DebugResult {
        let urls = makeDebugStoreURLs()
        let memoryStore = makeMemoryStore(urls: urls)
        let progressURL = urls.directory.appendingPathComponent("progress.json")
        let worldURL = urls.directory.appendingPathComponent("world_seed.json")
        let progressStore = PicodProgressStore(fileURL: progressURL)
        let worldSeedDatabase = WorldSeedDatabase(fileURL: worldURL)
        let diaryDatabase = PicoDiaryDatabase()
        let timezone = "Asia/Shanghai"
        let firstNoon = Date(timeIntervalSince1970: 1_767_247_200 + 12 * 60 * 60)

        for offset in 0...7 {
            let date = firstNoon.addingTimeInterval(Double(offset) * 86_400)
            _ = progressStore.ensureToday(
                now: date,
                timezoneIdentifier: timezone,
                preferredGenerationId: offset == 0 ? "debug-passive-life" : nil
            )
        }

        let result = PicodLifecycleReconciler().reconcile(
            now: firstNoon.addingTimeInterval(7 * 86_400),
            timezoneIdentifier: timezone,
            languageCode: "en",
            latestFormID: 0,
            progressStore: progressStore,
            memoryStore: memoryStore,
            worldSeedDatabase: worldSeedDatabase,
            diaryDatabase: diaryDatabase,
            preferredGenerationID: nil
        )
        let album = memoryStore.lifeAlbums.first
        let passed = result.closedLifeAlbumIDs.count == 1
            && result.didReturnToEgg
            && album?.dayRecords.count == 7
            && album?.dayRecords.allSatisfy({ !$0.didCapturePhoto }) == true
        logLines.append("passive-reconcile closed=\(result.closedLifeAlbumIDs.count) placeholders=\(result.placeholderDailyRecordCount)")
        try? FileManager.default.removeItem(at: urls.directory)
        return PicodP0DebugResult(
            id: "passive-lifecycle-reconciliation",
            passed: passed,
            summary: "foreground reconciliation closed \(result.closedLifeAlbumIDs.count) Life Album(s) with \(result.placeholderDailyRecordCount) placeholders"
        )
    }

    @MainActor
    private static func simulateAppReload(
        urls: DebugStoreURLs,
        original: PicodMemoryStore,
        logLines: inout [String]
    ) -> PicodP0DebugResult {
        let reloaded = makeMemoryStore(urls: urls)
        let passed = reloaded.dailyRecords.count == original.dailyRecords.count
            && reloaded.lifeAlbums.count == original.lifeAlbums.count
            && reloaded.cycleRecords.count == original.cycleRecords.count
            && reloaded.storyCards.count == original.storyCards.count
            && reloaded.eraMemories.count == original.eraMemories.count
        logLines.append("reload daily=\(reloaded.dailyRecords.count) albums=\(reloaded.lifeAlbums.count) cycles=\(reloaded.cycleRecords.count) cards=\(reloaded.storyCards.count)")
        return PicodP0DebugResult(
            id: "app-relaunch-store-reload",
            passed: passed,
            summary: "reload daily=\(reloaded.dailyRecords.count) albums=\(reloaded.lifeAlbums.count) cycles=\(reloaded.cycleRecords.count) cards=\(reloaded.storyCards.count)"
        )
    }

    @MainActor
    private static func validateStores(_ store: PicodMemoryStore) -> [String] {
        var issues: [String] = []
        issues.append(contentsOf: PicodMemoryValidation.validateMemoryIndex(
            store.index,
            dailyRecords: store.dailyRecords,
            albums: store.lifeAlbums,
            cycleRecords: store.cycleRecords,
            storyCards: store.storyCards,
            eraMemories: store.eraMemories
        ))
        for album in store.lifeAlbums {
            issues.append(contentsOf: PicodMemoryValidation.validateLifeAlbum(album))
        }
        for record in store.cycleRecords {
            issues.append(contentsOf: PicodMemoryValidation.validateCycleRecord(record, albums: store.lifeAlbums))
        }
        for card in store.storyCards {
            issues.append(contentsOf: PicodMemoryValidation.validateStoryCard(card))
        }
        for memory in store.eraMemories {
            issues.append(contentsOf: PicodMemoryValidation.validateEraMemory(memory, cycleRecords: store.cycleRecords))
        }
        return issues
    }

    private static func debugLabels(day: Int) -> [VisionLabel] {
        let labels: [(String, Float)]
        switch day {
        case 1: labels = [("warm indoor lamp", 0.86), ("table", 0.62)]
        case 2: labels = [("paper book", 0.82), ("warm cloth", 0.58)]
        case 3: labels = [("bird path", 0.84), ("sky", 0.55)]
        case 4: labels = [("rain umbrella", 0.88), ("street", 0.52)]
        case 5: labels = [("night lantern", 0.89), ("stone", 0.56)]
        case 6: labels = [("night lantern", 0.91), ("window", 0.57)]
        default: labels = [("mirror reflection", 0.90), ("water", 0.60)]
        }
        return labels.map { VisionLabel(identifier: $0.0, confidence: $0.1) }
    }

    private static func debugPalette(day: Int) -> [PhotoPaletteColor] {
        switch day {
        case 1:
            return [
                PhotoPaletteColor(red: 0.82, green: 0.58, blue: 0.34, alpha: 1),
                PhotoPaletteColor(red: 0.96, green: 0.82, blue: 0.56, alpha: 1)
            ]
        case 2:
            return [
                PhotoPaletteColor(red: 0.80, green: 0.60, blue: 0.38, alpha: 1),
                PhotoPaletteColor(red: 0.90, green: 0.86, blue: 0.72, alpha: 1)
            ]
        case 4:
            return [
                PhotoPaletteColor(red: 0.30, green: 0.42, blue: 0.56, alpha: 1),
                PhotoPaletteColor(red: 0.50, green: 0.60, blue: 0.68, alpha: 1)
            ]
        case 5, 6:
            return [
                PhotoPaletteColor(red: 0.18, green: 0.20, blue: 0.30, alpha: 1),
                PhotoPaletteColor(red: 0.92, green: 0.72, blue: 0.38, alpha: 1)
            ]
        case 7:
            return [
                PhotoPaletteColor(red: 0.70, green: 0.78, blue: 0.84, alpha: 1),
                PhotoPaletteColor(red: 0.46, green: 0.52, blue: 0.62, alpha: 1)
            ]
        default:
            return [
                PhotoPaletteColor(red: 0.62, green: 0.72, blue: 0.54, alpha: 1),
                PhotoPaletteColor(red: 0.82, green: 0.68, blue: 0.42, alpha: 1)
            ]
        }
    }

    private static func debugTimePhase(day: Int) -> PicodTimePhase {
        switch day {
        case 4: return .dusk
        case 5, 6, 7: return .night
        default: return .afternoon
        }
    }

    private static func debugStoryBeatIDs(day: Int) -> [String] {
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

    private static func generationParticipation(capturedDays: Set<Int>) -> GenerationParticipation {
        GenerationParticipation(
            daysPhotographed: capturedDays.count,
            consecutiveDays: longestConsecutiveDays(in: capturedDays),
            firstDayParticipated: capturedDays.contains(1)
        )
    }

    private static func longestConsecutiveDays(in days: Set<Int>) -> Int {
        var longest = 0
        var current = 0
        for day in 1...7 {
            if days.contains(day) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }
        return longest
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
        participation: PicodParticipationState
    ) -> PicodProgressRecord {
        let absolute = (cycle - 1) * 7 + day
        let start = Date(timeIntervalSince1970: 1_767_247_200 + Double((absolute - 1) * 86_400))
        return PicodProgressRecord(
            eraId: eraID,
            absoluteDayIndex: absolute,
            cycleIndex: cycle,
            dayInCycle: day,
            calendarDayKey: "debug-\(cycle)-\(day)",
            dayStartAt: start,
            generationId: generationID,
            photoSnapshotDayKey: nil,
            interactionRecordCount: day >= 4 ? 1 : 0,
            diarySummaryDayKey: nil,
            worldSeedGenerationId: day >= 4 ? "debug-world" : nil,
            firedStoryBeatIds: [],
            participationState: participation,
            openedAt: start,
            finalizedAt: day == 7 ? start.addingTimeInterval(20 * 60 * 60) : nil
        )
    }

    private static func fakeSeedMatch(renderedFormID: Int) -> PhotoSeedMatch {
        PhotoSeedMatch(
            selectedSeedID: "form_\(renderedFormID)",
            renderedFormID: renderedFormID,
            confidence: 0.72,
            topAlternativeSeeds: [],
            semanticReasonTags: ["debug"],
            colorReasonTags: ["debug"],
            timeWeatherReasonTags: ["debug"],
            storyGateReasonTags: ["story:\(NarrativeCharacterKind.mirrorMiko.rawValue)"],
            debugInfo: PhotoSeedDecisionDebugInfo(
                componentWeights: [:],
                candidateScores: [:],
                normalizedLabels: ["mirror"],
                dominantColorDescription: nil
            )
        )
    }

    @MainActor
    private static func makeMemoryStore(urls: DebugStoreURLs) -> PicodMemoryStore {
        PicodMemoryStore(
            fileURL: urls.index,
            lifeAlbumStore: LifeAlbumStore(fileURL: urls.lifeAlbums),
            cycleRecordStore: CycleRecordStore(fileURL: urls.cycleRecords),
            storyCardStore: StoryCardStore(fileURL: urls.storyCards),
            eraMemoryStore: EraMemoryStore(fileURL: urls.eraMemories)
        )
    }

    private static func makeDebugStoreURLs() -> DebugStoreURLs {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("picod_p0_debug_\(UUID().uuidString)", isDirectory: true)
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
}

private struct DebugStoreURLs {
    let directory: URL
    let index: URL
    let lifeAlbums: URL
    let cycleRecords: URL
    let storyCards: URL
    let eraMemories: URL
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
