import Combine
import Foundation
import ImageIO
import Photos
import SwiftUI
import UIKit

enum PhotoCaptureSource: String, Codable, Hashable {
    case camera
    case photoLibrary
    case unknown
}

struct PhotoGPSCoordinate: Codable, Hashable {
    var schemaVersion: Int? = 1
    let latitude: Double
    let longitude: Double
    let altitudeMeters: Double?
}

struct PhotoCaptureMetadata: Codable, Hashable {
    var schemaVersion: Int? = 1
    let source: PhotoCaptureSource
    let hasOriginalImageData: Bool
    let hasEXIF: Bool
    let hasGPS: Bool
    let pixelWidth: Int?
    let pixelHeight: Int?
    let orientation: Int?
    let cameraMake: String?
    let cameraModel: String?
    let lensModel: String?
    let exposureTime: Double?
    let fNumber: Double?
    let isoSpeed: Int?
    let focalLength: Double?
    let originalDateTime: String?
    let gpsCoordinate: PhotoGPSCoordinate?

    static func fromImageData(_ data: Data?, source: PhotoCaptureSource) -> PhotoCaptureMetadata {
        guard let data, !data.isEmpty,
              let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return PhotoCaptureMetadata(
                source: source,
                hasOriginalImageData: data?.isEmpty == false,
                hasEXIF: false,
                hasGPS: false,
                pixelWidth: nil,
                pixelHeight: nil,
                orientation: nil,
                cameraMake: nil,
                cameraModel: nil,
                lensModel: nil,
                exposureTime: nil,
                fNumber: nil,
                isoSpeed: nil,
                focalLength: nil,
                originalDateTime: nil,
                gpsCoordinate: nil
            )
        }

        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any]
        let coordinate = gpsCoordinate(from: gps)

        return PhotoCaptureMetadata(
            source: source,
            hasOriginalImageData: true,
            hasEXIF: exif?.isEmpty == false || tiff?.isEmpty == false,
            hasGPS: coordinate != nil,
            pixelWidth: intValue(properties[kCGImagePropertyPixelWidth]),
            pixelHeight: intValue(properties[kCGImagePropertyPixelHeight]),
            orientation: intValue(properties[kCGImagePropertyOrientation]),
            cameraMake: stringValue(tiff?[kCGImagePropertyTIFFMake]),
            cameraModel: stringValue(tiff?[kCGImagePropertyTIFFModel]),
            lensModel: stringValue(exif?[kCGImagePropertyExifLensModel]),
            exposureTime: doubleValue(exif?[kCGImagePropertyExifExposureTime]),
            fNumber: doubleValue(exif?[kCGImagePropertyExifFNumber]),
            isoSpeed: isoSpeedValue(exif?[kCGImagePropertyExifISOSpeedRatings]),
            focalLength: doubleValue(exif?[kCGImagePropertyExifFocalLength]),
            originalDateTime: stringValue(exif?[kCGImagePropertyExifDateTimeOriginal]),
            gpsCoordinate: coordinate
        )
    }

    private static func gpsCoordinate(from gps: [CFString: Any]?) -> PhotoGPSCoordinate? {
        guard let gps,
              var latitude = doubleValue(gps[kCGImagePropertyGPSLatitude]),
              var longitude = doubleValue(gps[kCGImagePropertyGPSLongitude]) else {
            return nil
        }

        if stringValue(gps[kCGImagePropertyGPSLatitudeRef])?.uppercased() == "S" {
            latitude *= -1
        }
        if stringValue(gps[kCGImagePropertyGPSLongitudeRef])?.uppercased() == "W" {
            longitude *= -1
        }

        var altitude = doubleValue(gps[kCGImagePropertyGPSAltitude])
        if stringValue(gps[kCGImagePropertyGPSAltitudeRef]) == "1", let value = altitude {
            altitude = -value
        }

        return PhotoGPSCoordinate(latitude: latitude, longitude: longitude, altitudeMeters: altitude)
    }

    private static func stringValue(_ value: Any?) -> String? {
        if let string = value as? String, !string.isEmpty { return string }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        if let double = value as? Double { return double }
        if let string = value as? String { return Double(string) }
        return nil
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let number = value as? NSNumber { return number.intValue }
        if let int = value as? Int { return int }
        if let string = value as? String { return Int(string) }
        return nil
    }

    private static func isoSpeedValue(_ value: Any?) -> Int? {
        if let numbers = value as? [NSNumber] { return numbers.first?.intValue }
        if let ints = value as? [Int] { return ints.first }
        return intValue(value)
    }

    func enrichedWithPhotoLibraryAsset(identifier: String?) -> PhotoCaptureMetadata {
        guard let identifier, !identifier.isEmpty else { return self }
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
        guard let asset else { return self }

        let assetCoordinate = asset.location.map {
            PhotoGPSCoordinate(
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude,
                altitudeMeters: $0.verticalAccuracy >= 0 ? $0.altitude : nil
            )
        }
        let assetDate = asset.creationDate.map { ISO8601DateFormatter().string(from: $0) }

        return PhotoCaptureMetadata(
            source: source,
            hasOriginalImageData: hasOriginalImageData,
            hasEXIF: hasEXIF,
            hasGPS: gpsCoordinate != nil || assetCoordinate != nil,
            pixelWidth: pixelWidth ?? asset.pixelWidth,
            pixelHeight: pixelHeight ?? asset.pixelHeight,
            orientation: orientation,
            cameraMake: cameraMake,
            cameraModel: cameraModel,
            lensModel: lensModel,
            exposureTime: exposureTime,
            fNumber: fNumber,
            isoSpeed: isoSpeed,
            focalLength: focalLength,
            originalDateTime: originalDateTime ?? assetDate,
            gpsCoordinate: gpsCoordinate ?? assetCoordinate
        )
    }
}

