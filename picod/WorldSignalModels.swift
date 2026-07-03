import Foundation

enum WorldCaptureState: String, Codable, Hashable {
    case captured
    case missing
    case future
    case closed
}

enum WorldParticipationState: String, Codable, Hashable {
    case unknown
    case absent
    case minimal
    case partial
    case steady
}

enum WorldSignalConfidenceBand: String, Codable, Hashable {
    case none
    case low
    case medium
    case high
}

enum WorldBrightnessBand: String, Codable, Hashable {
    case dark
    case dim
    case balanced
    case bright
}

enum WorldSaturationBand: String, Codable, Hashable {
    case muted
    case soft
    case vivid
}

enum WorldSignalSubtletyLevel: String, Codable, Hashable {
    case barelyVisible
    case subtle
    case clear
}

struct PhotoMoodSignal: Codable, Hashable {
    var schemaVersion: Int? = 1
    let dominantColorFamily: String?
    let brightnessBand: WorldBrightnessBand
    let saturationBand: WorldSaturationBand
    let semanticMoodTags: [String]
    let confidenceBand: WorldSignalConfidenceBand
}

struct PicoWorldSignal: Codable, Hashable {
    var schemaVersion: Int? = 1
    let renderedFormID: Int?
    let genomeTraits: [String: String]
    let changedTraits: [String]
    let anomalyMark: String?
    let memoryScar: String?
    let ageLayer: Int
}

struct StoryWorldSignal: Codable, Hashable {
    var schemaVersion: Int? = 1
    let storylineID: String
    let storyCardID: String?
    let displayState: StoryCardDisplayState?
    let recurrenceCount: Int
    let evidenceDailyRecordIDs: [String]
    let mapTraceIDs: [String]
    let suggestedWorldEcho: String?
    let subtletyLevel: WorldSignalSubtletyLevel
}

struct CycleWorldSignal: Codable, Hashable {
    var schemaVersion: Int? = 1
    let cycleID: CycleID?
    let toriiCount: Int
    let visitorSummary: String?
    let weatherPatternSummary: String?
    let participationPattern: String?
    let unresolvedAnomalyIDs: [String]
}

struct EraWorldSignal: Codable, Hashable {
    var schemaVersion: Int? = 1
    let eraID: EraID
    let isLocked: Bool
    let hasUnlockedMemory: Bool
    let resetEchoLevel: Int
    let persistentStoryCardIDs: [String]
    let vanishedStoryCardIDs: [String]
}

struct WorldSignalBundle: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: String
    let localDayKey: PicodDayKey
    let lifeID: LifeID
    let cycleID: CycleID
    let eraID: EraID
    let dayIndexInLife: DayIndexInLife
    let cycleIndexInEra: CycleIndexInEra
    let captureState: WorldCaptureState
    let participationState: WorldParticipationState
    let photoMoodSignals: [PhotoMoodSignal]
    let colorSignals: [String]
    let weatherSignals: [String]
    let timeOfDaySignals: [String]
    let picoEvolutionSignals: [PicoWorldSignal]
    let storySignals: [StoryWorldSignal]
    let diarySignals: [String]
    let mapTraceSignals: [String]
    let lifeAlbumSignals: [String]
    let cycleSignals: [CycleWorldSignal]
    let eraSignals: [EraWorldSignal]
    let missingDaySignals: [String]
    let evidenceIDs: [String]
    let debugSummary: String

    var primaryPhotoMood: PhotoMoodSignal? {
        photoMoodSignals.first
    }

    var primaryPicoSignal: PicoWorldSignal? {
        picoEvolutionSignals.first
    }
}
