import Foundation

enum WorldMapValidationSeverity: String, Codable, Hashable {
    case warning
    case error
}

enum WorldMapValidationCategory: String, CaseIterable, Codable, Hashable {
    case picoSafety = "pico safety"
    case forestEdge = "forest edge"
    case connection = "connection"
    case terrain = "terrain"
    case habitat = "habitat"
    case reachability = "reachability"
}

struct WorldMapValidationIssue: Identifiable, Codable, Hashable {
    let id: String
    let severity: WorldMapValidationSeverity
    let code: String
    let coord: MapCoord?
    let message: String

    var category: WorldMapValidationCategory {
        switch code {
        case "pico_spawn_off_map", "pico_spawn_blocked", "pico_spawn_occlusion_risk", "pico_route_occlusion_risk":
            return .picoSafety
        case "perimeter_forest_sparse":
            return .forestEdge
        case "water_connection_missing", "disconnected_structure", "missing_approach_tile":
            return .connection
        case "terrain_mismatch":
            return .terrain
        case "animal_habitat_mismatch":
            return .habitat
        default:
            return .reachability
        }
    }

    var coordLabel: String {
        guard let coord else { return "map" }
        return "x\(coord.x) y\(coord.y)"
    }

    var debugLine: String {
        "\(severity.rawValue) \(code) @ \(coordLabel): \(message)"
    }
}

struct WorldMapValidationReport: Codable, Hashable {
    let mapName: String
    let issues: [WorldMapValidationIssue]
    let perimeterTreeCount: Int
    let reachableTileCount: Int
    let primaryRouteTileCount: Int
    let disconnectedStructureCount: Int
    let picoOcclusionRiskCount: Int

    var errorCount: Int {
        issues.filter { $0.severity == .error }.count
    }

    var warningCount: Int {
        issues.filter { $0.severity == .warning }.count
    }

    var didPassCoreRules: Bool {
        errorCount == 0
    }

    var summaryLine: String {
        "errors \(errorCount) / warnings \(warningCount) / perimeter trees \(perimeterTreeCount) / reachable \(reachableTileCount) / route \(primaryRouteTileCount)"
    }

    var issueCountsByCode: [(code: String, count: Int)] {
        Dictionary(grouping: issues, by: \.code)
            .map { (code: $0.key, count: $0.value.count) }
            .sorted {
                if $0.count == $1.count {
                    return $0.code < $1.code
                }
                return $0.count > $1.count
            }
    }

    func issues(in category: WorldMapValidationCategory) -> [WorldMapValidationIssue] {
        issues.filter { $0.category == category }
    }

    func warningCount(in category: WorldMapValidationCategory) -> Int {
        issues(in: category).filter { $0.severity == .warning }.count
    }

    func errorCount(in category: WorldMapValidationCategory) -> Int {
        issues(in: category).filter { $0.severity == .error }.count
    }

    func categorySummaryLine(for category: WorldMapValidationCategory) -> String {
        let errors = errorCount(in: category)
        let warnings = warningCount(in: category)
        if errors == 0 && warnings == 0 {
            return "ok"
        }
        return "errors \(errors) / warnings \(warnings)"
    }
}

enum WorldMapValidator {
    static func validate(_ map: TestMap) -> WorldMapValidationReport {
        var validator = Validator(map: map)
        return validator.run()
    }

    static func validate(_ projection: WorldStateProjection, baseMap: TestMap) -> WorldMapValidationReport {
        let projectedProps = WorldProjectionMapAdapter.runtimeProps(from: projection)
        let projectedAnimals = WorldProjectionMapAdapter.runtimeAnimals(from: projection)
        let augmentedMap = TestMap(
            name: "\(baseMap.name) Projection",
            width: baseMap.width,
            height: baseMap.height,
            terrain: baseMap.terrain,
            props: baseMap.props + projectedProps,
            animals: baseMap.animals + projectedAnimals,
            petSpawn: baseMap.petSpawn
        )
        var validator = Validator(map: augmentedMap)
        let mapReport = validator.run()
        let projectionIssues = validateProjectionRules(projection)
        return WorldMapValidationReport(
            mapName: mapReport.mapName,
            issues: Array((mapReport.issues + projectionIssues).prefix(120)),
            perimeterTreeCount: mapReport.perimeterTreeCount,
            reachableTileCount: mapReport.reachableTileCount,
            primaryRouteTileCount: mapReport.primaryRouteTileCount,
            disconnectedStructureCount: mapReport.disconnectedStructureCount,
            picoOcclusionRiskCount: mapReport.picoOcclusionRiskCount
        )
    }

