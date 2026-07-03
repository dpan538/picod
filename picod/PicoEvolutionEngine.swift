import Foundation

struct PicoGenome: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: UUID
    var baseBody: String
    var coreColor: String
    var accentColor: String
    var headTrait: String
    var appendageTrait: String
    var eyeTrait: String
    var textureTrait: String
    var anomalyMark: String?
    var memoryScar: String?
    var ageLayer: Int
    var seedLineageIDs: [String]
    var renderedFormID: Int

    init(
        id: UUID = UUID(),
        baseBody: String,
        coreColor: String,
        accentColor: String,
        headTrait: String,
        appendageTrait: String,
        eyeTrait: String,
        textureTrait: String,
        anomalyMark: String? = nil,
        memoryScar: String? = nil,
        ageLayer: Int,
        seedLineageIDs: [String],
        renderedFormID: Int
    ) {
        self.id = id
        self.baseBody = baseBody
        self.coreColor = coreColor
        self.accentColor = accentColor
        self.headTrait = headTrait
        self.appendageTrait = appendageTrait
        self.eyeTrait = eyeTrait
        self.textureTrait = textureTrait
        self.anomalyMark = anomalyMark
        self.memoryScar = memoryScar
        self.ageLayer = max(0, min(7, ageLayer))
        self.seedLineageIDs = Array(seedLineageIDs.suffix(14))
        self.renderedFormID = renderedFormID
    }

    static let egg = PicoGenome(
        baseBody: "egg",
        coreColor: "F0EDE8",
        accentColor: "D8D4CE",
        headTrait: "sleeping",
        appendageTrait: "none",
        eyeTrait: "closed",
        textureTrait: "shell",
        anomalyMark: nil,
        memoryScar: nil,
        ageLayer: 0,
        seedLineageIDs: [],
        renderedFormID: 0
    )
}

struct PicoEvolutionInput: Hashable {
    let date: Date
    let dayIndexInLife: DayIndexInLife
    let seedMatch: PhotoSeedMatch
    let photoSnapshot: PhotoTraitSnapshot?
    let previousGenome: PicoGenome?
    let activeStoryFlags: Set<String>
    let isNightClosure: Bool
}

struct PicoEvolutionDebugSnapshot: Codable, Hashable {
    var schemaVersion: Int? = 1
    let dayIndexInLife: Int
    let allowedMajorChanges: Int
    let selectedMajorChange: String
    let inheritedFields: [String]
    let mutationReasonTags: [String]
    let genomeBefore: PicoGenome?
    let genomeAfter: PicoGenome?
    let changedTraits: [String]?
    let renderedFormID: Int?
    let inheritanceSource: String?
    let rendererFallbackNote: String?
}

struct PicoEvolutionDecision: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: UUID
    let genomeBefore: PicoGenome?
    let genomeAfter: PicoGenome
    let renderedFormID: Int
    let changedMajorTrait: String?
    let reasonTags: [String]
    let closesLife: Bool
    let returnsToEgg: Bool
    let debugSnapshot: PicoEvolutionDebugSnapshot

    init(
        id: UUID = UUID(),
        genomeBefore: PicoGenome?,
        genomeAfter: PicoGenome,
        renderedFormID: Int,
        changedMajorTrait: String?,
        reasonTags: [String],
        closesLife: Bool,
        returnsToEgg: Bool,
        debugSnapshot: PicoEvolutionDebugSnapshot
    ) {
        self.id = id
        self.genomeBefore = genomeBefore
        self.genomeAfter = genomeAfter
        self.renderedFormID = renderedFormID
        self.changedMajorTrait = changedMajorTrait
        self.reasonTags = reasonTags
        self.closesLife = closesLife
        self.returnsToEgg = returnsToEgg
        self.debugSnapshot = debugSnapshot
    }
}

