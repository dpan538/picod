import Foundation

struct PhotoSeedSignature: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: String
    let renderedFormID: Int
    let semanticTags: [String]
    let colorTags: [String]
    let timeWeatherTags: [String]
    let dayFitTags: [String]
    let personality: PicoPersonality
}

struct PhotoSeedAlternative: Codable, Hashable, Identifiable {
    var id: String { seedID }
    let seedID: String
    let renderedFormID: Int
    let confidence: Double
    let reasonTags: [String]
}

struct PhotoSeedDecisionDebugInfo: Codable, Hashable {
    var schemaVersion: Int? = 1
    let componentWeights: [String: Double]
    let candidateScores: [String: Double]
    let normalizedLabels: [String]
    let dominantColorDescription: String?
}

struct PhotoSeedMatch: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    var id: String { selectedSeedID }
    let selectedSeedID: String
    let renderedFormID: Int
    let confidence: Double
    let topAlternativeSeeds: [PhotoSeedAlternative]
    let semanticReasonTags: [String]
    let colorReasonTags: [String]
    let timeWeatherReasonTags: [String]
    let storyGateReasonTags: [String]
    let debugInfo: PhotoSeedDecisionDebugInfo
}

struct PhotoSeedMatcherInput: Hashable {
    let visionLabels: [VisionLabel]
    let dominantColor: HSBColor?
    let colorPalette: [PhotoPaletteColor]
    let timePhase: PicodTimePhase
    let weather: PicodWeatherCondition
    let coarseLocationTag: String?
    let dayIndexInLife: DayIndexInLife
    let previousGenome: PicoGenome?
    let participationRhythm: ParticipationLevel
    let activeStoryFlags: Set<String>
}

struct PhotoSeedMatcher {
    private let weights: [String: Double] = [
        "semantic": 0.35,
        "color": 0.15,
        "timeWeather": 0.15,
        "dayIndex": 0.15,
        "inheritance": 0.10,
        "participation": 0.05,
        "storyGate": 0.05
    ]

    func match(input: PhotoSeedMatcherInput) -> PhotoSeedMatch {
        let normalizedLabels = input.visionLabels
            .map { VisionLabel(identifier: MappingDatabase.normalize($0.identifier), confidence: $0.confidence) }
            .sorted { lhs, rhs in
                if lhs.confidence != rhs.confidence { return lhs.confidence > rhs.confidence }
                return lhs.identifier < rhs.identifier
            }

        let labelText = normalizedLabels.map(\.identifier)
        let signatures = Self.seedSignatures()
        let candidateDetails = signatures.map { signature in
            score(signature: signature, labels: normalizedLabels, labelText: labelText, input: input)
        }
        let sorted = candidateDetails.sorted { lhs, rhs in
            if lhs.total != rhs.total { return lhs.total > rhs.total }
            return lhs.signature.renderedFormID < rhs.signature.renderedFormID
        }

        let winner = sorted.first ?? score(
            signature: Self.fallbackSignature(),
            labels: normalizedLabels,
            labelText: labelText,
            input: input
        )
        let confidence = max(0, min(1, winner.total))
        let alternatives = sorted
            .dropFirst()
            .prefix(4)
            .map {
                PhotoSeedAlternative(
                    seedID: $0.signature.id,
                    renderedFormID: $0.signature.renderedFormID,
                    confidence: max(0, min(1, $0.total)),
                    reasonTags: Array(($0.semanticTags + $0.colorTags + $0.timeWeatherTags).prefix(5))
                )
            }

        let debug = PhotoSeedDecisionDebugInfo(
            componentWeights: weights,
            candidateScores: Dictionary(uniqueKeysWithValues: sorted.prefix(12).map { ($0.signature.id, $0.total) }),
            normalizedLabels: labelText,
            dominantColorDescription: input.dominantColor.map {
                "h:\(Int($0.hue.rounded())) s:\(String(format: "%.2f", $0.saturation)) b:\(String(format: "%.2f", $0.brightness))"
            }
        )

        return PhotoSeedMatch(
            selectedSeedID: winner.signature.id,
            renderedFormID: winner.signature.renderedFormID,
            confidence: confidence,
            topAlternativeSeeds: alternatives,
            semanticReasonTags: winner.semanticTags,
            colorReasonTags: winner.colorTags,
            timeWeatherReasonTags: winner.timeWeatherTags,
            storyGateReasonTags: winner.storyTags,
            debugInfo: debug
        )
    }

