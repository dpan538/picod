import Foundation

enum PicodDiaryTextBridge {
    static func fragment(for record: DailyLifeRecord?, languageCode: String) -> String {
        guard let record else {
            return languageCode == "zh"
                ? "这一天还在等一张照片。"
                : "This day is still waiting for one photo."
        }
        guard record.didCapturePhoto else {
            return languageCode == "zh"
                ? "我在这一天很安静，地图把空白也保存了下来。"
                : "I was quiet here. The map kept the empty space too."
        }

        if !record.storyBeatIDs.isEmpty {
            return storyFragment(for: record.storyBeatIDs, languageCode: languageCode)
        }
        if let mood = record.mapMood {
            return moodFragment(for: mood, languageCode: languageCode)
        }
        if record.renderedFormID != nil {
            return languageCode == "zh"
                ? "我从今天的照片里留下了一点形状。"
                : "I kept a small shape from today's photo."
        }
        return languageCode == "zh"
            ? "我记得今天的颜色，但还说不清它是什么。"
            : "I remember today's color, even if I cannot name it."
    }

    static func lifeRhythm(for album: LifeAlbum, languageCode: String) -> String {
        let captured = album.dayRecords.filter(\.didCapturePhoto).count
        let missed = max(0, 7 - captured)
        let mood = moodLabel(album.dominantLifeMood, languageCode: languageCode)
        let storyCount = album.unlockedStoryCardIDs.count

        if languageCode == "zh" {
            var lines = ["这七天有 \(captured) 天留下照片，\(missed) 天保持安静。"]
            lines.append("最常留下的感觉是：\(mood)。")
            if storyCount > 0 {
                lines.append("有 \(storyCount) 条故事痕迹跟着这次生命。")
            }
            return lines.joined(separator: "\n")
        }

        var lines = ["This Life held \(captured) captured day(s) and \(missed) quiet placeholder(s)."]
        lines.append("Its strongest mood was \(mood).")
        if storyCount > 0 {
            lines.append("\(storyCount) story trace(s) followed this Life.")
        }
        return lines.joined(separator: "\n")
    }

    static func evidenceLine(for record: DailyLifeRecord, languageCode: String) -> String {
        let day = record.dayIndexInLife.rawValue
        let fragment = fragment(for: record, languageCode: languageCode)
        let trace = record.storyTraceIDs.first.map { traceName($0, languageCode: languageCode) }
        if let trace {
            return languageCode == "zh"
                ? "第 \(day) 天 · \(fragment)\n痕迹：\(trace)"
                : "Day \(day) · \(fragment)\nTrace: \(trace)"
        }
        return languageCode == "zh"
            ? "第 \(day) 天 · \(fragment)"
            : "Day \(day) · \(fragment)"
    }

    static func stateLabel(_ state: StoryCardDisplayState, languageCode: String) -> String {
        switch state {
        case .locked:
            return languageCode == "zh" ? "未显现" : "not visible"
        case .traceSeen:
            return languageCode == "zh" ? "看见痕迹" : "trace seen"
        case .encountered:
            return languageCode == "zh" ? "遇见过" : "encountered"
        case .recurring:
            return languageCode == "zh" ? "再次出现" : "recurring"
        case .remembered:
            return languageCode == "zh" ? "被记住" : "remembered"
        }
    }