struct PicoEvolutionEngine {
    func evolve(input: PicoEvolutionInput) -> PicoEvolutionDecision {
        let day = input.dayIndexInLife.rawValue
        let before = input.previousGenome

        if day == 7 && input.isNightClosure {
            let beforeOrFinal = before ?? hatchGenome(input: input)
            var egg = PicoGenome.egg
            egg.memoryScar = beforeOrFinal.memoryScar ?? "life-returned"
            egg.seedLineageIDs = beforeOrFinal.seedLineageIDs
            let debug = PicoEvolutionDebugSnapshot(
                dayIndexInLife: day,
                allowedMajorChanges: 2,
                selectedMajorChange: "returnToEgg",
                inheritedFields: ["seedLineageIDs", "memoryScar"],
                mutationReasonTags: ["day7:closure"],
                genomeBefore: beforeOrFinal,
                genomeAfter: egg,
                changedTraits: ["returnToEgg"],
                renderedFormID: egg.renderedFormID,
                inheritanceSource: "day7Closure",
                rendererFallbackNote: nil
            )
            return PicoEvolutionDecision(
                genomeBefore: beforeOrFinal,
                genomeAfter: egg,
                renderedFormID: egg.renderedFormID,
                changedMajorTrait: "returnToEgg",
                reasonTags: ["life:closed", "pico:egg"],
                closesLife: true,
                returnsToEgg: true,
                debugSnapshot: debug
            )
        }

        let missingPreviousGenome = day > 1 && before == nil
        var after = day == 1 || before == nil ? hatchGenome(input: input) : before!
        var inheritedFields = inheritedFieldNames()
        var changedTrait: String?
        var reasonTags: [String] = ["seed:\(input.seedMatch.selectedSeedID)", "day:\(day)"]
        if missingPreviousGenome {
            reasonTags.append("inheritance:missing-previous-fallback")
        }

        if day > 1 {
            let mutation = controlledMutation(for: day, input: input, genome: after)
            mutation.apply(&after)
            changedTrait = mutation.traitName
            reasonTags.append(contentsOf: mutation.reasonTags)
            inheritedFields.removeAll { $0 == mutation.traitName }
        } else {
            changedTrait = "hatch"
            reasonTags.append("hatch:first-photo")
        }

        after.ageLayer = day
        after.renderedFormID = input.seedMatch.renderedFormID
        after.seedLineageIDs.append(input.seedMatch.selectedSeedID)
        after.seedLineageIDs = Array(after.seedLineageIDs.suffix(14))

        let debug = PicoEvolutionDebugSnapshot(
            dayIndexInLife: day,
            allowedMajorChanges: day == 1 ? 3 : 1,
            selectedMajorChange: changedTrait ?? "none",
            inheritedFields: inheritedFields.sorted(),
            mutationReasonTags: reasonTags,
            genomeBefore: before,
            genomeAfter: after,
            changedTraits: changedTrait.map { [$0] } ?? [],
            renderedFormID: after.renderedFormID,
            inheritanceSource: day == 1 ? "hatch" : (missingPreviousGenome ? "missingPreviousFallback" : "previousGenome"),
            rendererFallbackNote: nil
        )

        return PicoEvolutionDecision(
            genomeBefore: before,
            genomeAfter: after,
            renderedFormID: after.renderedFormID,
            changedMajorTrait: changedTrait,
            reasonTags: reasonTags,
            closesLife: day == 7,
            returnsToEgg: false,
            debugSnapshot: debug
        )
    }

    private func hatchGenome(input: PicoEvolutionInput) -> PicoGenome {
        let seedID = input.seedMatch.selectedSeedID
        let renderedFormID = input.seedMatch.renderedFormID
        let dominant = input.photoSnapshot?.colorPalette.first
        let core = hexString(from: dominant) ?? "F0EDE8"
        let accent = input.photoSnapshot?.colorPalette.dropFirst().first.flatMap(hexString(from:)) ?? core
        let personality = MappingDatabase.personality(for: renderedFormID)

        return PicoGenome(
            baseBody: baseBody(for: personality, labels: input.photoSnapshot?.normalizedLabels ?? []),
            coreColor: core,
            accentColor: accent,
            headTrait: "new",
            appendageTrait: "small",
            eyeTrait: eyeTrait(for: personality),
            textureTrait: textureTrait(from: input.photoSnapshot?.normalizedLabels ?? []),
            anomalyMark: nil,
            memoryScar: nil,
            ageLayer: 1,
            seedLineageIDs: [seedID],
            renderedFormID: renderedFormID
        )
    }

    private func controlledMutation(
        for day: Int,
        input: PicoEvolutionInput,
        genome: PicoGenome
    ) -> PicoGenomeMutation {
        let labels = input.photoSnapshot?.normalizedLabels ?? []
        let highConfidenceLabels = (input.photoSnapshot?.rawVisionTopN ?? [])
            .filter { $0.confidence >= 0.55 }
            .map { MappingDatabase.normalize($0.identifier) }

        switch day {
        case 2:
            let texture = textureTrait(from: highConfidenceLabels.isEmpty ? labels : highConfidenceLabels)
            return PicoGenomeMutation(traitName: "textureTrait", reasonTags: ["day2:texture", "labels:\(texture)"]) {
                $0.textureTrait = texture
                if let accent = input.photoSnapshot?.colorPalette.dropFirst().first.flatMap(hexString(from:)) {
                    $0.accentColor = accent
                }
            }
        case 3:
            let appendage = appendageTrait(from: highConfidenceLabels)
            return PicoGenomeMutation(traitName: "appendageTrait", reasonTags: ["day3:movement", "appendage:\(appendage)"]) {
                $0.appendageTrait = appendage
            }
        case 4:
            let mark = atmosphereMark(for: input)
            return PicoGenomeMutation(traitName: "anomalyMark", reasonTags: ["day4:atmosphere", "mark:\(mark)"]) {
                $0.anomalyMark = mark
            }
        case 5:
            let scar = memoryScar(from: genome, labels: labels)
            return PicoGenomeMutation(traitName: "memoryScar", reasonTags: ["day5:memory", "scar:\(scar)"]) {
                $0.memoryScar = scar
            }
        case 6:
            let eye = matureEyeTrait(for: input, current: genome.eyeTrait)
            return PicoGenomeMutation(traitName: "eyeTrait", reasonTags: ["day6:mature", "eye:\(eye)"]) {
                $0.eyeTrait = eye
            }
        case 7:
            let finalMark = finalLifeMark(for: input, genome: genome)
            return PicoGenomeMutation(traitName: "anomalyMark", reasonTags: ["day7:final-form", "mark:\(finalMark)"]) {
                $0.anomalyMark = finalMark
            }
        default:
            return PicoGenomeMutation(traitName: "accentColor", reasonTags: ["day:accent"]) {
                if let accent = input.photoSnapshot?.colorPalette.dropFirst().first.flatMap(hexString(from:)) {
                    $0.accentColor = accent
                }
            }
        }
    }

