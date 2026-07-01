import Foundation

struct PicodStoryScheduleResult: Hashable {
    let candidates: [StoryBeatActivation]
    let scheduled: [StoryBeatActivation]

    var scheduledBeatIds: [String] {
        scheduled.map(\.id)
    }
}

struct PicodStoryScheduler {
    var maxActivationsPerDay = 1

    func evaluate(context: StoryTriggerContext) -> PicodStoryScheduleResult {
        let engine = StoryTriggerEngine()
        let candidates = engine.eligibleBeats(context: context)
        guard context.progress.firedStoryBeatIds.isEmpty else {
            return PicodStoryScheduleResult(candidates: candidates, scheduled: [])
        }
        guard context.progress.absoluteDayIndex > 1 else {
            return PicodStoryScheduleResult(candidates: candidates, scheduled: [])
        }

        let scheduled = Array(candidates.prefix(max(0, maxActivationsPerDay)))
        return PicodStoryScheduleResult(candidates: candidates, scheduled: scheduled)
    }
}