struct PhotoCaptureEnvironmentSnapshot: Codable, Hashable {
    var schemaVersion: Int? = 1
    let timezoneIdentifier: String
    let localHour: Int
    let timePhase: PicodTimePhase
    let quantizedLatitude: Double
    let quantizedLongitude: Double
    let weatherCondition: PicodWeatherCondition
    let temperatureCelsius: Double?
    let humidityPercent: Double?
    let precipitationChance: Double?
    let weatherFetchedAt: Date?
    let usedResolvedLocation: Bool

    static func from(worldInput: PicodWorldInput) -> PhotoCaptureEnvironmentSnapshot {
        let weather = worldInput.volatile.weather
        return PhotoCaptureEnvironmentSnapshot(
            timezoneIdentifier: worldInput.stable.timezoneIdentifier,
            localHour: worldInput.volatile.localHour,
            timePhase: worldInput.volatile.timePhase,
            quantizedLatitude: worldInput.stable.quantizedLatitude,
            quantizedLongitude: worldInput.stable.quantizedLongitude,
            weatherCondition: weather.condition,
            temperatureCelsius: weather.temperatureCelsius,
            humidityPercent: weather.humidityPercent,
            precipitationChance: weather.precipitationChance,
            weatherFetchedAt: weather.fetchedAt,
            usedResolvedLocation: worldInput.stable.quantizedLatitude != 0 || worldInput.stable.quantizedLongitude != 0
        )
    }
}

struct PicodCapturedPhoto {
    let image: UIImage
    let imageData: Data?
    let metadata: PhotoCaptureMetadata

    init(image: UIImage, imageData: Data?, source: PhotoCaptureSource) {
        self.image = image
        self.imageData = imageData
        self.metadata = PhotoCaptureMetadata.fromImageData(imageData, source: source)
    }

    init(image: UIImage, imageData: Data?, metadata: PhotoCaptureMetadata) {
        self.image = image
        self.imageData = imageData
        self.metadata = metadata
    }
}

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
    let captureMetadata: PhotoCaptureMetadata?
    let captureEnvironment: PhotoCaptureEnvironmentSnapshot?
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
        captureMetadata: PhotoCaptureMetadata? = nil,
        captureEnvironment: PhotoCaptureEnvironmentSnapshot? = nil,
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
        self.captureMetadata = captureMetadata
        self.captureEnvironment = captureEnvironment
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

    init(fileURL: URL) {
        self.fileURL = fileURL
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

    func resetAll() {
        saveTask?.cancel()
        snapshots = []
        try? FileManager.default.removeItem(at: fileURL)
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

    static func extractBackgroundColor(from image: UIImage) -> PhotoPaletteColor? {
        extractPalette(from: image, targetCount: 1).first
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
