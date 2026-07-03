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
