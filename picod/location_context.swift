import Combine
import CoreLocation
import Foundation

#if canImport(WeatherKit)
import WeatherKit
#endif

enum PicodLocationAuthorizationState: Equatable {
    case notDetermined
    case denied
    case restricted
    case authorizedWhenInUse
}

enum PicodLocationDataState: Equatable {
    case idle
    case resolving
    case resolved
    case unavailable
}

enum PicodWeatherDataState: Equatable {
    case idle
    case resolving
    case resolved
    case unavailable
}

enum PicodTimePhase: String, Codable {
    case morning
    case afternoon
    case dusk
    case night

    var ambientProgress: Double {
        switch self {
        case .morning: return 0.08
        case .afternoon: return 0.14
        case .dusk: return 0.46
        case .night: return 0.72
        }
    }

    static func from(hour: Int) -> PicodTimePhase {
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<20: return .dusk
        default: return .night
        }
    }
}

struct PicodLocationContext: Equatable {
    let latitude: Double
    let longitude: Double
    let localityName: String?
    let regionName: String?
    let timezoneIdentifier: String
    let localDate: Date
    let localHour: Int
}

enum PicodWeatherCondition: String, Equatable, Codable {
    case clear
    case cloudy
    case rain
    case storm
    case fog
    case snow
    case unknown

    var uiCondition: WeatherCondition {
        switch self {
        case .clear: return .sunny
        case .cloudy: return .cloudy
        case .rain: return .rainy
        case .storm: return .stormy
        case .fog: return .foggy
        case .snow: return .snowy
        case .unknown: return .partlyCloudy
        }
    }
}

struct PicodWeatherContext: Equatable {
    let temperatureCelsius: Double?
    let humidityPercent: Double?
    let condition: PicodWeatherCondition
    let fetchedAt: Date?

    static let unavailable = PicodWeatherContext(
        temperatureCelsius: nil,
        humidityPercent: nil,
        condition: .unknown,
        fetchedAt: nil
    )
}

struct PicodLocationSeed: Equatable {
    // ~0.006 degree ~= 650m latitude band. This is intentionally coarse
    // so small user movement does not churn world identity.
    static let quantizationStepDegrees: Double = 0.006

    let quantizedLatitude: Double
    let quantizedLongitude: Double
    let locationKey: String
    let worldSeed: UInt64

    static func build(from location: PicodLocationContext) -> PicodLocationSeed {
        let qLat = quantize(location.latitude)
        let qLon = quantize(location.longitude)
        let tz = location.timezoneIdentifier
        let region = location.regionName?.lowercased() ?? "region:unknown"
        let key = String(format: "lat:%.3f|lon:%.3f|tz:%@|r:%@", qLat, qLon, tz, region)
        let seed = fnv1a64(key)
        return PicodLocationSeed(
            quantizedLatitude: qLat,
            quantizedLongitude: qLon,
            locationKey: key,
            worldSeed: seed
        )
    }

    private static func quantize(_ value: Double) -> Double {
        (value / quantizationStepDegrees).rounded() * quantizationStepDegrees
    }

    private static func fnv1a64(_ input: String) -> UInt64 {
        let offsetBasis: UInt64 = 14_695_981_039_346_656_037
        let prime: UInt64 = 1_099_511_628_211
        var hash = offsetBasis
        for byte in input.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return hash
    }
}

struct PicodEnvironmentalInfluence: Equatable {
    let waterBias: Double
    let greeneryBias: Double
    let urbanBias: Double
    let elevationBias: Double
    let pathOrientationBias: Double?

    static let neutral = PicodEnvironmentalInfluence(
        waterBias: 0.5,
        greeneryBias: 0.5,
        urbanBias: 0.5,
        elevationBias: 0.5,
        pathOrientationBias: nil
    )
}

struct PicodStableWorldInput: Equatable {
    let quantizedLatitude: Double
    let quantizedLongitude: Double
    let localityName: String?
    let regionName: String?
    let timezoneIdentifier: String
    let worldSeed: UInt64
}

struct PicodVolatileWorldInput: Equatable {
    let localDate: Date
    let localHour: Int
    let timePhase: PicodTimePhase
    let weather: PicodWeatherContext
    let instanceSeed: UInt64
}