    private func score(
        signature: PhotoSeedSignature,
        labels: [VisionLabel],
        labelText: [String],
        input: PhotoSeedMatcherInput
    ) -> CandidateScore {
        let semantic = semanticScore(signature: signature, labels: labels)
        let color = colorScore(signature: signature, dominantColor: input.dominantColor)
        let timeWeather = timeWeatherScore(signature: signature, input: input)
        let day = dayScore(signature: signature, dayIndex: input.dayIndexInLife.rawValue)
        let inheritance = inheritanceScore(signature: signature, previousGenome: input.previousGenome)
        let participation = participationScore(signature: signature, rhythm: input.participationRhythm)
        let story = storyGateScore(signature: signature, storyFlags: input.activeStoryFlags)

        let total =
            semantic.value * (weights["semantic"] ?? 0) +
            color.value * (weights["color"] ?? 0) +
            timeWeather.value * (weights["timeWeather"] ?? 0) +
            day.value * (weights["dayIndex"] ?? 0) +
            inheritance.value * (weights["inheritance"] ?? 0) +
            participation.value * (weights["participation"] ?? 0) +
            story.value * (weights["storyGate"] ?? 0)

        return CandidateScore(
            signature: signature,
            total: total,
            semanticTags: semantic.tags,
            colorTags: color.tags,
            timeWeatherTags: timeWeather.tags,
            storyTags: story.tags
        )
    }

    private func semanticScore(signature: PhotoSeedSignature, labels: [VisionLabel]) -> (value: Double, tags: [String]) {
        var score = 0.0
        var tags: [String] = []
        let semanticSet = Set(signature.semanticTags)
        for label in labels {
            guard semanticSet.contains(where: { label.identifier.contains($0) || $0.contains(label.identifier) }) else {
                continue
            }
            score += Double(label.confidence)
            tags.append("label:\(label.identifier)")
        }
        if tags.isEmpty {
            score = Double(signature.personality == .natural ? 0.16 : 0.10)
        }
        return (min(1, score), Array(Set(tags)).sorted())
    }

    private func colorScore(signature: PhotoSeedSignature, dominantColor: HSBColor?) -> (value: Double, tags: [String]) {
        guard let dominantColor else { return (0.28, ["color:missing"]) }
        let colorTag = Self.colorTag(for: dominantColor)
        let brightnessTag = dominantColor.brightness < 0.28 ? "dark" : dominantColor.brightness > 0.74 ? "bright" : "muted"
        let tags = [colorTag, brightnessTag]
        let overlap = tags.filter { signature.colorTags.contains($0) }.count
        let value = overlap == 0 ? 0.24 : min(1, 0.34 + Double(overlap) * 0.33)
        return (value, tags.map { "color:\($0)" })
    }

    private func timeWeatherScore(signature: PhotoSeedSignature, input: PhotoSeedMatcherInput) -> (value: Double, tags: [String]) {
        var tags = ["time:\(input.timePhase.rawValue)", "weather:\(input.weather.rawValue)"]
        if let coarse = input.coarseLocationTag, !coarse.isEmpty {
            tags.append("place:\(coarse)")
        }
        let needles = [
            input.timePhase.rawValue,
            input.weather.rawValue,
            input.coarseLocationTag ?? ""
        ].filter { !$0.isEmpty }
        let hits = needles.filter { signature.timeWeatherTags.contains($0) }.count
        return (hits == 0 ? 0.25 : min(1, 0.36 + Double(hits) * 0.28), tags)
    }

    private func dayScore(signature: PhotoSeedSignature, dayIndex: Int) -> (value: Double, tags: [String]) {
        let dayTag = "day\(dayIndex)"
        if signature.dayFitTags.contains(dayTag) {
            return (1.0, ["fit:\(dayTag)"])
        }
        if dayIndex == 1 && signature.personality != .yokai {
            return (0.74, ["fit:hatch-safe"])
        }
        if dayIndex >= 4 && signature.personality == .yokai {
            return (0.78, ["fit:late-life-anomaly"])
        }
        return (0.46, ["fit:neutral"])
    }

    private func inheritanceScore(signature: PhotoSeedSignature, previousGenome: PicoGenome?) -> (value: Double, tags: [String]) {
        guard let previousGenome else { return (0.52, ["inheritance:none"]) }
        if previousGenome.seedLineageIDs.contains(signature.id) {
            return (0.96, ["inheritance:lineage"])
        }
        if previousGenome.renderedFormID == signature.renderedFormID {
            return (0.90, ["inheritance:form"])
        }
        if MappingDatabase.personality(for: previousGenome.renderedFormID) == signature.personality {
            return (0.72, ["inheritance:temperament"])
        }
        return (0.36, ["inheritance:mutation"])
    }

    private func participationScore(signature: PhotoSeedSignature, rhythm: ParticipationLevel) -> (value: Double, tags: [String]) {
        switch rhythm {
        case .full:
            return (signature.personality == .natural ? 0.84 : 0.64, ["rhythm:full"])
        case .partial:
            return (0.68, ["rhythm:partial"])
        case .minimal:
            return (signature.personality == .artifact ? 0.76 : 0.58, ["rhythm:minimal"])
        case .absent:
            return (signature.personality == .ethereal ? 0.70 : 0.42, ["rhythm:quiet"])
        }
    }

