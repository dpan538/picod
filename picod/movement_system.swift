import Combine
import Foundation

@MainActor
final class WorldSimulation: ObservableObject {
    @Published private(set) var petCoord: MapCoord
    @Published private(set) var latestLog: String?
    @Published private(set) var latestEvent: PetEvent?
    @Published private(set) var petState: PetState
    @Published private(set) var runtimeProps: [PropPlacement] = []
    @Published private(set) var runtimeAnimals: [AnimalPlacement] = []

    private var map: TestMap
    private var blockedCoords: Set<MapCoord> = []
    private var treeCoords: [MapCoord] = []
    private var birdCoords: [MapCoord] = []
    private var signCoords: [MapCoord] = []
    private var mushroomCoords: [MapCoord] = []
    private var interestingCoords: [MapCoord] = []
    private var pondEdgeCoords: [MapCoord] = []

    private var movementTask: Task<Void, Never>?
    private var rngState: UInt64 = 0x9E3779B97F4A7C15
    private var lastCoord: MapCoord?
    private var recentTrail: [MapCoord] = []
    private var quietStepCounter = 0
    private var eventCooldown = 0
    private var currentLanguageCode = "en"
    private var appState: AppState = .empty

    init(map: TestMap) {
        self.map = map
        self.petCoord = map.petSpawn.coord
        self.petState = .initial(languageCode: "en")
        self.runtimeProps = map.props
        self.runtimeAnimals = map.animals
        rebuildSpatialCaches(for: map)
    }

    private func rebuildSpatialCaches(for map: TestMap) {
        var blocked: Set<MapCoord> = []
        var trees: [MapCoord] = []
        var birds: [MapCoord] = []
        var signs: [MapCoord] = []
        var mushrooms: [MapCoord] = []
        var interests: [MapCoord] = []

        for prop in map.props {
            if prop.kind.isBlockingForPet {
                blocked.insert(prop.coord)
            }

            if prop.kind.isTreeLike { trees.append(prop.coord) }
            if prop.kind.isSignLike { signs.append(prop.coord) }
            if prop.kind.isMushroomLike { mushrooms.append(prop.coord) }
            if prop.kind.isTreeLike || prop.kind.isSignLike || prop.kind.isMushroomLike {
                interests.append(prop.coord)
            }
        }

        for animal in map.animals {
            if animal.kind == .bird { birds.append(animal.coord) }
            interests.append(animal.coord)
        }

        blockedCoords = blocked
        treeCoords = trees
        birdCoords = birds
        signCoords = signs
        mushroomCoords = mushrooms
        interestingCoords = interests
        pondEdgeCoords = Self.computePondEdges(for: map, blocked: blocked)
    }