    static func shortDate(_ date: Date, languageCode: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageCode == "zh" ? "zh_Hans_CN" : "en_US_POSIX")
        formatter.dateFormat = languageCode == "zh" ? "M月d日" : "MMM d"
        return formatter.string(from: date)
    }

    static func moodLabel(_ mood: String, languageCode: String) -> String {
        if languageCode == "zh" {
            if mood.contains("rain") { return "雨后的安静" }
            if mood.contains("night") || mood.contains("lit") { return "夜里的微光" }
            if mood.contains("mist") { return "雾里的停顿" }
            if mood.contains("dusk") { return "傍晚的暖色" }
            if mood.contains("morning") { return "清晨的亮色" }
            return "安静"
        }
        if mood.contains("rain") { return "rain-soft quiet" }
        if mood.contains("night") || mood.contains("lit") { return "small night light" }
        if mood.contains("mist") { return "mist-stillness" }
        if mood.contains("dusk") { return "warm dusk" }
        if mood.contains("morning") { return "clear morning" }
        return "quiet"
    }

    private static func moodFragment(for mood: String, languageCode: String) -> String {
        if languageCode == "zh" {
            if mood.contains("rain") { return "雨让路变得更安静，我也慢了一点。" }
            if mood.contains("night") || mood.contains("lit") { return "夜里有一点光，我把它留在身边。" }
            if mood.contains("mist") { return "雾把边缘变软了，我看得更慢。" }
            if mood.contains("dusk") { return "傍晚的颜色停了一会儿。" }
            return "今天的地图很轻，我也轻轻地走。"
        }
        if mood.contains("rain") { return "The rain made the path quieter, so I moved more softly." }
        if mood.contains("night") || mood.contains("lit") { return "A little night light stayed close to me." }
        if mood.contains("mist") { return "The mist softened the edges, and I looked slowly." }
        if mood.contains("dusk") { return "The dusk color stayed for a while." }
        return "The map felt light today, so I walked lightly too."
    }

    private static func storyFragment(for beatIDs: [String], languageCode: String) -> String {
        let joined = beatIDs.joined(separator: "|")
        if joined.contains(NarrativeCharacterKind.umbrellaWoman.rawValue) {
            return languageCode == "zh"
                ? "雨边有一小块影子，我没有追过去。"
                : "At the rain's edge, a small shape waited. I did not chase it."
        }
        if joined.contains(NarrativeCharacterKind.nightLamplighter.rawValue) {
            return languageCode == "zh"
                ? "有盏灯比别的灯晚一点亮。"
                : "One lamp lit a little later than the others."
        }
        if joined.contains(NarrativeCharacterKind.mirrorMiko.rawValue) {
            return languageCode == "zh"
                ? "水里有个倒影，比我多停了一会儿。"
                : "A reflection in the water stayed a little longer than I did."
        }
        return languageCode == "zh"
            ? "今天有一条很小的痕迹。"
            : "A very small trace crossed today."
    }

    private static func traceName(_ traceID: String, languageCode: String) -> String {
        if traceID.contains(NarrativeCharacterKind.umbrellaWoman.rawValue) {
            return languageCode == "zh" ? "伞边的雨痕" : "umbrella-edge rain mark"
        }
        if traceID.contains(NarrativeCharacterKind.nightLamplighter.rawValue) {
            return languageCode == "zh" ? "晚亮的灯" : "late lantern light"
        }
        if traceID.contains(NarrativeCharacterKind.mirrorMiko.rawValue) {
            return languageCode == "zh" ? "停留的倒影" : "lingering reflection"
        }
        return languageCode == "zh" ? "小地图痕迹" : "small map trace"
    }
}

enum PicodTodayTraceText {
    static func lines(
        seedMatch: PhotoSeedMatch,
        evolution: PicoEvolutionDecision,
        mapMood: String,
        storyBundle: PicodStoryEventBundle,
        palette: [PhotoPaletteColor],
        languageCode: String
    ) -> [String] {
        var output: [String] = []

        if seedMatch.confidence < 0.42 || seedMatch.debugInfo.normalizedLabels.isEmpty {
            output.append(languageCode == "zh"
                ? "Pico 留下了今天的感觉，而不是明确的形状。"
                : "Pico kept the feeling of the photo more than a clear shape.")
        } else if let color = palette.first {
            output.append(colorLine(color, languageCode: languageCode))
        }

        if let changed = evolution.changedMajorTrait {
            output.append(changeLine(changed, languageCode: languageCode))
        }

        if let storyLine = storyLine(storyBundle, languageCode: languageCode) {
            output.append(storyLine)
        } else {
            output.append(mapLine(mapMood, languageCode: languageCode))
        }

        return Array(output.prefix(3))
    }

    static func duplicateLines(languageCode: String) -> [String] {
        [
            languageCode == "zh"
                ? "今天的照片已经被保存了。"
                : "Today's photo is already saved.",
            languageCode == "zh"
                ? "Pico 会守着这个形态到明天。"
                : "Pico will keep this shape until tomorrow."
        ]
    }