    private func storyGateScore(signature: PhotoSeedSignature, storyFlags: Set<String>) -> (value: Double, tags: [String]) {
        guard !storyFlags.isEmpty else { return (0.50, ["story:none"]) }
        let hits = storyFlags.filter { flag in
            signature.semanticTags.contains(flag) || signature.timeWeatherTags.contains(flag)
        }
        if hits.isEmpty {
            return (0.50, storyFlags.sorted().map { "story:\($0)" })
        }
        return (0.92, hits.sorted().map { "story:\($0)" })
    }

    private struct CandidateScore {
        let signature: PhotoSeedSignature
        let total: Double
        let semanticTags: [String]
        let colorTags: [String]
        let timeWeatherTags: [String]
        let storyTags: [String]
    }

    static func seedSignatures() -> [PhotoSeedSignature] {
        MappingDatabase.clusters.map { cluster in
            PhotoSeedSignature(
                id: "form_\(cluster.formId)",
                renderedFormID: cluster.formId,
                semanticTags: Array(cluster.keywords).sorted(),
                colorTags: colorTags(for: cluster),
                timeWeatherTags: timeWeatherTags(for: cluster),
                dayFitTags: dayFitTags(for: cluster),
                personality: cluster.personality
            )
        }
    }

    static func fallbackSignature() -> PhotoSeedSignature {
        PhotoSeedSignature(
            id: "form_1",
            renderedFormID: 1,
            semanticTags: ["animal", "small", "quiet"],
            colorTags: ["warm", "muted"],
            timeWeatherTags: ["morning", "clear"],
            dayFitTags: ["day1", "day2"],
            personality: .natural
        )
    }

    static func hsb(from color: PhotoPaletteColor?) -> HSBColor? {
        guard let color else { return nil }
        let red = Float(color.red)
        let green = Float(color.green)
        let blue = Float(color.blue)
        let maxValue = max(red, green, blue)
        let minValue = min(red, green, blue)
        let delta = maxValue - minValue
        var hue: Float = 0
        if delta != 0 {
            if maxValue == red {
                hue = 60 * (((green - blue) / delta).truncatingRemainder(dividingBy: 6))
            } else if maxValue == green {
                hue = 60 * (((blue - red) / delta) + 2)
            } else {
                hue = 60 * (((red - green) / delta) + 4)
            }
        }
        if hue < 0 { hue += 360 }
        let saturation = maxValue == 0 ? 0 : delta / maxValue
        return HSBColor(hue: hue, saturation: saturation, brightness: maxValue)
    }

    private static func colorTag(for hsb: HSBColor) -> String {
        if hsb.saturation < 0.16 {
            return hsb.brightness > 0.72 ? "white" : hsb.brightness < 0.28 ? "black" : "gray"
        }
        switch hsb.hue {
        case 0..<35, 335...360: return "red"
        case 35..<70: return "gold"
        case 70..<165: return "green"
        case 165..<250: return "blue"
        case 250..<335: return "violet"
        default: return "muted"
        }
    }

    private static func colorTags(for cluster: FormCluster) -> [String] {
        var tags: Set<String> = ["muted"]
        for (tag, values) in MappingDatabase.attributeWeightTable where values[cluster.formId] != nil {
            tags.insert(tag == "grey" ? "gray" : tag)
        }
        for rule in MappingDatabase.colorBiasTable where rule.bias[cluster.formId] != nil {
            let mid = midpointHue(low: rule.range.hueLow, high: rule.range.hueHigh)
            tags.insert(colorTag(for: HSBColor(hue: mid, saturation: rule.range.satMin, brightness: rule.range.briMin)))
        }
        return Array(tags).sorted()
    }

    private static func timeWeatherTags(for cluster: FormCluster) -> [String] {
        var tags: Set<String> = []
        for (tag, values) in MappingDatabase.sceneFilterTable where values[cluster.formId] != nil {
            switch tag {
            case "night":
                tags.insert("night")
            case "rainy":
                tags.insert("rain")
            case "foggy":
                tags.insert("fog")
            case "snowy":
                tags.insert("snow")
            default:
                tags.insert(tag)
            }
        }
        if cluster.keywords.contains(where: { $0.contains("lantern") || $0.contains("moon") }) {
            tags.insert("night")
        }
        if cluster.personality == .natural {
            tags.insert("morning")
            tags.insert("afternoon")
            tags.insert("clear")
        }
        return Array(tags).sorted()
    }

    private static func dayFitTags(for cluster: FormCluster) -> [String] {
        switch cluster.personality {
        case .natural:
            return ["day1", "day2", "day3"]
        case .artifact:
            return ["day2", "day5", "day6"]
        case .ethereal:
            return ["day4", "day6", "day7"]
        case .yokai:
            return ["day4", "day5", "day6", "day7"]
        }
    }

    private static func midpointHue(low: Float, high: Float) -> Float {
        if low <= high {
            return (low + high) / 2
        }
        let wrapped = ((low + high + 360) / 2).truncatingRemainder(dividingBy: 360)
        return wrapped
    }
}
