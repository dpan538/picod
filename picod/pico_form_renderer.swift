import Foundation

enum PicoPart: String, Codable, CaseIterable, Hashable {
    case head
    case limbs
    case body
}

struct PartPriority: Codable, Hashable {
    let formId: Int
    let order: [PicoPart]
}

struct PicoRenderResult: Codable, Hashable {
    let generationId: String
    let dayIndex: Int
    let chosenFormId: Int
    let partForms: [PicoPart: Int]
    let replacedParts: [PicoPart]
}

enum PicoFormRenderer {
    private static let defaultOrder: [PicoPart] = [.head, .limbs, .body]

    // Per-form override: snake-like form changes body first.
    private static let overrides: [Int: [PicoPart]] = [
        8: [.body, .head, .limbs]
    ]

    static func priority(for formId: Int) -> PartPriority {
        PartPriority(formId: formId, order: overrides[formId] ?? defaultOrder)
    }

    static func render(
        generationId: String,
        dayIndex: Int,
        chosenFormId: Int,
        existingSnapshots: [PhotoTraitSnapshot]
    ) -> PicoRenderResult {
        let generationSnapshots = existingSnapshots
            .filter { $0.generationId == generationId }
            .sorted { lhs, rhs in
                if lhs.dayIndex != rhs.dayIndex { return lhs.dayIndex < rhs.dayIndex }
                return lhs.timestamp < rhs.timestamp
            }

        let baseFormId = generationSnapshots.first(where: { $0.dayIndex == 1 })?.chosenFormId
            ?? generationSnapshots.first?.chosenFormId
            ?? chosenFormId

        var partForms: [PicoPart: Int] = [
            .head: baseFormId,
            .limbs: baseFormId,
            .body: baseFormId
        ]

        var replacedSet = Set<PicoPart>()

        // Replay previous daily replacements (day2~day7) to reconstruct current mixed form.
        for snapshot in generationSnapshots where snapshot.dayIndex >= 2 {
            for part in snapshot.replacedParts {
                partForms[part] = snapshot.chosenFormId
                replacedSet.insert(part)
            }
        }

        if dayIndex <= 1 {
            let allParts = PicoPart.allCases
            return PicoRenderResult(
                generationId: generationId,
                dayIndex: dayIndex,
                chosenFormId: chosenFormId,
                partForms: [.head: chosenFormId, .limbs: chosenFormId, .body: chosenFormId],
                replacedParts: allParts
            )
        }

        let order = priority(for: chosenFormId).order
        let nextPart = order.first(where: { !replacedSet.contains($0) }) ?? order[0]
        partForms[nextPart] = chosenFormId

        return PicoRenderResult(
            generationId: generationId,
            dayIndex: dayIndex,
            chosenFormId: chosenFormId,
            partForms: partForms,
            replacedParts: [nextPart]
        )
    }
}