    static func photoImportFailed(languageCode: String) -> [String] {
        [
            languageCode == "zh"
                ? "这张照片没有读出来。"
                : "That photo could not be read.",
            languageCode == "zh"
                ? "今天还可以再选一张。"
                : "You can choose another one for today."
        ]
    }

    private static func colorLine(_ color: PhotoPaletteColor, languageCode: String) -> String {
        let brightness = max(color.red, color.green, color.blue)
        let warmth = color.red + color.green * 0.6 - color.blue
        if languageCode == "zh" {
            if brightness < 0.32 { return "Pico 收下了今天偏暗的颜色。" }
            if brightness > 0.76 { return "Pico 带走了今天明亮的光。" }
            if warmth > 0.65 { return "Pico 留住了今天温暖的颜色。" }
            return "Pico 记住了今天柔和的颜色。"
        }
        if brightness < 0.32 { return "Pico kept the darker color from today." }
        if brightness > 0.76 { return "Pico carried today's bright light." }
        if warmth > 0.65 { return "Pico kept the warm color from today." }
        return "Pico remembered today's softer color."
    }

    private static func changeLine(_ changed: String, languageCode: String) -> String {
        switch changed {
        case "hatch":
            return languageCode == "zh" ? "第一张照片让 Pico 孵出来了。" : "The first photo helped Pico hatch."
        case "textureTrait":
            return languageCode == "zh" ? "Pico 的表面变得更像今天。" : "Pico's surface shifted toward today."
        case "appendageTrait":
            return languageCode == "zh" ? "Pico 学会了一点新的移动方式。" : "Pico learned a small new way to move."
        case "anomalyMark":
            return languageCode == "zh" ? "有一条很轻的痕迹落在 Pico 身上。" : "A light trace settled onto Pico."
        case "memoryScar":
            return languageCode == "zh" ? "Pico 记住了前几天的一点东西。" : "Pico remembered something from earlier days."
        case "eyeTrait":
            return languageCode == "zh" ? "Pico 看世界的方式成熟了一点。" : "Pico's way of looking grew a little steadier."
        default:
            return languageCode == "zh" ? "Pico 有了一点小变化。" : "Pico changed in a small way."
        }
    }

    private static func mapLine(_ mood: String, languageCode: String) -> String {
        if languageCode == "zh" {
            if mood.contains("rain") { return "雨让地图安静了一些。" }
            if mood.contains("night") || mood.contains("lit") { return "地图在夜里留下一点光。" }
            if mood.contains("mist") { return "雾让地图边缘变软。" }
            return "地图也收下了今天的心情。"
        }
        if mood.contains("rain") { return "The rain made the map quieter." }
        if mood.contains("night") || mood.contains("lit") { return "The map kept a little night light." }
        if mood.contains("mist") { return "Mist softened the edge of the map." }
        return "The map kept today's mood too."
    }

    private static func storyLine(_ bundle: PicodStoryEventBundle, languageCode: String) -> String? {
        let ids = bundle.beats.map(\.storylineID).joined(separator: "|")
        if ids.contains(NarrativeCharacterKind.umbrellaWoman.rawValue) {
            return languageCode == "zh"
                ? "雨边出现了一小块伞形的痕迹。"
                : "A small umbrella-shaped trace appeared at the rain's edge."
        }
        if ids.contains(NarrativeCharacterKind.nightLamplighter.rawValue) {
            return languageCode == "zh"
                ? "有盏灯像是记得 Pico 路过。"
                : "A small lamp seemed to remember Pico passing."
        }
        if ids.contains(NarrativeCharacterKind.mirrorMiko.rawValue) {
            return languageCode == "zh"
                ? "有个倒影停得比平时久一点。"
                : "A reflection stayed a little longer than usual."
        }
        return nil
    }
}