struct PicodWorldInput: Equatable {
    let stable: PicodStableWorldInput
    let volatile: PicodVolatileWorldInput
    let environmentalInfluence: PicodEnvironmentalInfluence

    static func fallback(now: Date, timezone: TimeZone = .current) -> PicodWorldInput {
        let hour = Calendar.current.component(.hour, from: now)
        let phase = PicodTimePhase.from(hour: hour)
        let stable = PicodStableWorldInput(
            quantizedLatitude: 0,
            quantizedLongitude: 0,
            localityName: nil,
            regionName: nil,
            timezoneIdentifier: timezone.identifier,
            worldSeed: 0xA11CE_2026
        )
        let volatile = PicodVolatileWorldInput(
            localDate: now,
            localHour: hour,
            timePhase: phase,
            weather: .unavailable,
            instanceSeed: stable.worldSeed ^ UInt64(hour)
        )
        return PicodWorldInput(stable: stable, volatile: volatile, environmentalInfluence: .neutral)
    }
}

protocol PicodWeatherProviding {
    func fetchWeather(at coordinate: CLLocationCoordinate2D, now: Date) async -> PicodWeatherContext
}

protocol EnvironmentalInfluenceProviding {
    func influence(location: PicodLocationContext, weather: PicodWeatherContext) -> PicodEnvironmentalInfluence
}

final class HeuristicEnvironmentalInfluenceProvider: EnvironmentalInfluenceProviding {
    func influence(location: PicodLocationContext, weather: PicodWeatherContext) -> PicodEnvironmentalInfluence {
        let traits = LocationTraitTranslator.traits(from: CLLocation(latitude: location.latitude, longitude: location.longitude))
        let humidityFactor = (weather.humidityPercent ?? 55.0) / 100.0
        let rainBoost = weather.condition == .rain || weather.condition == .storm ? 0.12 : 0.0

        return PicodEnvironmentalInfluence(
            waterBias: min(1.0, max(0.0, traits.watersideBias + rainBoost)),
            greeneryBias: min(1.0, max(0.0, traits.greenBias * 0.7 + humidityFactor * 0.3)),
            urbanBias: traits.urbanBias,
            elevationBias: min(1.0, max(0.0, 1.0 - traits.opennessBias * 0.8)),
            pathOrientationBias: nil
        )
    }
}

final class WeatherKitPicodProvider: PicodWeatherProviding {
    private struct CacheEntry {
        let weather: PicodWeatherContext
        let timestamp: Date
        let key: String
    }

    private let cacheTTL: TimeInterval = 20 * 60
    private var cache: CacheEntry?

    func fetchWeather(at coordinate: CLLocationCoordinate2D, now: Date) async -> PicodWeatherContext {
        let key = Self.coordinateKey(coordinate)
        if let cache, cache.key == key, now.timeIntervalSince(cache.timestamp) < cacheTTL {
            return cache.weather
        }

        #if canImport(WeatherKit)
        do {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let weather = try await WeatherService.shared.weather(for: location)
            let current = weather.currentWeather
            let mapped = PicodWeatherContext(
                temperatureCelsius: current.temperature.converted(to: .celsius).value,
                humidityPercent: current.humidity * 100,
                condition: Self.mapCondition(current.condition),
                fetchedAt: now
            )
            cache = CacheEntry(weather: mapped, timestamp: now, key: key)
            return mapped
        } catch {
            if let cache, cache.key == key {
                return cache.weather
            }
            return .unavailable
        }
        #else
        return .unavailable
        #endif
    }

    private static func coordinateKey(_ coordinate: CLLocationCoordinate2D) -> String {
        let qLat = (coordinate.latitude / 0.01).rounded() * 0.01
        let qLon = (coordinate.longitude / 0.01).rounded() * 0.01
        return String(format: "%.2f|%.2f", qLat, qLon)
    }

    #if canImport(WeatherKit)
    private static func mapCondition(_ condition: WeatherKit.WeatherCondition) -> PicodWeatherCondition {
        switch condition {
        case .clear, .mostlyClear, .hot, .windy:
            return .clear
        case .cloudy, .mostlyCloudy, .partlyCloudy:
            return .cloudy
        case .rain, .drizzle, .heavyRain:
            return .rain
        case .thunderstorms:
            return .storm
        case .foggy, .haze, .smoky:
            return .fog
        case .snow, .heavySnow, .sleet, .flurries, .blizzard:
            return .snow
        default:
            return .unknown
        }
    }
    #endif
}

