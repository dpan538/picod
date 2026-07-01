import Foundation
import SwiftUI

struct PhotoPipelineMockCaseResult: Hashable {
    let name: String
    let passed: Bool
    let details: String
    let inputSummary: String
    let expectedSummary: String
    let actualSummary: String
}

struct PhotoPipelineMockReport: Hashable {
    let results: [PhotoPipelineMockCaseResult]

    var passedCount: Int { results.filter(\.passed).count }
    var totalCount: Int { results.count }
    var summary: String { "mock validation: \(passedCount)/\(totalCount) passed" }
}

enum PhotoPipelineMockValidator {
    static func runAll() -> PhotoPipelineMockReport {
        let scenario1 = validateNormalHit()
        let scenario2 = validateMultiClusterCompetition()
        let scenario3 = validateLowConfidenceSpookyFallback()
        let scenario4 = validateSpecialFaceFallback()
        let scenario5 = validateDuplicateDayKeyRejection()
        let scenario6 = validateDay1Day2Overlay()

        return PhotoPipelineMockReport(results: [scenario1, scenario2, scenario3, scenario4, scenario5, scenario6])
    }

    private static func validateNormalHit() -> PhotoPipelineMockCaseResult {
        let output = PhotoClassificationPipeline.resolve(from: [
            ("cat", 0.92),
            ("tabby", 0.71),
            ("pet", 0.65)
        ])
        let passed = output.chosenFormId == 1
        return .init(
            name: "scenario1_normal_hit",
            passed: passed,
            details: "expected 1, got \(output.chosenFormId)",
            inputSummary: "[cat:0.92, tabby:0.71, pet:0.65]",
            expectedSummary: "chosenFormId = 1 (狸猫)",
            actualSummary: "chosenFormId = \(output.chosenFormId)"
        )
    }

    private static func validateMultiClusterCompetition() -> PhotoPipelineMockCaseResult {
        // Keep intent from review note: cat-side should win over mushroom-side.
        let output = PhotoClassificationPipeline.resolve(from: [
            ("cat", 0.55),
            ("tabby", 0.53),
            ("mushroom", 0.48)
        ])
        let passed = output.chosenFormId == 1
        return .init(
            name: "scenario2_multi_cluster",
            passed: passed,
            details: "expected 1, got \(output.chosenFormId)",
            inputSummary: "[cat:0.55, tabby:0.53, mushroom:0.48]",
            expectedSummary: "cat簇胜出，chosenFormId = 1",
            actualSummary: "chosenFormId = \(output.chosenFormId)"
        )
    }

    private static func validateLowConfidenceSpookyFallback() -> PhotoPipelineMockCaseResult {
        let output = PhotoClassificationPipeline.resolve(from: [
            ("object", 0.35),
            ("thing", 0.28)
        ])
        let passed = MappingDatabase.spookyFallbackRange.contains(output.chosenFormId)
        return .init(
            name: "scenario3_low_confidence_spooky",
            passed: passed,
            details: "expected 21...35, got \(output.chosenFormId)",
            inputSummary: "[object:0.35, thing:0.28]",
            expectedSummary: "chosenFormId in 21...35",
            actualSummary: "chosenFormId = \(output.chosenFormId)"
        )
    }

    private static func validateSpecialFaceFallback() -> PhotoPipelineMockCaseResult {
        let output = PhotoClassificationPipeline.resolve(from: [
            ("face", 0.88),
            ("person", 0.75)
        ])
        let expected = Set([22, 28])
        let passed = expected.contains(output.chosenFormId)
        return .init(
            name: "scenario4_special_face",
            passed: passed,
            details: "expected 22 or 28, got \(output.chosenFormId)",
            inputSummary: "[face:0.88, person:0.75]",
            expectedSummary: "chosenFormId = 22 or 28",
            actualSummary: "chosenFormId = \(output.chosenFormId)"
        )
    }

    private static func validateDuplicateDayKeyRejection() -> PhotoPipelineMockCaseResult {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("picod_mock_snapshot_\(UUID().uuidString).json")

        let db = PhotoTraitSnapshotDatabase(fileURL: tempURL)
        let sharedDayKey = "mock_gen_day1_\(UUID().uuidString)"

        let first = db.insert(mockSnapshot(dayKey: sharedDayKey, generationId: "mock_gen", dayIndex: 1, formId: 1, replacedParts: [.head, .limbs, .body]))
        let second = db.insert(mockSnapshot(dayKey: sharedDayKey, generationId: "mock_gen", dayIndex: 1, formId: 51, replacedParts: [.head]))

        try? FileManager.default.removeItem(at: tempURL)

        let passed = first && !second
        return .init(
            name: "scenario5_duplicate_day_key",
            passed: passed,
            details: "expected first=true second=false, got first=\(first) second=\(second)",
            inputSummary: "same dayKey insert twice",
            expectedSummary: "first insert accepted, second rejected",
            actualSummary: "first=\(first), second=\(second)"
        )
    }