enum PicodWorldTraceText {
    static func worldTraceLine(for anchor: WorldEvidenceAnchor, languageCode: String) -> String {
        if languageCode == "zh" {
            if anchor.storylineID == NarrativeCharacterKind.nightLamplighter.rawValue {
                return "那盏灯记住了这个夜晚。"
            }
            if anchor.storylineID == NarrativeCharacterKind.umbrellaWoman.rawValue {
                return "雨停在石路边。"
            }
            if anchor.storylineID == NarrativeCharacterKind.mirrorMiko.rawValue {
                return "神社旁边有一点东西看了回来。"
            }
            switch anchor.anchorKind {
            case .cycleMarker:
                return "周期结束后，一个标记留了下来。"
            case .eraEcho:
                return "很久以后，有一点回声还在。"
            case .waterEdge:
                return "水边留下了一条安静的痕迹。"
            case .light:
                return "小光在路边多停了一会儿。"
            case .shrine:
                return "神社附近留下了一点没说出口的东西。"
            case .path:
                return "一条小痕迹落在路边。"
            case .atmosphere:
                return "今天的空气留在了地图里。"
            case .object, .visitor, .animal, .unknown:
                return "地图上留下了一点小东西。"
            }
        }

        if anchor.storylineID == NarrativeCharacterKind.nightLamplighter.rawValue {
            return "The lamp remembered this night."
        }
        if anchor.storylineID == NarrativeCharacterKind.umbrellaWoman.rawValue {
            return "The rain stayed on the stones."
        }
        if anchor.storylineID == NarrativeCharacterKind.mirrorMiko.rawValue {
            return "Something by the shrine looked back."
        }
        switch anchor.anchorKind {
        case .cycleMarker:
            return "One marker stayed after the cycle ended."
        case .eraEcho:
            return "A rare echo stayed after the long turn."
        case .waterEdge:
            return "A quiet trace stayed near the water."
        case .light:
            return "A small light paused by the path."
        case .shrine:
            return "Something unsaid stayed near the shrine."
        case .path:
            return "A trace was left near the path."
        case .atmosphere:
            return "The day's air settled into the map."
        case .object, .visitor, .animal, .unknown:
            return "A small thing stayed in the world."
        }
    }

    static func dailyTraceLine(
        for link: WorldEvidenceLink?,
        anchors: [WorldEvidenceAnchor],
        didCapturePhoto: Bool,
        mapMood: String?,
        languageCode: String
    ) -> String {
        let fallback: String
        if didCapturePhoto {
            fallback = dailyFallback(mapMood: mapMood, languageCode: languageCode)
        } else {
            fallback = languageCode == "zh"
                ? "这一天很安静，地图也把空白留住了。"
                : "This day stayed quiet, and the map kept the empty space."
        }
        return traceLines(
            for: link,
            anchors: anchors,
            fallback: fallback,
            languageCode: languageCode,
            limit: 2,
            includePlaceLine: link?.canHighlightOnMap == true
        ).joined(separator: "\n")
    }

    static func storyEvidenceLine(
        for link: WorldEvidenceLink,
        languageCode: String
    ) -> String {
        if link.canOpenDetail {
            return languageCode == "zh"
                ? "有一条痕迹已经能被看见。"
                : "One trace has become visible."
        }
        return languageCode == "zh"
            ? "这条痕迹还只露出一点边。"
            : "This trace is still only showing its edge."
    }

    static func storyEvidenceLine(
        for link: WorldEvidenceLink,
        anchors: [WorldEvidenceAnchor],
        displayState: StoryCardDisplayState,
        recurrenceCount: Int,
        languageCode: String
    ) -> String {
        if displayState == .locked {
            return languageCode == "zh"
                ? "这条痕迹还没有走进世界。"
                : "This trace has not stepped into the world yet."
        }

        var lines = traceLines(
            for: link,
            anchors: anchors,
            fallback: languageCode == "zh"
                ? "世界只留下了一点很轻的线索。"
                : "The world only left a faint clue.",
            languageCode: languageCode,
            limit: 2,
            includePlaceLine: false
        )
        if recurrenceCount > 1 && lines.count < 3 {
            lines.append(languageCode == "zh"
                ? "它已经不止一次靠近。"
                : "It has returned more than once.")
        }
        return Array(lines.prefix(3)).joined(separator: "\n")
    }