@MainActor
final class PicodWorldInputService: NSObject, ObservableObject, CLLocationManagerDelegate {
    enum RefreshReason {
        case launch
        case foreground
        case userRequested
    }

    @Published private(set) var authorizationState: PicodLocationAuthorizationState = .notDetermined
    @Published private(set) var locationState: PicodLocationDataState = .idle
    @Published private(set) var weatherState: PicodWeatherDataState = .idle
    @Published private(set) var worldInput: PicodWorldInput = .fallback(now: Date())

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let weatherProvider: PicodWeatherProviding
    private let influenceProvider: EnvironmentalInfluenceProviding
    private let sessionSalt: UInt64 = UInt64.random(in: 1...UInt64.max)

    private var pendingRefreshReason: RefreshReason?
    private var lastResolvedLocation: CLLocation?

    init(
        weatherProvider: PicodWeatherProviding? = nil,
        influenceProvider: EnvironmentalInfluenceProviding? = nil
    ) {
        self.weatherProvider = weatherProvider ?? WeatherKitPicodProvider()
        self.influenceProvider = influenceProvider ?? HeuristicEnvironmentalInfluenceProvider()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = kCLDistanceFilterNone
        updateAuthorizationState(manager.authorizationStatus)
    }

    func requestWhenInUsePermission() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func refresh(reason: RefreshReason) {
        pendingRefreshReason = reason
        let status = manager.authorizationStatus
        updateAuthorizationState(status)

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationState = .resolving
            manager.requestLocation()
        case .notDetermined:
            locationState = .idle
        case .denied, .restricted:
            locationState = .unavailable
            weatherState = .unavailable
            worldInput = fallbackInput(for: Date())
        @unknown default:
            locationState = .unavailable
            weatherState = .unavailable
            worldInput = fallbackInput(for: Date())
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        updateAuthorizationState(status)

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            // If we just got authorization and a refresh was requested, resolve now.
            if pendingRefreshReason != nil {
                refresh(reason: pendingRefreshReason ?? .launch)
            }
        } else if status == .denied || status == .restricted {
            locationState = .unavailable
            weatherState = .unavailable
            worldInput = fallbackInput(for: Date())
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            locationState = .unavailable
            weatherState = .unavailable
            worldInput = fallbackInput(for: Date())
            return
        }

        lastResolvedLocation = location
        Task {
            await resolveWorldInput(from: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        _ = error
        locationState = .unavailable
        if authorizationState == .authorizedWhenInUse {
            weatherState = .unavailable
        }
        worldInput = fallbackInput(for: Date())
    }

    private func updateAuthorizationState(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            authorizationState = .notDetermined
        case .denied:
            authorizationState = .denied
        case .restricted:
            authorizationState = .restricted
        case .authorizedAlways, .authorizedWhenInUse:
            authorizationState = .authorizedWhenInUse
        @unknown default:
            authorizationState = .restricted
        }
    }

    private func resolveWorldInput(from location: CLLocation) async {
        let now = Date()
        let placemark = await reverseGeocode(location)
        let timezone = placemark?.timeZone ?? .current
        let localNow = now
        let localHour = localHour(for: localNow, timezone: timezone)

        let locality = placemarkLocalityName(placemark)
        let region = placemarkRegionName(placemark)

        let locationContext = PicodLocationContext(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            localityName: locality,
            regionName: region,
            timezoneIdentifier: timezone.identifier,
            localDate: localNow,
            localHour: localHour
        )

        locationState = .resolved
        weatherState = .resolving

        let weather = await weatherProvider.fetchWeather(at: location.coordinate, now: now)
        weatherState = weather == .unavailable ? .unavailable : .resolved

        let seed = PicodLocationSeed.build(from: locationContext)
        let phase = PicodTimePhase.from(hour: locationContext.localHour)
        let instanceSeed = buildInstanceSeed(worldSeed: seed.worldSeed, phase: phase, weather: weather, date: localNow)
        let influence = influenceProvider.influence(location: locationContext, weather: weather)

        let stable = PicodStableWorldInput(
            quantizedLatitude: seed.quantizedLatitude,
            quantizedLongitude: seed.quantizedLongitude,
            localityName: locality,
            regionName: region,
            timezoneIdentifier: timezone.identifier,
            worldSeed: seed.worldSeed
        )

        let volatile = PicodVolatileWorldInput(
            localDate: localNow,
            localHour: locationContext.localHour,
            timePhase: phase,
            weather: weather,
            instanceSeed: instanceSeed
        )

        worldInput = PicodWorldInput(stable: stable, volatile: volatile, environmentalInfluence: influence)
    }

