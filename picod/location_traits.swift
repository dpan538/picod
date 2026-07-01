import CoreLocation
import Foundation

struct LocationTraits: Codable, Equatable {
    var watersideBias: Double
    var greenBias: Double
    var urbanBias: Double
    var opennessBias: Double

    init(watersideBias: Double, greenBias: Double, urbanBias: Double, opennessBias: Double) {
        self.watersideBias = Self.clamp(watersideBias)
        self.greenBias = Self.clamp(greenBias)
        self.urbanBias = Self.clamp(urbanBias)
        self.opennessBias = Self.clamp(opennessBias)
    }

    static let neutral = LocationTraits(watersideBias: 0.5, greenBias: 0.5, urbanBias: 0.5, opennessBias: 0.5)

    static let parkLike = LocationTraits(watersideBias: 0.45, greenBias: 0.78, urbanBias: 0.24, opennessBias: 0.52)
    static let watersideLike = LocationTraits(watersideBias: 0.88, greenBias: 0.58, urbanBias: 0.22, opennessBias: 0.57)
    static let urbanLike = LocationTraits(watersideBias: 0.18, greenBias: 0.28, urbanBias: 0.86, opennessBias: 0.34)
    static let openFieldLike = LocationTraits(watersideBias: 0.24, greenBias: 0.56, urbanBias: 0.16, opennessBias: 0.92)

    private static func clamp(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }
}

enum LocationTraitPreset: String, CaseIterable, Codable {
    case parkLike
    case watersideLike
    case urbanLike
    case openFieldLike

    var traits: LocationTraits {
        switch self {
        case .parkLike: return .parkLike
        case .watersideLike: return .watersideLike
        case .urbanLike: return .urbanLike
        case .openFieldLike: return .openFieldLike
        }
    }
}

// Lightweight bridge for future live CoreLocation integration.
// This intentionally biases generation mood rather than attempting literal map reconstruction.
struct LocationTraitTranslator {
    static func traits(from location: CLLocation, speed: CLLocationSpeed? = nil) -> LocationTraits {
        let lat = abs(location.coordinate.latitude)
        let lon = abs(location.coordinate.longitude)

        let pseudoWater = fmod((lat * 0.73 + lon * 1.11), 1.0)
        let pseudoGreen = fmod((lat * 1.37 + lon * 0.41), 1.0)
        let pseudoUrban = fmod((lat * 0.29 + lon * 1.89), 1.0)
        let motion = min(1.0, max(0.0, (speed ?? 0) / 18.0))
        let openness = min(1.0, max(0.0, (0.65 - pseudoUrban * 0.45) + motion * 0.2))

        return LocationTraits(
            watersideBias: pseudoWater,
            greenBias: pseudoGreen,
            urbanBias: pseudoUrban,
            opennessBias: openness
        )
    }
}