    static func lifeAlbumTraceLine(
        for link: WorldEvidenceLink,
        anchors: [WorldEvidenceAnchor],
        capturedDays: Int,
        languageCode: String
    ) -> String {
        var lines = traceLines(
            for: link,
            anchors: anchors,
            fallback: languageCode == "zh"
                ? "七天的痕迹安静地放在世界里。"
                : "A seven-day trace rests quietly in the world.",
            languageCode: languageCode,
            limit: 2,
            includePlaceLine: false
        )
        if lines.count < 2 {
            lines.append(languageCode == "zh"
                ? "\(capturedDays) 天照片留下了这次生命的节奏。"
                : "\(capturedDays) captured day(s) left this Life's rhythm.")
        }
        return Array(lines.prefix(2)).joined(separator: "\n")
    }

    static func cycleTraceLine(
        for link: WorldEvidenceLink,
        anchors: [WorldEvidenceAnchor],
        toriiCount: Int,
        languageCode: String
    ) -> String {
        let fallback = toriiCount > 0
            ? (languageCode == "zh"
                ? "周期结束后，一个标记留了下来。"
                : "One marker stayed after the cycle ended.")
            : (languageCode == "zh"
                ? "这个周期留下了很轻的节奏。"
                : "This cycle left a quiet rhythm.")
        return traceLines(
            for: link,
            anchors: anchors,
            fallback: fallback,
            languageCode: languageCode,
            limit: 2,
            includePlaceLine: toriiCount > 0 && link.canHighlightOnMap
        ).joined(separator: "\n")
    }

    static func eraTraceLine(
        for link: WorldEvidenceLink?,
        anchors: [WorldEvidenceAnchor],
        isUnlocked: Bool,
        languageCode: String
    ) -> String {
        guard isUnlocked else {
            return languageCode == "zh" ? "还没有显现。" : "Not visible yet."
        }
        return traceLines(
            for: link,
            anchors: anchors,
            fallback: languageCode == "zh"
                ? "很久以后，有一点回声还在。"
                : "A rare echo stayed after the long turn.",
            languageCode: languageCode,
            limit: 1,
            includePlaceLine: false
        ).joined(separator: "\n")
    }

    static func containsForbiddenNormalUITerm(_ text: String) -> Bool {
        forbiddenNormalUITerms.contains { text.localizedCaseInsensitiveContains($0) }
    }

    static let forbiddenNormalUITerms = [
        "evidenceID",
        "projectedElementID",
        "catalogElementID",
        "WorldStateProjection",
        "resolver",
        "validator",
        "audit",
        "debug",
        "json",
        "store"
    ]

    private static func traceLines(
        for link: WorldEvidenceLink?,
        anchors: [WorldEvidenceAnchor],
        fallback: String,
        languageCode: String,
        limit: Int,
        includePlaceLine: Bool
    ) -> [String] {
        guard let link else {
            return [fallback]
        }
        let anchorByID = Dictionary(anchors.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let matched = link.anchorIDs.compactMap { anchorByID[$0] }
            .filter { $0.displayState != .hidden && $0.validationState != .locked }

        var seen = Set<String>()
        var lines = matched
            .map { worldTraceLine(for: $0, languageCode: languageCode) }
            .filter { seen.insert($0).inserted }

        if lines.isEmpty {
            lines = [localizedFallback(link.fallbackLabel, defaultFallback: fallback, languageCode: languageCode)]
        }
        if includePlaceLine && lines.count < limit {
            lines.append(languageCode == "zh"
                ? "它在世界里有一个很轻的位置。"
                : "It has a quiet place in the world.")
        }
        return Array(lines.prefix(limit))
    }

    private static func localizedFallback(
        _ fallback: String,
        defaultFallback: String,
        languageCode: String
    ) -> String {
        guard languageCode == "zh" else { return fallback.isEmpty ? defaultFallback : fallback }
        if fallback.contains("world marker") || fallback.contains("cycle") {
            return "这个周期留下了很轻的节奏。"
        }
        if fallback.contains("seven-day") || fallback.contains("Life") {
            return "七天的痕迹安静地放在世界里。"
        }
        if fallback.contains("rare") || fallback.contains("long turn") {
            return "很久以后，有一点回声还在。"
        }
        if fallback.contains("not stepped") || fallback.contains("faint clue") {
            return "世界只留下了一点很轻的线索。"
        }
        if fallback.contains("quiet") || fallback.contains("trace") {
            return "地图只留下了一点很轻的痕迹。"
        }
        return defaultFallback
    }

    private static func dailyFallback(mapMood: String?, languageCode: String) -> String {
        let mood = mapMood ?? "quiet"
        if languageCode == "zh" {
            if mood.contains("rain") { return "雨把今天的痕迹留在路边。" }
            if mood.contains("night") || mood.contains("lit") { return "夜里有一点光被留下来。" }
            if mood.contains("mist") { return "雾把今天的边缘留得很软。" }
            return "今天的照片在地图里留下了一点心情。"
        }
        if mood.contains("rain") { return "The rain left today's trace near the path." }
        if mood.contains("night") || mood.contains("lit") { return "A little night light was left behind." }
        if mood.contains("mist") { return "The mist left today's edges soft." }
        return "Today's photo left a small mood in the map."
    }
}

struct PicodEvidenceCopyDebugCheck: Codable, Hashable, Identifiable {
    let id: String
    let passed: Bool
    let summary: String
}

struct PicodEvidenceCopyDebugSummary: Codable, Hashable {
    let checks: [PicodEvidenceCopyDebugCheck]