    private static func validateProjectionRules(_ projection: WorldStateProjection) -> [WorldMapValidationIssue] {
        var issues: [WorldMapValidationIssue] = []
        let allElements = projection.allElements

        for (index, element) in allElements.enumerated() {
            let isKnownCatalogID = PropKind(rawValue: element.catalogElementID) != nil ||
                AnimalKind(rawValue: element.catalogElementID) != nil
            if !isKnownCatalogID {
                issues.append(
                    projectionIssue(
                        .error,
                        code: "projection_unknown_catalog_id",
                        index: index,
                        coord: element.tileOrAnchor,
                        "\(element.catalogElementID) is not in the world element catalog"
                    )
                )
            }

            if element.debugReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(
                    projectionIssue(
                        .warning,
                        code: "projection_missing_debug_reason",
                        index: index,
                        coord: element.tileOrAnchor,
                        "\(element.id) has no debug reason"
                    )
                )
            }

            if element.source == .storyTrace && element.evidenceIDs.isEmpty {
                issues.append(
                    projectionIssue(
                        .error,
                        code: "projection_story_trace_missing_evidence",
                        index: index,
                        coord: element.tileOrAnchor,
                        "\(element.id) is a story trace without evidence IDs"
                    )
                )
            }

            if element.source == .cycleRecord && element.evidenceIDs.isEmpty {
                issues.append(
                    projectionIssue(
                        .error,
                        code: "projection_cycle_marker_missing_source",
                        index: index,
                        coord: element.tileOrAnchor,
                        "\(element.id) is a cycle marker without a cycle source"
                    )
                )
            }

            if element.source == .eraMemory && !element.evidenceIDs.contains(projection.eraID.rawValue) {
                issues.append(
                    projectionIssue(
                        .error,
                        code: "projection_era_echo_locked",
                        index: index,
                        coord: element.tileOrAnchor,
                        "\(element.id) lacks unlocked era evidence"
                    )
                )
            }

            if let propKind = PropKind(rawValue: element.catalogElementID) {
                let expectedRole = propKind.worldElementSpec.role
                if element.role != expectedRole && element.role != .photoTrace && element.role != .eraEcho {
                    issues.append(
                        projectionIssue(
                            .warning,
                            code: "projection_role_mismatch",
                            index: index,
                            coord: element.tileOrAnchor,
                            "\(element.id) role \(element.role.rawValue) differs from catalog role \(expectedRole.rawValue)"
                        )
                    )
                }
            }
        }

        let duplicateStoryGroups = Dictionary(
            grouping: allElements.filter { $0.source == .storyTrace },
            by: { "\($0.catalogElementID)|\($0.evidenceIDs.sorted().joined(separator: ","))" }
        )
        for (offset, group) in duplicateStoryGroups.values.filter({ $0.count > 1 }).enumerated() {
            if let first = group.first {
                issues.append(
                    projectionIssue(
                        .warning,
                        code: "projection_duplicate_story_trace",
                        index: 10_000 + offset,
                        coord: first.tileOrAnchor,
                        "duplicate unique story trace for the same evidence"
                    )
                )
            }
        }

        return issues
    }

    private static func projectionIssue(
        _ severity: WorldMapValidationSeverity,
        code: String,
        index: Int,
        coord: MapCoord?,
        _ message: String
    ) -> WorldMapValidationIssue {
        WorldMapValidationIssue(
            id: "\(code)-projection-\(index + 1)",
            severity: severity,
            code: code,
            coord: coord,
            message: message
        )
    }
}

private struct Validator {
    let map: TestMap
    private var issues: [WorldMapValidationIssue] = []
    private var occupiedByBlockingProps = Set<MapCoord>()
    private var perimeterTreeCount = 0
    private var disconnectedStructureCount = 0
    private var picoOcclusionRiskCount = 0

