import Foundation

struct StoryTriggerContext: Hashable {
    let progress: PicodProgressRecord
    let weatherCondition: PicodWeatherCondition
    let timePhase: PicodTimePhase
    let localHour: Int
    let recentParticipationStates: [PicodParticipationState]
    let alreadyFiredBeatIds: Set<String>
}

struct StoryBeatActivation: Codable, Hashable, Identifiable {
    let id: String
    let characterKind: NarrativeCharacterKind
    let window: String
    let reasonTags: [String]
    let priority: Int
}

struct StoryTriggerEngine {
    func eligibleBeats(context: StoryTriggerContext) -> [StoryBeatActivation] {
        NarrativeCharacterDatabase.profiles.values
            .compactMap { profile in activation(for: profile, context: context) }
            .filter { !context.alreadyFiredBeatIds.contains($0.id) }
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
                return lhs.id < rhs.id
            }
    }

    private func activation(
        for profile: NarrativeCharacterProfile,
        context: StoryTriggerContext
    ) -> StoryBeatActivation? {
        let windows = profile.activeWindows.isEmpty ? ["any"] : profile.activeWindows
        guard let matchedWindow = windows.first(where: { matches(window: $0, context: context) }) else {
            return nil
        }

        let beatId = "\(profile.kind.rawValue):era\(context.progress.eraId):day\(context.progress.absoluteDayIndex):\(matchedWindow)"
        return StoryBeatActivation(
            id: beatId,
            characterKind: profile.kind,
            window: matchedWindow,
            reasonTags: profile.tags + [matchedWindow],
            priority: priority(for: matchedWindow, context: context)
        )
    }

    private func matches(window: String, context: StoryTriggerContext) -> Bool {
        switch window {
        case "any":
            return true
        case "dusk_or_night":
            return context.timePhase == .dusk || context.timePhase == .night
        case "day":
            return context.timePhase == .morning || context.timePhase == .afternoon
        case "dusk":
            return context.timePhase == .dusk
        case "night":
            return context.timePhase == .night
        case "deep_night":
            return context.timePhase == .night && (0..<4).contains(context.localHour)
        case "dawn":
            return (4..<7).contains(context.localHour)
        case "rain":
            return context.weatherCondition == .rain || context.weatherCondition == .storm
        case "fog":
            return context.weatherCondition == .fog
        case "rain_or_fog":
            return context.weatherCondition == .rain || context.weatherCondition == .storm || context.weatherCondition == .fog
        case "cycle2":
            return context.progress.cycleIndex >= 2
        case "day4_evening":
            return context.progress.dayInCycle >= 4 && (context.timePhase == .dusk || context.timePhase == .night)
        case "torii_depth":
            return context.progress.cycleIndex >= 2
        case "reflection":
            return context.progress.interactionRecordCount > 0 || context.progress.cycleIndex >= 2
        case "water":
            return context.progress.worldSeedGenerationId != nil
        case "forest":
            return context.progress.interactionRecordCount > 0
        case "idle_hours":
            return context.progress.participationState != .captured
        case "low_participation":
            return context.recentParticipationStates.suffix(3).contains(.absent)
        case "late_cycle":
            return context.progress.absoluteDayIndex >= 35 || context.progress.cycleIndex >= 5
        case "cycle7":
            return context.progress.cycleIndex == 7
        case "post_hatch_wait":
            return context.progress.dayInCycle >= 2
        default:
            return false
        }
    }

    private func priority(for window: String, context: StoryTriggerContext) -> Int {
        var value = context.progress.cycleIndex * 10 + context.progress.dayInCycle
        if window == "cycle7" || window == "late_cycle" {
            value += 100
        }
        if window == "low_participation" {
            value += 20
        }
        if context.progress.isEraFinalDay {
            value += 50
        }
        return value
    }
}
