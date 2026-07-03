import Foundation

struct StoryBeat: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: String
    let storylineID: String
    let characterKind: NarrativeCharacterKind
    let reasonTags: [String]
    let occurredAt: Date
}

struct MapTrace: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: String
    let storylineID: String
    let traceKind: String
    let mapMood: String
    let visualHint: String
}

struct DiaryInfluence: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: String
    let storylineID: String
    let optionalDiaryPhrase: String?
    let toneTags: [String]
}

struct StoryCardProgression: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: String
    let storylineID: String
    let nextDisplayState: StoryCardDisplayState
    let evidenceDailyRecordID: String?
    let diaryEntryID: String?
    let mapTraceID: String?
    let recurrenceDelta: Int
    let isEraRelevant: Bool
}

struct PicodStoryEventBundle: Codable, Hashable {
    var schemaVersion: Int? = 1
    let beats: [StoryBeat]
    let mapTraces: [MapTrace]
    let diaryInfluences: [DiaryInfluence]
    let cardProgressions: [StoryCardProgression]
}

enum PicodP0StoryRegistry {
    nonisolated static let activeStoryKinds: Set<NarrativeCharacterKind> = [
        .nightLamplighter,
        .umbrellaWoman,
        .mirrorMiko
    ]

    nonisolated static let specReadyStoryKinds: Set<NarrativeCharacterKind> = [
        .lostBackpacker,
        .toriiBetweenLight,
        .doorKnocker
    ]
}

extension StoryBeatActivation {
    var isP0ActiveStory: Bool {
        PicodP0StoryRegistry.activeStoryKinds.contains(characterKind)
    }
}

struct PicodStoryEventNormalizer {
    func normalize(
        activations: [StoryBeatActivation],
        occurredAt: Date,
        languageCode: String,
        dailyRecordID: String?
    ) -> PicodStoryEventBundle {
        let filtered = activations.filter(\.isP0ActiveStory)
        let beats = filtered.map {
            StoryBeat(
                id: $0.id,
                storylineID: $0.characterKind.rawValue,
                characterKind: $0.characterKind,
                reasonTags: $0.reasonTags,
                occurredAt: occurredAt
            )
        }
        let traces = filtered.map {
            MapTrace(
                id: "trace:\($0.id)",
                storylineID: $0.characterKind.rawValue,
                traceKind: traceKind(for: $0.characterKind),
                mapMood: mapMood(for: $0.characterKind),
                visualHint: visualHint(for: $0.characterKind)
            )
        }
        let influences = filtered.map {
            DiaryInfluence(
                id: "diary:\($0.id)",
                storylineID: $0.characterKind.rawValue,
                optionalDiaryPhrase: NarrativeCharacterDatabase.dialogue(
                    for: $0.characterKind,
                    languageCode: languageCode,
                    channel: .encounter,
                    seed: $0.id.hashValue
                ),
                toneTags: toneTags(for: $0.characterKind)
            )
        }
        let progressions = filtered.map {
            StoryCardProgression(
                id: "card:\($0.id)",
                storylineID: $0.characterKind.rawValue,
                nextDisplayState: .encountered,
                evidenceDailyRecordID: dailyRecordID,
                diaryEntryID: dailyRecordID.map { "diary:\($0)" },
                mapTraceID: "trace:\($0.id)",
                recurrenceDelta: 1,
                isEraRelevant: $0.characterKind == .mirrorMiko
            )
        }
        return PicodStoryEventBundle(
            beats: beats,
            mapTraces: traces,
            diaryInfluences: influences,
            cardProgressions: progressions
        )
    }

    private func traceKind(for kind: NarrativeCharacterKind) -> String {
        switch kind {
        case .nightLamplighter: return "lamp-light"
        case .umbrellaWoman: return "umbrella-edge"
        case .mirrorMiko: return "delayed-reflection"
        default: return "quiet-trace"
        }
    }

    private func mapMood(for kind: NarrativeCharacterKind) -> String {
        switch kind {
        case .nightLamplighter: return "lit-night"
        case .umbrellaWoman: return "rain-watched"
        case .mirrorMiko: return "still-water"
        default: return "quiet"
        }
    }

    private func visualHint(for kind: NarrativeCharacterKind) -> String {
        switch kind {
        case .nightLamplighter: return "one lantern warms after Pico passes"
        case .umbrellaWoman: return "a small umbrella shape waits near the edge"
        case .mirrorMiko: return "a reflection lingers longer than the figure"
        default: return "the map keeps a small mark"
        }
    }

    private func toneTags(for kind: NarrativeCharacterKind) -> [String] {
        switch kind {
        case .nightLamplighter: return ["calm", "night", "lantern"]
        case .umbrellaWoman: return ["rain", "edge", "watched"]
        case .mirrorMiko: return ["reflection", "memory", "quiet"]
        default: return ["quiet"]
        }
    }
}