    init(map: TestMap) {
        self.map = map
    }

    mutating func run() -> WorldMapValidationReport {
        buildOccupancy()
        validatePerimeterForest()
        validatePicoSpawn()
        let reachable = reachableTiles(from: map.petSpawn.coord)
        let primaryRoute = primaryRouteTiles(reachable: reachable)
        validateRoutes(reachable: reachable, primaryRoute: primaryRoute)
        validateProps(reachable: reachable)
        validateAnimals()

        return WorldMapValidationReport(
            mapName: map.name,
            issues: Array(issues.prefix(80)),
            perimeterTreeCount: perimeterTreeCount,
            reachableTileCount: reachable.count,
            primaryRouteTileCount: primaryRoute.count,
            disconnectedStructureCount: disconnectedStructureCount,
            picoOcclusionRiskCount: picoOcclusionRiskCount
        )
    }

    private mutating func buildOccupancy() {
        for prop in map.props {
            let spec = prop.kind.worldElementSpec
            if prop.kind.isTreeLike && isPerimeter(prop.coord, band: 4) {
                perimeterTreeCount += 1
            }
            if spec.blocksPico {
                occupiedByBlockingProps.formUnion(cells(for: prop))
            }
        }
    }

    private mutating func validatePerimeterForest() {
        let target = map.width >= 24 && map.height >= 24 ? 35 : 14
        if perimeterTreeCount < target {
            add(
                .warning,
                code: "perimeter_forest_sparse",
                coord: nil,
                "perimeter tree count \(perimeterTreeCount) is below target \(target)"
            )
        }
    }

    private mutating func validatePicoSpawn() {
        let spawn = map.petSpawn.coord
        if !onMap(spawn) {
            add(.error, code: "pico_spawn_off_map", coord: spawn, "Pico spawn is outside the map")
            return
        }
        if occupiedByBlockingProps.contains(spawn) || map.terrain.landform(at: spawn).isWaterLike {
            add(.error, code: "pico_spawn_blocked", coord: spawn, "Pico spawn is blocked by terrain or prop footprint")
        }

        for prop in map.props {
            let spec = prop.kind.worldElementSpec
            guard spec.occlusionClass.isPicoRisk else { continue }
            let nearest = nearestDistance(from: spawn, to: visualCells(for: prop))
            if nearest <= 2 {
                picoOcclusionRiskCount += 1
                add(
                    .warning,
                    code: "pico_spawn_occlusion_risk",
                    coord: prop.coord,
                    "\(prop.kind.rawValue) is too close to Pico spawn"
                )
            }
        }
    }

    private mutating func validateRoutes(reachable: Set<MapCoord>, primaryRoute: [MapCoord]) {
        if reachable.isEmpty {
            add(.error, code: "pico_no_reachable_tiles", coord: map.petSpawn.coord, "Pico has no reachable walking area")
            return
        }

        let pathReachable = reachable.filter { WorldElementCatalog.pathTerrain.contains(map.terrain.landform(at: $0)) }
        if pathReachable.isEmpty {
            add(.warning, code: "pico_no_path_connection", coord: map.petSpawn.coord, "Pico can move, but no path-like route is reachable")
        }

        let corridor = primaryRoute.isEmpty ? Array(reachable.sortedByMapOrder.prefix(24)) : primaryRoute
        for prop in map.props {
            let spec = prop.kind.worldElementSpec
            guard spec.occlusionClass.isPicoRisk else { continue }
            let propCells = visualCells(for: prop)
            if corridor.contains(where: { nearestDistance(from: $0, to: propCells) <= 1 }) {
                picoOcclusionRiskCount += 1
                add(
                    .warning,
                    code: "pico_route_occlusion_risk",
                    coord: prop.coord,
                    "\(prop.kind.rawValue) may crowd a common Pico route"
                )
            }
        }
    }

