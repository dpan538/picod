import Foundation
import UIKit

struct DailyCaptureOrchestratorInput {
    let capturedPhoto: UIImage?
    let rawVisionLabels: [VisionLabel]
    let colorPalette: [PhotoPaletteColor]
    let localDate: Date
    let progress: PicodProgressRecord
    let existingSnapshots: [PhotoTraitSnapshot]
    let previousGenome: PicoGenome?
    let worldInput: PicodWorldInput
    let participation: GenerationParticipation
    let activeStoryBeatIDs: [String]
    let photoMetadata: PhotoCaptureMetadata?
    let languageCode: String
    let isNightClosure: Bool
}

struct DailyCaptureOrchestratorResult {
    let photoSnapshot: PhotoTraitSnapshot
    let seedMatch: PhotoSeedMatch
    let evolutionDecision: PicoEvolutionDecision
    let renderResult: PicoRenderResult
    let storyBundle: PicodStoryEventBundle
    let classificationOutput: PhotoClassificationPipelineOutput
    let mapMood: String
}

struct DailyCaptureOrchestrator {
    func run(input: DailyCaptureOrchestratorInput) -> DailyCaptureOrchestratorResult {
        let dominantColor = PhotoSeedMatcher.hsb(from: input.colorPalette.first)
        let matcherInput = PhotoSeedMatcherInput(
            visionLabels: input.rawVisionLabels,
            dominantColor: dominantColor,
            colorPalette: input.colorPalette,
            timePhase: input.worldInput.volatile.timePhase,
            weather: input.worldInput.volatile.weather.condition,
            coarseLocationTag: coarseLocationTag(from: input.worldInput),
            dayIndexInLife: DayIndexInLife(input.progress.dayInCycle),
            previousGenome: input.previousGenome,
            participationRhythm: input.participation.level,
            activeStoryFlags: Set(input.activeStoryBeatIDs.map(Self.storyFlag(from:)))
        )
        let seedMatch = PhotoSeedMatcher().match(input: matcherInput)
        let render = PicoFormRenderer.render(
            generationId: input.progress.generationId,
            dayIndex: input.progress.dayInCycle,
            chosenFormId: seedMatch.renderedFormID,
            existingSnapshots: input.existingSnapshots
        )
        let normalizedLabels = input.rawVisionLabels
            .map { MappingDatabase.normalize($0.identifier) }
            .sorted()
        let snapshot = PhotoTraitSnapshot(
            dayKey: "\(input.progress.generationId)_day\(input.progress.dayInCycle)",
            generationId: input.progress.generationId,
            dayIndex: input.progress.dayInCycle,
            rawVisionTopN: input.rawVisionLabels.sorted { $0.confidence > $1.confidence },
            normalizedLabels: normalizedLabels,
            matchedClusterScores: clusterScores(from: seedMatch),
            chosenFormId: seedMatch.renderedFormID,
            replacedParts: render.replacedParts,
            colorPalette: input.colorPalette,
            captureMetadata: input.photoMetadata,
            captureEnvironment: PhotoCaptureEnvironmentSnapshot.from(worldInput: input.worldInput),
            timestamp: input.localDate
        )
        let evolution = PicoEvolutionEngine().evolve(
            input: PicoEvolutionInput(
                date: input.localDate,
                dayIndexInLife: DayIndexInLife(input.progress.dayInCycle),
                seedMatch: seedMatch,
                photoSnapshot: snapshot,
                previousGenome: input.previousGenome,
                activeStoryFlags: Set(input.activeStoryBeatIDs.map(Self.storyFlag(from:))),
                isNightClosure: input.isNightClosure
            )
        )
        let activations = input.activeStoryBeatIDs.compactMap(Self.activation(from:))
        let recordID = "\(input.progress.generationId):day\(input.progress.dayInCycle)"
        let storyBundle = PicodStoryEventNormalizer().normalize(
            activations: activations,
            occurredAt: input.localDate,
            languageCode: input.languageCode,
            dailyRecordID: recordID
        )
        let output = PhotoClassificationPipelineOutput(
            chosenFormId: seedMatch.renderedFormID,
            matchedClusterScores: snapshot.matchedClusterScores,
            rawVisionTopN: snapshot.rawVisionTopN,
            normalizedLabels: snapshot.normalizedLabels
        )

        return DailyCaptureOrchestratorResult(
            photoSnapshot: snapshot,
            seedMatch: seedMatch,
            evolutionDecision: evolution,
            renderResult: render,
            storyBundle: storyBundle,
            classificationOutput: output,
            mapMood: mapMood(from: seedMatch, worldInput: input.worldInput)
        )
    }