    private static func validateDay1Day2Overlay() -> PhotoPipelineMockCaseResult {
        let generationId = "mock_gen_overlay"

        let day1Render = PicoFormRenderer.render(
            generationId: generationId,
            dayIndex: 1,
            chosenFormId: 1,
            existingSnapshots: []
        )

        let day1Snapshot = mockSnapshot(
            dayKey: "\(generationId)_day1",
            generationId: generationId,
            dayIndex: 1,
            formId: 1,
            replacedParts: day1Render.replacedParts
        )

        let day2Render = PicoFormRenderer.render(
            generationId: generationId,
            dayIndex: 2,
            chosenFormId: 51,
            existingSnapshots: [day1Snapshot]
        )

        let head = day2Render.partForms[.head]
        let limbs = day2Render.partForms[.limbs]
        let body = day2Render.partForms[.body]

        let passed = (head == 51) && (limbs == 1) && (body == 1) && (day2Render.replacedParts == [.head])
        return .init(
            name: "scenario6_day1_day2_overlay",
            passed: passed,
            details: "expected head=51 limbs=1 body=1 replaced=[head], got head=\(head ?? -1) limbs=\(limbs ?? -1) body=\(body ?? -1) replaced=\(day2Render.replacedParts.map(\.rawValue))",
            inputSummary: "Day1 form=1, Day2 form=51",
            expectedSummary: "蘑菇头 + 狸猫四肢 + 狸猫躯干",
            actualSummary: "head=\(head ?? -1), limbs=\(limbs ?? -1), body=\(body ?? -1), replaced=\(day2Render.replacedParts.map(\.rawValue))"
        )
    }

    private static func mockSnapshot(
        dayKey: String,
        generationId: String,
        dayIndex: Int,
        formId: Int,
        replacedParts: [PicoPart]
    ) -> PhotoTraitSnapshot {
        PhotoTraitSnapshot(
            dayKey: dayKey,
            generationId: generationId,
            dayIndex: dayIndex,
            rawVisionTopN: [],
            normalizedLabels: [],
            matchedClusterScores: [],
            chosenFormId: formId,
            replacedParts: replacedParts,
            colorPalette: [],
            timestamp: Date()
        )
    }
}

struct PhotoPipelineMockScenarioCardView: View {
    let result: PhotoPipelineMockCaseResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.name)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                Spacer()
                Text(result.passed ? "PASS" : "FAIL")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(result.passed ? .green : .red)
            }
            Group {
                Text("input: \(result.inputSummary)")
                Text("expected: \(result.expectedSummary)")
                Text("actual: \(result.actualSummary)")
                Text("check: \(result.details)")
            }
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundColor(.primary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
    }
}

private struct PhotoPipelineSingleScenarioPreview: View {
    let scenarioIndex: Int
    private var scenario: PhotoPipelineMockCaseResult {
        let all = PhotoPipelineMockValidator.runAll().results
        let safeIndex = max(0, min(all.count - 1, scenarioIndex))
        return all[safeIndex]
    }

    var body: some View {
        PhotoPipelineMockScenarioCardView(result: scenario)
            .frame(width: 430, height: 220)
            .background(Color(.secondarySystemBackground))
    }
}

#Preview("Mock-Scenario-1") {
    PhotoPipelineSingleScenarioPreview(scenarioIndex: 0)
}

#Preview("Mock-Scenario-2") {
    PhotoPipelineSingleScenarioPreview(scenarioIndex: 1)
}

#Preview("Mock-Scenario-3") {
    PhotoPipelineSingleScenarioPreview(scenarioIndex: 2)
}

#Preview("Mock-Scenario-4") {
    PhotoPipelineSingleScenarioPreview(scenarioIndex: 3)
}

#Preview("Mock-Scenario-5") {
    PhotoPipelineSingleScenarioPreview(scenarioIndex: 4)
}

#Preview("Mock-Scenario-6") {
    PhotoPipelineSingleScenarioPreview(scenarioIndex: 5)
}