    private func fallbackInput(for now: Date) -> PicodWorldInput {
        // Keep stable world identity if we already resolved once, even if temporary refresh fails.
        if let lastResolvedLocation {
            let timezone = TimeZone.current
            let hour = localHour(for: now, timezone: timezone)
            let localContext = PicodLocationContext(
                latitude: lastResolvedLocation.coordinate.latitude,
                longitude: lastResolvedLocation.coordinate.longitude,
                localityName: worldInput.stable.localityName,
                regionName: worldInput.stable.regionName,
                timezoneIdentifier: timezone.identifier,
                localDate: now,
                localHour: hour
            )
            let seed = PicodLocationSeed.build(from: localContext)
            let phase = PicodTimePhase.from(hour: hour)
            let stable = PicodStableWorldInput(
                quantizedLatitude: seed.quantizedLatitude,
                quantizedLongitude: seed.quantizedLongitude,
                localityName: worldInput.stable.localityName,
                regionName: worldInput.stable.regionName,
                timezoneIdentifier: timezone.identifier,
                worldSeed: seed.worldSeed
            )
            let volatile = PicodVolatileWorldInput(
                localDate: now,
                localHour: hour,
                timePhase: phase,
                weather: .unavailable,
                instanceSeed: buildInstanceSeed(worldSeed: seed.worldSeed, phase: phase, weather: .unavailable, date: now)
            )
            return PicodWorldInput(stable: stable, volatile: volatile, environmentalInfluence: .neutral)
        }

        return .fallback(now: now)
    }

    private func reverseGeocode(_ location: CLLocation) async -> CLPlacemark? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first
        } catch {
            return nil
        }
    }

    private func placemarkLocalityName(_ placemark: CLPlacemark?) -> String? {
        guard let placemark else { return nil }
        if let locality = placemark.locality, !locality.isEmpty {
            return locality
        }
        if let subAdmin = placemark.subAdministrativeArea, !subAdmin.isEmpty {
            return subAdmin
        }
        if let admin = placemark.administrativeArea, !admin.isEmpty {
            return admin
        }
        if let country = placemark.country, !country.isEmpty {
            return country
        }
        return nil
    }

    private func placemarkRegionName(_ placemark: CLPlacemark?) -> String? {
        guard let placemark else { return nil }
        if let admin = placemark.administrativeArea, !admin.isEmpty {
            return admin
        }
        if let subAdmin = placemark.subAdministrativeArea, !subAdmin.isEmpty {
            return subAdmin
        }
        if let country = placemark.country, !country.isEmpty {
            return country
        }
        return nil
    }

    private func localHour(for date: Date, timezone: TimeZone) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar.component(.hour, from: date)
    }

    private func buildInstanceSeed(
        worldSeed: UInt64,
        phase: PicodTimePhase,
        weather: PicodWeatherContext,
        date: Date
    ) -> UInt64 {
        let phaseHash = UInt64(abs(phase.rawValue.hashValue % 10_000))
        let weatherHash = UInt64(abs(weather.condition.rawValue.hashValue % 10_000))
        let dayOfYear = UInt64(Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1)
        var seed = worldSeed
        seed ^= phaseHash &* 0x9E37
        seed ^= weatherHash &* 0xC2B2
        seed ^= dayOfYear &* 0x27D4
        seed ^= sessionSalt
        return seed
    }

    var dashboardWeather: (tempText: String, humidText: String, condition: WeatherCondition) {
        let weather = worldInput.volatile.weather
        let temp = weather.temperatureCelsius.map { "\(Int($0.rounded()))°" } ?? "--°"
        let humid = weather.humidityPercent.map { "\(Int($0.rounded()))%" } ?? "--%"
        return (temp, humid, weather.condition.uiCondition)
    }
}