    func runWithVision(
        image: UIImage,
        inputBuilder: @escaping ([VisionLabel], [PhotoPaletteColor]) -> DailyCaptureOrchestratorInput
    ) async -> DailyCaptureOrchestratorResult {
        let labels = await PhotoClassificationPipeline.classify(image: image, topN: 20)
        let palette = PhotoTraitSnapshotDatabase.extractPalette(from: image, targetCount: 6)
        return run(input: inputBuilder(labels, palette))
    }

    private func clusterScores(from match: PhotoSeedMatch) -> [ClusterScore] {
        var scores: [ClusterScore] = [
            ClusterScore(
                formId: match.renderedFormID,
                clusterName: match.selectedSeedID,
                primaryScore: Float(match.confidence),
                hitCount: match.semanticReasonTags.count,
                matchedLabels: match.debugInfo.normalizedLabels,
                priorityWeight: 100
            )
        ]
        scores.append(contentsOf: match.topAlternativeSeeds.map {
            ClusterScore(
                formId: $0.renderedFormID,
                clusterName: $0.seedID,
                primaryScore: Float($0.confidence),
                hitCount: $0.reasonTags.count,
                matchedLabels: $0.reasonTags,
                priorityWeight: 50
            )
        })
        return scores
    }

    private func mapMood(from match: PhotoSeedMatch, worldInput: PicodWorldInput) -> String {
        if match.storyGateReasonTags.contains(where: { $0.contains("umbrella") }) {
            return "rain-watched"
        }
        if match.storyGateReasonTags.contains(where: { $0.contains("lamplighter") }) {
            return "lit-night"
        }
        switch worldInput.volatile.weather.condition {
        case .rain, .storm: return "rain-softened"
        case .fog: return "mist-still"
        case .snow: return "pale-quiet"
        case .clear, .cloudy, .unknown:
            break
        }
        switch worldInput.volatile.timePhase {
        case .night: return "night-calm"
        case .dusk: return "dusk-warm"
        case .morning: return "morning-clear"
        case .afternoon: return "day-quiet"
        }
    }

    private func coarseLocationTag(from input: PicodWorldInput) -> String? {
        if input.environmentalInfluence.waterBias > 0.65 { return "water" }
        if input.environmentalInfluence.greeneryBias > 0.65 { return "forest" }
        if input.environmentalInfluence.urbanBias > 0.65 { return "urban" }
        return nil
    }

    nonisolated private static func activation(from beatID: String) -> StoryBeatActivation? {
        let rawKind = beatID.split(separator: ":").first.map(String.init) ?? beatID
        guard let kind = NarrativeCharacterKind(rawValue: rawKind),
              PicodP0StoryRegistry.activeStoryKinds.contains(kind) else {
            return nil
        }
        let window = beatID.split(separator: ":").last.map(String.init) ?? "any"
        return StoryBeatActivation(
            id: beatID,
            characterKind: kind,
            window: window,
            reasonTags: ["p0", window],
            priority: 0
        )
    }

    nonisolated private static func storyFlag(from beatID: String) -> String {
        let raw = beatID.split(separator: ":").first.map(String.init) ?? beatID
        switch raw {
        case "nightLamplighter": return "night_lamplighter"
        case "umbrellaWoman": return "umbrella_woman"
        case "mirrorMiko": return "mirror_miko"
        default: return raw
        }
    }
}
