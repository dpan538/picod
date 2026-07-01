import Foundation
import UIKit
import Vision

struct PhotoClassificationPipelineOutput: Codable, Hashable {
    let chosenFormId: Int
    let matchedClusterScores: [ClusterScore]
    let rawVisionTopN: [VisionLabel]
    let normalizedLabels: [String]
}

enum PhotoClassificationPipeline {
    static func classify(image: UIImage, topN: Int = 12) async -> [VisionLabel] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNClassifyImageRequest()
                let handler = VNImageRequestHandler(
                    cgImage: cgImage,
                    orientation: CGImagePropertyOrientation(image.imageOrientation),
                    options: [:]
                )

                do {
                    try handler.perform([request])
                    let observations = (request.results as? [VNClassificationObservation]) ?? []
                    let labels = observations
                        .prefix(topN)
                        .map { VisionLabel(identifier: $0.identifier, confidence: $0.confidence) }
                    continuation.resume(returning: labels)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    static func resolve(from rawLabels: [(identifier: String, confidence: Float)]) -> PhotoClassificationPipelineOutput {
        let rawVisionTopN = rawLabels
            .sorted { $0.confidence > $1.confidence }
            .map { VisionLabel(identifier: $0.identifier, confidence: $0.confidence) }

        let normalized: [VisionLabel] = rawLabels.map {
            VisionLabel(identifier: MappingDatabase.normalize($0.identifier), confidence: $0.confidence)
        }

        let normalizedLabels = normalized.map(\.identifier)
        let scores = computeClusterScores(labels: normalized)
        let winner = pickWinner(from: scores)

        if let winner, winner.primaryScore >= MappingDatabase.confidenceThreshold {
            return PhotoClassificationPipelineOutput(
                chosenFormId: winner.formId,
                matchedClusterScores: scores,
                rawVisionTopN: rawVisionTopN,
                normalizedLabels: normalizedLabels
            )
        }

        let fallbackFormId = resolveFallbackFormId(from: normalizedLabels)
        return PhotoClassificationPipelineOutput(
            chosenFormId: fallbackFormId,
            matchedClusterScores: scores,
            rawVisionTopN: rawVisionTopN,
            normalizedLabels: normalizedLabels
        )
    }

    private static func computeClusterScores(labels: [VisionLabel]) -> [ClusterScore] {
        var output: [ClusterScore] = []
        output.reserveCapacity(MappingDatabase.clusters.count)

        for cluster in MappingDatabase.clusters {
            var primary: Float = 0
            var hits = 0
            var matched: [String] = []

            for label in labels where cluster.keywords.contains(label.identifier) {
                primary += label.confidence
                hits += 1
                matched.append(label.identifier)
            }

            guard hits > 0 else { continue }
            output.append(
                ClusterScore(
                    formId: cluster.formId,
                    clusterName: cluster.name,
                    primaryScore: primary,
                    hitCount: hits,
                    matchedLabels: Array(Set(matched)).sorted(),
                    priorityWeight: cluster.priorityWeight
                )
            )
        }

        return output.sorted {
            if $0.primaryScore != $1.primaryScore { return $0.primaryScore > $1.primaryScore }
            if $0.hitCount != $1.hitCount { return $0.hitCount > $1.hitCount }
            if $0.priorityWeight != $1.priorityWeight { return $0.priorityWeight > $1.priorityWeight }
            return $0.formId < $1.formId
        }
    }

    private static func pickWinner(from scores: [ClusterScore]) -> ClusterScore? {
        scores.first
    }

    private static func resolveFallbackFormId(from normalizedLabels: [String]) -> Int {
        if let rule = bestSpecialRule(for: normalizedLabels), !rule.fallbackFormIds.isEmpty {
            return rule.fallbackFormIds.randomElement() ?? rule.fallbackFormIds[0]
        }

        return Int.random(in: MappingDatabase.spookyFallbackRange)
    }

    private static func bestSpecialRule(for labels: [String]) -> SpecialRuleCategory? {
        let labelSet = Set(labels)
        return MappingDatabase.specialCategories
            .compactMap { category -> (SpecialRuleCategory, Int)? in
                let hitCount = category.keywords.intersection(labelSet).count
                guard hitCount > 0 else { return nil }
                return (category, hitCount)
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.key < rhs.0.key
            }
            .first?
            .0
    }
}

private extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