    private func baseBody(for personality: PicoPersonality, labels: [String]) -> String {
        if labels.contains(where: { $0.contains("fish") || $0.contains("water") }) { return "water" }
        if labels.contains(where: { $0.contains("bird") || $0.contains("sky") }) { return "light" }
        switch personality {
        case .natural: return "round"
        case .artifact: return "keepsake"
        case .ethereal: return "mist"
        case .yokai: return "odd"
        }
    }

    private func eyeTrait(for personality: PicoPersonality) -> String {
        switch personality {
        case .natural: return "soft"
        case .artifact: return "button"
        case .ethereal: return "glow"
        case .yokai: return "watching"
        }
    }

    private func textureTrait(from labels: [String]) -> String {
        if labels.contains(where: { $0.contains("paper") || $0.contains("book") }) { return "paper" }
        if labels.contains(where: { $0.contains("water") || $0.contains("rain") }) { return "wet" }
        if labels.contains(where: { $0.contains("tree") || $0.contains("wood") }) { return "bark" }
        if labels.contains(where: { $0.contains("stone") || $0.contains("rock") }) { return "stone" }
        if labels.contains(where: { $0.contains("flower") || $0.contains("grass") }) { return "leaf" }
        return "soft"
    }

    private func appendageTrait(from labels: [String]) -> String {
        if labels.contains(where: { $0.contains("bird") || $0.contains("butterfly") }) { return "winglets" }
        if labels.contains(where: { $0.contains("fish") || $0.contains("water") }) { return "fins" }
        if labels.contains(where: { $0.contains("tree") || $0.contains("branch") }) { return "sprouts" }
        if labels.contains(where: { $0.contains("path") || $0.contains("road") }) { return "steady-feet" }
        return "small"
    }

    private func atmosphereMark(for input: PicoEvolutionInput) -> String {
        if input.activeStoryFlags.contains("umbrella_woman") || input.activeStoryFlags.contains("umbrellaWoman") {
            return "rain-edge"
        }
        if input.activeStoryFlags.contains("night_lamplighter") || input.activeStoryFlags.contains("nightLamplighter") {
            return "lamp-dot"
        }
        switch input.seedMatch.debugInfo.normalizedLabels.first {
        case let label? where label.contains("mirror"):
            return "reflection"
        case let label? where label.contains("fog") || label.contains("mist"):
            return "mist-edge"
        default:
            return "weather-line"
        }
    }

    private func memoryScar(from genome: PicoGenome, labels: [String]) -> String {
        if let anomaly = genome.anomalyMark {
            return "remembered-\(anomaly)"
        }
        if labels.contains(where: { $0.contains("old") || $0.contains("stone") }) {
            return "stone-memory"
        }
        return "first-week-mark"
    }

    private func matureEyeTrait(for input: PicoEvolutionInput, current: String) -> String {
        if input.activeStoryFlags.contains("mirror_miko") || input.activeStoryFlags.contains("mirrorMiko") {
            return "reflected"
        }
        if input.seedMatch.confidence >= 0.72 {
            return "clear"
        }
        return current
    }

    private func finalLifeMark(for input: PicoEvolutionInput, genome: PicoGenome) -> String {
        if input.activeStoryFlags.contains("mirror_miko") || input.activeStoryFlags.contains("mirrorMiko") {
            return "mirror-return"
        }
        return genome.anomalyMark ?? "returning"
    }

    private func inheritedFieldNames() -> [String] {
        [
            "baseBody",
            "coreColor",
            "accentColor",
            "headTrait",
            "appendageTrait",
            "eyeTrait",
            "textureTrait",
            "anomalyMark",
            "memoryScar"
        ]
    }

    private func hexString(from color: PhotoPaletteColor?) -> String? {
        guard let color else { return nil }
        let red = max(0, min(255, Int((color.red * 255.0).rounded())))
        let green = max(0, min(255, Int((color.green * 255.0).rounded())))
        let blue = max(0, min(255, Int((color.blue * 255.0).rounded())))
        return String(format: "%02X%02X%02X", red, green, blue)
    }
}

private struct PicoGenomeMutation {
    let traitName: String
    let reasonTags: [String]
    let apply: (inout PicoGenome) -> Void
}