    private mutating func validateProps(reachable: Set<MapCoord>) {
        for prop in map.props {
            let spec = prop.kind.worldElementSpec
            let footprint = cells(for: prop)

            if spec.connectionRequirements.contains(.water), !touchesWater(footprint) {
                add(.error, code: "water_connection_missing", coord: prop.coord, "\(prop.kind.rawValue) requires water contact")
            }

            if spec.connectionRequirements.contains(.path), !touchesTerrain(footprint, terrain: WorldElementCatalog.pathTerrain) {
                markDisconnected(prop)
            }

            if spec.connectionRequirements.contains(.courtyard), !touchesTerrain(footprint, terrain: WorldElementCatalog.courtyardTerrain) {
                markDisconnected(prop)
            }

            if spec.connectionRequirements.contains(.threshold) && !hasThresholdContext(footprint) {
                markDisconnected(prop)
            }

            if spec.requiresApproachTile && !hasApproachTile(around: footprint, reachable: reachable) {
                add(.warning, code: "missing_approach_tile", coord: prop.coord, "\(prop.kind.rawValue) has no clear approach tile")
            }

            if !spec.compatibleTerrain.isEmpty {
                let anchorLandform = map.terrain.landform(at: prop.coord)
                if !spec.compatibleTerrain.contains(anchorLandform) && spec.role != .flora {
                    add(
                        .warning,
                        code: "terrain_mismatch",
                        coord: prop.coord,
                        "\(prop.kind.rawValue) sits on \(anchorLandform.rawValue), outside preferred terrain"
                    )
                }
            }
        }
    }

    private mutating func validateAnimals() {
        for animal in map.animals where animal.kind.worldElementSpec.connectionRequirements.contains(.water) {
            if !map.terrain.landform(at: animal.coord).isWaterLike {
                add(.warning, code: "animal_habitat_mismatch", coord: animal.coord, "\(animal.kind.rawValue) should stay in water-like terrain")
            }
        }
    }

    private mutating func markDisconnected(_ prop: PropPlacement) {
        disconnectedStructureCount += 1
        add(.warning, code: "disconnected_structure", coord: prop.coord, "\(prop.kind.rawValue) lacks required map connection")
    }

    private func cells(for prop: PropPlacement) -> Set<MapCoord> {
        prop.kind.worldElementSpec.footprint.cells(anchor: prop.coord).filter(onMap)
    }

    private func visualCells(for prop: PropPlacement) -> Set<MapCoord> {
        prop.kind.worldElementSpec.visualFootprint.cells(anchor: prop.coord).filter(onMap)
    }

    private func touchesWater(_ footprint: Set<MapCoord>) -> Bool {
        footprint.contains { map.terrain.landform(at: $0).isWaterLike } ||
            neighbors(of: footprint).contains { map.terrain.landform(at: $0).isWaterLike }
    }

    private func touchesTerrain(_ footprint: Set<MapCoord>, terrain: Set<Landform>) -> Bool {
        footprint.contains { terrain.contains(map.terrain.landform(at: $0)) } ||
            neighbors(of: footprint).contains { terrain.contains(map.terrain.landform(at: $0)) }
    }

    private func hasThresholdContext(_ footprint: Set<MapCoord>) -> Bool {
        touchesTerrain(footprint, terrain: WorldElementCatalog.pathTerrain) ||
            touchesTerrain(footprint, terrain: WorldElementCatalog.courtyardTerrain)
    }

    private func hasApproachTile(around footprint: Set<MapCoord>, reachable: Set<MapCoord>) -> Bool {
        neighbors(of: footprint).contains { reachable.contains($0) && isWalkable($0) }
    }

    private func reachableTiles(from start: MapCoord) -> Set<MapCoord> {
        guard onMap(start), isWalkable(start) else { return [] }
        var visited: Set<MapCoord> = [start]
        var queue: [MapCoord] = [start]
        var index = 0

        while index < queue.count && visited.count < 260 {
            let current = queue[index]
            index += 1
            for next in neighbors(of: current) where !visited.contains(next) && isWalkable(next) {
                visited.insert(next)
                queue.append(next)
            }
        }

        return visited
    }