    var passedCount: Int { checks.filter(\.passed).count }
    var failedCount: Int { checks.filter { !$0.passed }.count }
    var summaryLine: String {
        "evidence copy checked \(checks.count) / failed \(failedCount)"
    }
}

enum PicodEvidenceCopyDebugValidator {
    static func runAll(languageCode: String = "en") -> PicodEvidenceCopyDebugSummary {
        let umbrella = anchor(id: "copy-umbrella", kind: .waterEdge, storylineID: NarrativeCharacterKind.umbrellaWoman.rawValue)
        let lamp = anchor(id: "copy-lamp", kind: .light, storylineID: NarrativeCharacterKind.nightLamplighter.rawValue)
        let mirror = anchor(id: "copy-mirror", kind: .shrine, storylineID: NarrativeCharacterKind.mirrorMiko.rawValue)
        let cycle = anchor(id: "copy-cycle", kind: .cycleMarker, sourceType: .cycleRecord)
        let eraHidden = anchor(id: "copy-era-hidden", kind: .eraEcho, sourceType: .eraMemory, displayState: .hidden, validationState: .locked)
        let eraVisible = anchor(id: "copy-era-visible", kind: .eraEcho, sourceType: .eraMemory, displayState: .remembered)
        let anchors = [umbrella, lamp, mirror, cycle, eraHidden, eraVisible]

        let umbrellaStory = PicodWorldTraceText.storyEvidenceLine(
            for: link(id: "copy-story-umbrella", type: .storyCard, anchors: [umbrella]),
            anchors: anchors,
            displayState: .traceSeen,
            recurrenceCount: 1,
            languageCode: languageCode
        )
        let lampStory = PicodWorldTraceText.storyEvidenceLine(
            for: link(id: "copy-story-lamp", type: .storyCard, anchors: [lamp]),
            anchors: anchors,
            displayState: .recurring,
            recurrenceCount: 2,
            languageCode: languageCode
        )
        let mirrorStory = PicodWorldTraceText.storyEvidenceLine(
            for: link(id: "copy-story-mirror", type: .storyCard, anchors: [mirror]),
            anchors: anchors,
            displayState: .encountered,
            recurrenceCount: 1,
            languageCode: languageCode
        )
        let dailyFallback = PicodWorldTraceText.dailyTraceLine(
            for: nil,
            anchors: [],
            didCapturePhoto: true,
            mapMood: "rain-soft",
            languageCode: languageCode
        )
        let album = PicodWorldTraceText.lifeAlbumTraceLine(
            for: link(id: "copy-album", type: .lifeAlbum, anchors: []),
            anchors: anchors,
            capturedDays: 5,
            languageCode: languageCode
        )
        let cycleLine = PicodWorldTraceText.cycleTraceLine(
            for: link(id: "copy-cycle-link", type: .cycleRecord, anchors: [cycle]),
            anchors: anchors,
            toriiCount: 1,
            languageCode: languageCode
        )
        let lockedEra = PicodWorldTraceText.eraTraceLine(
            for: link(id: "copy-era-hidden-link", type: .eraMemory, anchors: [eraHidden]),
            anchors: anchors,
            isUnlocked: false,
            languageCode: languageCode
        )
        let unlockedEra = PicodWorldTraceText.eraTraceLine(
            for: link(id: "copy-era-visible-link", type: .eraMemory, anchors: [eraVisible]),
            anchors: anchors,
            isUnlocked: true,
            languageCode: languageCode
        )
        let missingProjection = PicodWorldTraceText.storyEvidenceLine(
            for: WorldEvidenceLink.fallback(
                sourceMemoryType: .storyCard,
                sourceMemoryID: "copy-missing",
                label: "The world only left a faint clue.",
                debugSummary: "copy missing projection"
            ),
            anchors: [],
            displayState: .traceSeen,
            recurrenceCount: 1,
            languageCode: languageCode
        )
        let aggregate = [
            umbrellaStory,
            lampStory,
            mirrorStory,
            dailyFallback,
            album,
            cycleLine,
            lockedEra,
            unlockedEra,
            missingProjection
        ].joined(separator: "\n")

        let checks = [
            check("umbrella-copy", umbrellaStory.contains(languageCode == "zh" ? "雨" : "rain"), umbrellaStory),
            check("lamplighter-copy", lampStory.contains(languageCode == "zh" ? "灯" : "lamp"), lampStory),
            check("mirror-copy", mirrorStory.contains(languageCode == "zh" ? "神社" : "shrine"), mirrorStory),
            check("daily-fallback-copy", !dailyFallback.isEmpty, dailyFallback),
            check("life-album-copy", album.contains(languageCode == "zh" ? "七天" : "seven-day") || album.contains("Life"), album),
            check("cycle-copy", cycleLine.contains(languageCode == "zh" ? "周期" : "cycle") || cycleLine.contains("marker"), cycleLine),
            check("locked-era-quiet", lockedEra == (languageCode == "zh" ? "还没有显现。" : "Not visible yet."), lockedEra),
            check("unlocked-era-copy", unlockedEra.contains(languageCode == "zh" ? "回声" : "echo"), unlockedEra),
            check("missing-projection-copy", !missingProjection.isEmpty, missingProjection),
            check("no-forbidden-normal-terms", !PicodWorldTraceText.containsForbiddenNormalUITerm(aggregate), aggregate)
        ]

        return PicodEvidenceCopyDebugSummary(checks: checks)
    }

