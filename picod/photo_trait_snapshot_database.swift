import Foundation
import SwiftUI
import UIKit

struct PhotoPaletteColor: Codable, Hashable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

struct PhotoTraitSnapshot: Codable, Hashable, Identifiable {
    let id: UUID
    let dayKey: String
    let generationId: String
    let dayIndex: Int
    let rawVisionTopN: [VisionLabel]
    let normalizedLabels: [String]
    let matchedClusterScores: [ClusterScore]
    let chosenFormId: Int
    let replacedParts: [PicoPart]
    let colorPalette: [PhotoPaletteColor]
    let timestamp: Date

    init(
        id: UUID = UUID(),
        dayKey: String,
        generationId: String,
        dayIndex: Int,
        rawVisionTopN: [VisionLabel],
        normalizedLabels: [String],
        matchedClusterScores: [ClusterScore],
        chosenFormId: Int,
        replacedParts: [PicoPart],
        colorPalette: [PhotoPaletteColor],
        timestamp: Date
    ) {
        self.id = id
        self.dayKey = dayKey
        self.generationId = generationId
        self.dayIndex = dayIndex
        self.rawVisionTopN = rawVisionTopN
        self.normalizedLabels = normalizedLabels
        self.matchedClusterScores = matchedClusterScores
        self.chosenFormId = chosenFormId
        self.replacedParts = replacedParts
        self.colorPalette = colorPalette
        self.timestamp = timestamp
    }
}

@MainActor
final class PhotoTraitSnapshotDatabase: ObservableObject {
    @Published private(set) var snapshots: [PhotoTraitSnapshot] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var saveTask: Task<Void, Never>?

    init() {
        self.fileURL = Self.makeFileURL()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    @discardableResult
    func insert(_ snapshot: PhotoTraitSnapshot) -> Bool {
        // Unique constraint: one snapshot per dayKey.
        guard !snapshots.contains(where: { $0.dayKey == snapshot.dayKey }) else {
            return false
        }

        snapshots.append(snapshot)
        snapshots.sort { lhs, rhs in
            if lhs.generationId != rhs.generationId { return lhs.generationId < rhs.generationId }
            if lhs.dayIndex != rhs.dayIndex { return lhs.dayIndex < rhs.dayIndex }
            return lhs.timestamp < rhs.timestamp
        }
        scheduleSave()
        return true
    }

    func snapshots(for generationId: String) -> [PhotoTraitSnapshot] {
        snapshots.filter { $0.generationId == generationId }
    }

    func snapshot(for dayKey: String) -> PhotoTraitSnapshot? {
        snapshots.first { $0.dayKey == dayKey }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([PhotoTraitSnapshot].self, from: data) else {
            snapshots = []
            return
        }
        snapshots = decoded
    }

    private func save() {
        guard let data = try? encoder.encode(snapshots) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard let self, !Task.isCancelled else { return }
            self.save()
        }
    }

    static func extractPalette(from image: UIImage, targetCount: Int = 5) -> [PhotoPaletteColor] {
        guard let cgImage = image.cgImage,
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return []
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        guard bytesPerPixel >= 4, width > 0, height > 0 else { return [] }

        let stepX = max(1, width / 32)
        let stepY = max(1, height / 32)
        var buckets: [UInt32: (count: Int, sumR: Double, sumG: Double, sumB: Double, sumA: Double)] = [:]

        for y in stride(from: 0, to: height, by: stepY) {
            for x in stride(from: 0, to: width, by: stepX) {
                let index = (y * width + x) * bytesPerPixel
                let r = Double(bytes[index]) / 255.0
                let g = Double(bytes[index + 1]) / 255.0
                let b = Double(bytes[index + 2]) / 255.0
                let a = Double(bytes[index + 3]) / 255.0

                let keyR = UInt32((r * 7.0).rounded())
                let keyG = UInt32((g * 7.0).rounded())
                let keyB = UInt32((b * 7.0).rounded())
                let key = (keyR << 16) | (keyG << 8) | keyB

                var entry = buckets[key] ?? (0, 0, 0, 0, 0)
                entry.count += 1
                entry.sumR += r
                entry.sumG += g
                entry.sumB += b
                entry.sumA += a
                buckets[key] = entry
            }
        }

        return buckets.values
            .sorted { $0.count > $1.count }
            .prefix(targetCount)
            .map { bucket in
                let c = Double(bucket.count)
                return PhotoPaletteColor(
                    red: bucket.sumR / c,
                    green: bucket.sumG / c,
                    blue: bucket.sumB / c,
                    alpha: bucket.sumA / c
                )
            }
    }

    private static func makeFileURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("picod", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("photo_trait_snapshot_db.json")
    }
}