    private func primaryRouteTiles(reachable: Set<MapCoord>) -> [MapCoord] {
        let start = map.petSpawn.coord
        guard reachable.contains(start) else { return [] }

        let pathCandidates = reachable
            .filter { WorldElementCatalog.pathTerrain.contains(map.terrain.landform(at: $0)) }
            .sorted { lhs, rhs in
                routeTargetScore(lhs) == routeTargetScore(rhs)
                    ? lhs.mapOrderKey < rhs.mapOrderKey
                    : routeTargetScore(lhs) < routeTargetScore(rhs)
            }

        guard let target = pathCandidates.first else { return [] }
        return shortestPath(from: start, to: target)
    }

    private func routeTargetScore(_ coord: MapCoord) -> Int {
        let center = MapCoord(x: map.width / 2, y: map.height / 2)
        let upwardBias = coord.y > center.y ? (coord.y - center.y) * 2 : 0
        return manhattan(coord, center) + upwardBias
    }

    private func shortestPath(from start: MapCoord, to target: MapCoord) -> [MapCoord] {
        guard onMap(start), onMap(target), isWalkable(start), isWalkable(target) else { return [] }
        if start == target { return [start] }

        var visited: Set<MapCoord> = [start]
        var parent: [MapCoord: MapCoord] = [:]
        var queue: [MapCoord] = [start]
        var index = 0

        while index < queue.count && visited.count < 260 {
            let current = queue[index]
            index += 1
            for next in orderedRouteNeighbors(of: current) where !visited.contains(next) && isWalkable(next) {
                visited.insert(next)
                parent[next] = current
                if next == target {
                    return reconstructPath(to: target, parent: parent, start: start)
                }
                queue.append(next)
            }
        }

        return []
    }

    private func reconstructPath(to target: MapCoord, parent: [MapCoord: MapCoord], start: MapCoord) -> [MapCoord] {
        var result: [MapCoord] = [target]
        var current = target
        while current != start {
            guard let next = parent[current] else { return [] }
            current = next
            result.append(current)
        }
        return result.reversed()
    }

    private func isWalkable(_ coord: MapCoord) -> Bool {
        onMap(coord) &&
            !occupiedByBlockingProps.contains(coord) &&
            !map.terrain.landform(at: coord).isWaterLike
    }

    private func isPerimeter(_ coord: MapCoord, band: Int) -> Bool {
        coord.x < band || coord.y < band || coord.x >= map.width - band || coord.y >= map.height - band
    }

    private func nearestDistance(from coord: MapCoord, to cells: Set<MapCoord>) -> Int {
        cells.map { manhattan(coord, $0) }.min() ?? Int.max
    }

    private func manhattan(_ lhs: MapCoord, _ rhs: MapCoord) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y)
    }

    private func neighbors(of cells: Set<MapCoord>) -> Set<MapCoord> {
        Set(cells.flatMap(neighbors(of:))).filter(onMap)
    }

    private func neighbors(of coord: MapCoord) -> [MapCoord] {
        [
            MapCoord(x: coord.x + 1, y: coord.y),
            MapCoord(x: coord.x - 1, y: coord.y),
            MapCoord(x: coord.x, y: coord.y + 1),
            MapCoord(x: coord.x, y: coord.y - 1)
        ].filter(onMap)
    }

    private func orderedRouteNeighbors(of coord: MapCoord) -> [MapCoord] {
        [
            MapCoord(x: coord.x, y: coord.y - 1),
            MapCoord(x: coord.x - 1, y: coord.y),
            MapCoord(x: coord.x + 1, y: coord.y),
            MapCoord(x: coord.x, y: coord.y + 1)
        ].filter(onMap)
    }

    private func onMap(_ coord: MapCoord) -> Bool {
        coord.x >= 0 && coord.y >= 0 && coord.x < map.width && coord.y < map.height
    }

    private mutating func add(_ severity: WorldMapValidationSeverity, code: String, coord: MapCoord?, _ message: String) {
        let index = issues.count + 1
        issues.append(
            WorldMapValidationIssue(
                id: "\(code)-\(index)",
                severity: severity,
                code: code,
                coord: coord,
                message: message
            )
        )
    }
}

private extension MapCoord {
    var mapOrderKey: Int {
        y * 1000 + x
    }
}

private extension Set where Element == MapCoord {
    var sortedByMapOrder: [MapCoord] {
        sorted { $0.mapOrderKey < $1.mapOrderKey }
    }
}
