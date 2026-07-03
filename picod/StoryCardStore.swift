import Combine
import Foundation

@MainActor
final class StoryCardStore: ObservableObject {
    @Published private(set) var cards: [StoryCard] = []

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? PicodAtomicJSON.fileURL(named: "story_cards_db.json")
        load()
    }

    func apply(progressions: [StoryCardProgression], fallbackRecordID: String?, at date: Date) {
        for progression in progressions {
            upsertProgression(progression, fallbackRecordID: fallbackRecordID, at: date)
        }
        save()
    }

    func upsert(_ card: StoryCard) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        } else {
            cards.append(card)
        }
        sortAndBound()
        save()
    }

    func resetAll() {
        cards = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func upsertProgression(_ progression: StoryCardProgression, fallbackRecordID: String?, at date: Date) {
        let cardID = "story:\(progression.storylineID)"
        var card = cards.first(where: { $0.id == cardID }) ?? Self.makeLockedCard(storylineID: progression.storylineID)
        let evidenceID = progression.evidenceDailyRecordID ?? fallbackRecordID
        let alreadyHadEvidence = evidenceID.map { card.evidenceDailyRecordIDs.contains($0) } ?? false
        let alreadyHadDiary = progression.diaryEntryID.map { card.diaryEntryIDs.contains($0) } ?? false
        let alreadyHadTrace = progression.mapTraceID.map { card.mapTraceIDs.contains($0) } ?? false
        let hasAnyEvidenceInput = evidenceID != nil || progression.diaryEntryID != nil || progression.mapTraceID != nil
        let hasNewEvidence = !hasAnyEvidenceInput
            || (evidenceID != nil && !alreadyHadEvidence)
            || (progression.diaryEntryID != nil && !alreadyHadDiary)
            || (progression.mapTraceID != nil && !alreadyHadTrace)
        let recurrenceIncrement = hasNewEvidence ? progression.recurrenceDelta : 0

        card.displayState = nextState(current: card.displayState, requested: progression.nextDisplayState, recurrence: card.recurrenceCount + recurrenceIncrement)
        card.firstSeenAt = card.firstSeenAt ?? date
        card.lastSeenAt = date
        card.evidenceDailyRecordIDs = appendUnique(card.evidenceDailyRecordIDs, evidenceID)
        card.diaryEntryIDs = appendUnique(card.diaryEntryIDs, progression.diaryEntryID)
        card.mapTraceIDs = appendUnique(card.mapTraceIDs, progression.mapTraceID)
        card.recurrenceCount += recurrenceIncrement
        card.unlockedVisualLevel = min(3, max(card.unlockedVisualLevel, card.recurrenceCount))
        card.isEraRelevant = card.isEraRelevant || progression.isEraRelevant

        if let index = cards.firstIndex(where: { $0.id == cardID }) {
            cards[index] = card
        } else {
            cards.append(card)
        }
        sortAndBound()
    }

    private func nextState(current: StoryCardDisplayState, requested: StoryCardDisplayState, recurrence: Int) -> StoryCardDisplayState {
        if recurrence >= 3 { return .recurring }
        let rank: [StoryCardDisplayState: Int] = [
            .locked: 0,
            .traceSeen: 1,
            .encountered: 2,
            .recurring: 3,
            .remembered: 4
        ]
        return (rank[requested, default: 0] > rank[current, default: 0]) ? requested : current
    }

    private func appendUnique(_ values: [String], _ next: String?) -> [String] {
        guard let next, !next.isEmpty else { return values }
        var output = values
        if !output.contains(next) {
            output.append(next)
        }
        return Array(output.suffix(30))
    }

    private func sortAndBound() {
        cards.sort {
            if $0.displayState != $1.displayState {
                return $0.displayState.rawValue < $1.displayState.rawValue
            }
            return $0.id < $1.id
        }
        if cards.count > 80 {
            cards.removeFirst(cards.count - 80)
        }
    }

    private func load() {
        cards = PicodAtomicJSON.load([StoryCard].self, from: fileURL) ?? []
    }

    private func save() {
        PicodAtomicJSON.save(cards, to: fileURL)
    }

    private static func makeLockedCard(storylineID: String) -> StoryCard {
        let kind = NarrativeCharacterKind(rawValue: storylineID)
        let profile = kind.flatMap { NarrativeCharacterDatabase.profiles[$0] }
        return StoryCard(
            id: "story:\(storylineID)",
            storylineID: storylineID,
            displayState: .locked,
            title: profile?.titleEN ?? "A Quiet Trace",
            hiddenTitle: "Something remembered",
            shortDescription: "A small trace appears through diary, map, and repeated encounters.",
            firstSeenAt: nil,
            lastSeenAt: nil,
            firstSeenLifeID: nil,
            firstSeenCycleID: nil,
            evidenceDailyRecordIDs: [],
            diaryEntryIDs: [],
            mapTraceIDs: [],
            unlockedVisualLevel: 0,
            recurrenceCount: 0,
            isEraRelevant: false
        )
    }
}