    func start(languageCode: String, reduceMotion: Bool) {
        stop()

        currentLanguageCode = languageCode
        let intervalSeconds = reduceMotion ? 1.25 : 0.85

        movementTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
                self.step()
            }
        }
    }

    func stop() {
        movementTask?.cancel()
        movementTask = nil
    }

    func setAppState(_ state: AppState) {
        appState = state
        if state != .picoAlive {
            stop()
        }
    }

    func reloadMap(_ nextMap: TestMap, languageCode: String) {
        stop()
        map = nextMap
        petCoord = nextMap.petSpawn.coord
        petState = .initial(languageCode: languageCode)
        latestLog = nil
        latestEvent = nil
        runtimeProps = nextMap.props
        runtimeAnimals = nextMap.animals
        currentLanguageCode = languageCode
        lastCoord = nil
        recentTrail = []
        quietStepCounter = 0
        eventCooldown = 0
        rebuildSpatialCaches(for: nextMap)
    }

    func manualMove(direction: MoveDirection) {
        let delta: (x: Int, y: Int)
        switch direction {
        case .up: delta = (0, -1)
        case .down: delta = (0, 1)
        case .left: delta = (-1, 0)
        case .right: delta = (1, 0)
        }

        let next = MapCoord(x: petCoord.x + delta.x, y: petCoord.y + delta.y)
        guard isWalkable(next) else {
            petState.registerMovementStep(didMove: false)
            return
        }

        lastCoord = petCoord
        petCoord = next
        appendTrail(next)
        petState.registerMovementStep(didMove: true)

        if let event = detectInteractionEvent(at: next) {
            petState.register(event: event)
            latestLog = event.summary
            latestEvent = event
            quietStepCounter = 0
            eventCooldown = 2
        }
    }

    func initialLog(languageCode: String) -> String {
        languageCode == "zh"
            ? "pico 在草地上轻轻地踱步。"
            : "pico is wandering quietly in the meadow."
    }

    func checkIn(weatherCondition: WeatherCondition, languageCode: String) -> String {
        currentLanguageCode = languageCode
        let line = PetResponseGenerator.response(for: petState, weather: weatherCondition, languageCode: languageCode)

        let tapEvent = PetEvent(
            type: .tappedByUser,
            summary: line
        )
        petState.register(event: tapEvent)
        latestEvent = tapEvent
        return line
    }

    func checkIn(weatherCondition: WeatherCondition, formId: Int, languageCode: String) -> String {
        currentLanguageCode = languageCode
        let personality = formId > 0 ? MappingDatabase.personality(for: formId) : PicoPersonality.natural
        let line = PetResponseGenerator.response(
            for: petState,
            weather: weatherCondition,
            personality: personality,
            languageCode: languageCode
        )
        let tapEvent = PetEvent(type: .tappedByUser, summary: line)
        petState.register(event: tapEvent)
        latestEvent = tapEvent
        return line
    }

    private func step() {
        if eventCooldown > 0 {
            eventCooldown -= 1
        }

        // Occasionally pause to avoid robotic stepping.
        if nextRandomDouble() < 0.14 {
            petState.registerMovementStep(didMove: false)
            emitWanderFallbackIfNeeded()
            return
        }

        let previous = petCoord
        let next = chooseNextCoord(from: previous)

        if next != previous {
            lastCoord = previous
            petCoord = next
            appendTrail(next)
            petState.registerMovementStep(didMove: true)
        } else {
            petState.registerMovementStep(didMove: false)
        }

        if let event = detectInteractionEvent(at: petCoord) {
            petState.register(event: event)
            latestLog = event.summary
            latestEvent = event
            quietStepCounter = 0
            eventCooldown = 2
            return
        }

        emitWanderFallbackIfNeeded()
    }

    private func emitWanderFallbackIfNeeded() {
        quietStepCounter += 1
        guard quietStepCounter >= 7 else { return }

        let line = currentLanguageCode == "zh"
            ? "pico 在草地上慢慢散步。"
            : "pico wandered through the meadow."

        let event = PetEvent(type: .wandered, summary: line)
        petState.register(event: event)
        latestLog = line
        latestEvent = event
        quietStepCounter = 0
    }

    private func chooseNextCoord(from current: MapCoord) -> MapCoord {
        let candidates = collectNearbyWalkableTiles(from: current, radius: 2)
        guard !candidates.isEmpty else { return current }

        var weighted: [(coord: MapCoord, score: Double)] = []
        weighted.reserveCapacity(candidates.count)

        for coord in candidates {
            var score = 1.0 + (nextRandomDouble() * 0.35)

            if manhattan(current, coord) == 1 {
                score += 0.28
            }

            if let lastCoord, coord == lastCoord {
                score *= 0.08
            }

            if recentTrail.contains(coord) {
                score *= 0.45
            }

            score += attractionScore(for: coord)

            if score > 0.01 {
                weighted.append((coord, score))
            }
        }

        guard !weighted.isEmpty else { return current }
        return weightedRandomPick(weighted) ?? current
    }

    private func collectNearbyWalkableTiles(from origin: MapCoord, radius: Int) -> [MapCoord] {
        var coords: [MapCoord] = []

        for dy in -radius...radius {
            for dx in -radius...radius {
                let distance = abs(dx) + abs(dy)
                guard distance > 0, distance <= radius else { continue }

                let candidate = MapCoord(x: origin.x + dx, y: origin.y + dy)
                if isWalkable(candidate) {
                    coords.append(candidate)
                }
            }
        }

        return coords
    }

    private func attractionScore(for coord: MapCoord) -> Double {
        var score = 0.0

        if let nearestInterest = nearestDistance(from: coord, among: interestingCoords), nearestInterest <= 3 {
            score += (3.0 - Double(nearestInterest)) * 0.22
        }

        if let nearestPondEdge = nearestDistance(from: coord, among: pondEdgeCoords), nearestPondEdge <= 2 {
            score += (2.0 - Double(nearestPondEdge)) * 0.18
        }

        return score
    }

    private func nearestDistance(from coord: MapCoord, among points: [MapCoord]) -> Int? {
        points.map { manhattan(coord, $0) }.min()
    }

    private func weightedRandomPick(_ weighted: [(coord: MapCoord, score: Double)]) -> MapCoord? {
        let total = weighted.reduce(0.0) { $0 + $1.score }
        guard total > 0 else { return nil }

        var threshold = nextRandomDouble() * total
        for item in weighted {
            threshold -= item.score
            if threshold <= 0 {
                return item.coord
            }
        }
        return weighted.last?.coord
    }

    private func appendTrail(_ coord: MapCoord) {
        recentTrail.append(coord)
        if recentTrail.count > 8 {
            recentTrail.removeFirst(recentTrail.count - 8)
        }
    }

    private func isWalkable(_ coord: MapCoord) -> Bool {
        guard coord.x >= 0, coord.y >= 0, coord.x < map.width, coord.y < map.height else {
            return false
        }

        let terrain = map.terrain.landform(at: coord)
        if terrain.isWaterLike || terrain == .stone || terrain == .stoneGround {
            return false
        }

        return !blockedCoords.contains(coord)
    }

    private func detectInteractionEvent(at coord: MapCoord) -> PetEvent? {
        guard eventCooldown == 0 else { return nil }

        if nearestMatch(to: coord, points: birdCoords, maxDistance: 1) != nil {
            return PetEvent(
                type: .sawAnimal,
                summary: currentLanguageCode == "zh"
                    ? "pico 在草地里注意到一只小鸟。"
                    : "pico noticed a bird in the grass.",
                sourceAnimal: .bird,
                sourcePlace: .grass
            )
        }

        if let sign = nearestMatch(to: coord, points: signCoords, maxDistance: 1) {
            _ = sign
            return PetEvent(
                type: .noticedObject,
                summary: currentLanguageCode == "zh"
                    ? "pico 在木牌旁停了下来。"
                    : "pico paused by the sign.",
                sourceProp: .sign
            )
        }

        if let mushroom = nearestMatch(to: coord, points: mushroomCoords, maxDistance: 1) {
            _ = mushroom
            return PetEvent(
                type: .exploredMushroomPatch,
                summary: currentLanguageCode == "zh"
                    ? "pico 在蘑菇丛边轻轻嗅了嗅。"
                    : "pico sniffed around the mushrooms.",
                sourceProp: .mushroomPatch
            )
        }

        if isNearPond(coord) {
            return PetEvent(
                type: .foundWater,
                summary: currentLanguageCode == "zh"
                    ? "pico 在池塘边绕了一圈。"
                    : "pico wandered by the pond.",
                sourcePlace: .water
            )
        }

        if isNearTreeCluster(coord) {
            return PetEvent(
                type: .restedByTree,
                summary: currentLanguageCode == "zh"
                    ? "pico 在树丛旁安静休息。"
                    : "pico rested near the trees.",
                sourceProp: .tree
            )
        }

        return nil
    }

    private func nearestMatch(to coord: MapCoord, points: [MapCoord], maxDistance: Int) -> MapCoord? {
        points.first { manhattan(coord, $0) <= maxDistance }
    }

    private func isNearPond(_ coord: MapCoord) -> Bool {
        for y in max(0, coord.y - 1)...min(map.height - 1, coord.y + 1) {
            for x in max(0, coord.x - 1)...min(map.width - 1, coord.x + 1) {
                if map.terrain.landform(at: .init(x: x, y: y)).isWaterLike {
                    return true
                }
            }
        }
        return false
    }

    private func isNearTreeCluster(_ coord: MapCoord) -> Bool {
        let count = treeCoords.filter { manhattan($0, coord) <= 2 }.count
        return count >= 2
    }

    private func manhattan(_ a: MapCoord, _ b: MapCoord) -> Int {
        abs(a.x - b.x) + abs(a.y - b.y)
    }

    private func nextRandom() -> UInt64 {
        rngState = 6364136223846793005 &* rngState &+ 1442695040888963407
        return rngState
    }

    private func nextRandomDouble() -> Double {
        Double(nextRandom() & 0xFFFF_FFFF) / Double(UInt32.max)
    }

    private static func computePondEdges(for map: TestMap, blocked: Set<MapCoord>) -> [MapCoord] {
        var edges: [MapCoord] = []

        for y in 0..<map.height {
            for x in 0..<map.width {
                let coord = MapCoord(x: x, y: y)
                if map.terrain.landform(at: coord).isWaterLike {
                    continue
                }

                if blocked.contains(coord) {
                    continue
                }

                let neighbors = [
                    MapCoord(x: x - 1, y: y),
                    MapCoord(x: x + 1, y: y),
                    MapCoord(x: x, y: y - 1),
                    MapCoord(x: x, y: y + 1)
                ]

                let hasWaterNeighbor = neighbors.contains { n in
                    n.x >= 0 && n.y >= 0 && n.x < map.width && n.y < map.height && map.terrain.landform(at: n).isWaterLike
                }

                if hasWaterNeighbor {
                    edges.append(coord)
                }
            }
        }

        return edges
    }
}