    private static func check(_ id: String, _ passed: Bool, _ summary: String) -> PicodEvidenceCopyDebugCheck {
        PicodEvidenceCopyDebugCheck(id: id, passed: passed, summary: summary)
    }

    private static func link(
        id: String,
        type: WorldEvidenceMemoryType,
        anchors: [WorldEvidenceAnchor]
    ) -> WorldEvidenceLink {
        WorldEvidenceLink(
            sourceMemoryType: type,
            sourceMemoryID: id,
            anchorIDs: anchors.map(\.id),
            primaryAnchorID: anchors.first?.id,
            fallbackLabel: "The world only left a faint clue.",
            canHighlightOnMap: anchors.first?.anchorPoint != nil,
            canOpenDetail: !anchors.isEmpty,
            debugSummary: "copy validation"
        )
    }

    private static func anchor(
        id: String,
        kind: WorldEvidenceAnchorKind,
        sourceType: WorldEvidenceSourceType = .mapTrace,
        storylineID: String? = nil,
        displayState: WorldEvidenceAnchorDisplayState = .visible,
        validationState: WorldEvidenceAnchorValidationState = .valid
    ) -> WorldEvidenceAnchor {
        WorldEvidenceAnchor(
            id: id,
            evidenceID: "copy-evidence-\(id)",
            evidenceSourceType: sourceType,
            sourceRecordID: "copy-record-\(id)",
            localDayKey: nil,
            lifeID: nil,
            cycleID: nil,
            eraID: nil,
            storylineID: storylineID,
            projectedElementID: "copy-element-\(id)",
            catalogElementID: "copy-catalog-\(id)",
            mapVariantID: "copy-map",
            anchorKind: kind,
            anchorPoint: MapCoord(x: 1, y: 1),
            displayState: displayState,
            persistenceScope: .daily,
            userFacingLabel: "",
            debugReason: "copy validation fixture",
            validationState: validationState
        )
    }
}
