import Foundation

extension TestMapFactory {
    static let fullWorld: TestMap = fullWorld(context: .devPreset(.parkLike))

    static func fullWorld(context: WorldGenerationContext) -> TestMap {
        let width = 28
        let height = 28
        var terrain = TerrainLayer(width: width, height: height, fill: .grass)

        func fail(_ reason: String) -> Never {
            fatalError("Map generation failed: \(reason)")
        }

        func onMap(_ c: MapCoord) -> Bool {
            c.x >= 0 && c.x < width && c.y >= 0 && c.y < height
        }

        func inPlay(_ c: MapCoord) -> Bool {
            c.x >= 1 && c.y >= 1 && c.x < width - 1 && c.y < height - 1
        }

        func paint(_ land: Landform, _ c: MapCoord) {
            guard onMap(c) else { return }
            terrain.set(land, at: c)
        }

        func isForestBelt(_ xx: Int, _ yy: Int) -> Bool {
            xx <= 2 || xx >= 25 || yy <= 2 || yy >= 25
        }

        enum Facing {
            case north
            case south
            case east
            case west
        }

        enum ZoneID: Hashable {
            case courtyard
            case pagodaPrecinct
            case waterside
            case forestEdge
        }

        struct RectZone {
            let minX: Int
            let maxX: Int
            let minY: Int
            let maxY: Int

            func contains(_ c: MapCoord) -> Bool {
                c.x >= minX && c.x <= maxX && c.y >= minY && c.y <= maxY
            }
        }

        struct GenerationZones {
            let courtyard_zone: RectZone
            let pagoda_precinct_zone: RectZone
            let waterside_zone: RectZone
            let forest_edge_zone: Set<MapCoord>

            func zoneSet(for c: MapCoord) -> Set<ZoneID> {
                var result = Set<ZoneID>()
                if courtyard_zone.contains(c) { result.insert(.courtyard) }
                if pagoda_precinct_zone.contains(c) { result.insert(.pagodaPrecinct) }
                if waterside_zone.contains(c) { result.insert(.waterside) }
                if forest_edge_zone.contains(c) { result.insert(.forestEdge) }
                return result
            }
        }

        enum ElementRole {
            case mainHall
            case eastAuxiliary
            case westAuxiliary
            case pagoda
            case torii
            case shrine
            case dock
            case gate
            case bridge
            case wall
            case cherryTree
            case forestTree
            case reed
            case flower
            case stone
            case lantern
            case signpost
        }

        struct PlacementRule {
            let footprintWidth: Int
            let footprintHeight: Int
            let facing: Facing
            let clearanceToWater: Int
            let clearanceToPath: Int
            let clearanceToBuildings: Int
            let allowedZones: Set<ZoneID>
            let forbiddenZones: Set<ZoneID>
            let validationRules: [String]
        }

        struct PlacedElement {
            let kind: PropKind
            let role: ElementRole
            let anchor: MapCoord
            let rule: PlacementRule
            let footprint: Set<MapCoord>
        }

        func footprintCells(anchor: MapCoord, width w: Int, height h: Int) -> Set<MapCoord> {
            let minX = w.isMultiple(of: 2) ? anchor.x - (w / 2) + 1 : anchor.x - (w / 2)
            let maxX = minX + w - 1
            let minY = anchor.y - h + 1
            let maxY = anchor.y

            var cells = Set<MapCoord>()
            for yy in minY...maxY {
                for xx in minX...maxX {
                    let c = MapCoord(x: xx, y: yy)
                    if onMap(c) { cells.insert(c) }
                }
            }
            return cells
        }

        func manhattanDistance(_ a: MapCoord, _ b: MapCoord) -> Int {
            abs(a.x - b.x) + abs(a.y - b.y)
        }

        func hasNearWater(_ c: MapCoord, water: Set<MapCoord>, maxDistance: Int = 1) -> Bool {
            for w in water where manhattanDistance(c, w) <= maxDistance {
                return true
            }
            return false
        }

        func isMajorStructure(_ role: ElementRole) -> Bool {
            role == .mainHall || role == .eastAuxiliary || role == .westAuxiliary || role == .pagoda || role == .torii || role == .shrine || role == .dock
        }

        // ============================================================
        // Layer 1: Landform (terrain + creek + path skeleton only)
        // ============================================================
        var forestEdgeCells = Set<MapCoord>()
        for yy in 0..<height {
            for xx in 0..<width {
                if isForestBelt(xx, yy) {
                    let c = MapCoord(x: xx, y: yy)
                    forestEdgeCells.insert(c)
                    terrain.set(.forestEdge, at: c)
                }
            }
        }

        for yy in 3...24 {
            for xx in 3...24 {
                guard !isForestBelt(xx, yy) else { continue }
                let c = MapCoord(x: xx, y: yy)
                let h = (xx * 47 &+ yy * 83) % 25
                paint(h == 0 ? .groveFloor : .clearing, c)
            }
        }

        var creekCells = Set<MapCoord>()
        for xx in 4...23 {
            creekCells.insert(MapCoord(x: xx, y: 13))
            if (xx + xx / 4) % 2 == 0 { creekCells.insert(MapCoord(x: xx, y: 14)) }
            if xx % 6 == 2 { creekCells.insert(MapCoord(x: xx, y: 12)) }
        }
        for c in creekCells where inPlay(c) {
            terrain.set(.shallowWater, at: c)
        }

        var pathCells = Set<MapCoord>()
        func addPath(_ c: MapCoord) {
            guard inPlay(c) else { return }
            if creekCells.contains(c) {
                fail("path-water direct crossing at \(c) without bridge segment")
            }
            pathCells.insert(c)
            terrain.set(.stoneGround, at: c)
        }

        // South entrance -> courtyard -> main hall axis.
        for yy in 14...25 { addPath(MapCoord(x: 14, y: yy)) }

        // Main hall front and courtyard circulation.
        for xx in 12...16 { addPath(MapCoord(x: xx, y: 21)) }
        for xx in 10...14 { addPath(MapCoord(x: xx, y: 22)) }
        for xx in 14...17 { addPath(MapCoord(x: xx, y: 20)) }

        // West / east auxiliary branches.
        for xx in 10...14 { addPath(MapCoord(x: xx, y: 22)) }
        for xx in 14...17 { addPath(MapCoord(x: xx, y: 20)) }

        // North side crossing need: south approach and north approach split by creek.
        addPath(MapCoord(x: 14, y: 11))
        addPath(MapCoord(x: 14, y: 10))

        // Pagoda branch and ritual path.
        for xx in 14...19 { addPath(MapCoord(x: xx, y: 10)) }
        for xx in 19...21 { addPath(MapCoord(x: xx, y: 10)) }

        // Waterside branch (no direct water crossing).
        for xx in 14...19 { addPath(MapCoord(x: xx, y: 15)) }

        // Terrain polish near paths.
        var dirtCells = Set<MapCoord>()
        for p in pathCells {
            for d in [(0, 1), (0, -1), (1, 0), (-1, 0)] {
                let n = MapCoord(x: p.x + d.0, y: p.y + d.1)
                guard inPlay(n), !pathCells.contains(n), !creekCells.contains(n) else { continue }
                dirtCells.insert(n)
            }
        }
        for c in dirtCells {
            terrain.set(.dirt, at: c)
        }

        // ============================================================
        // Layer 2: Zones (explicit and inspectable)
        // ============================================================
        let zones = GenerationZones(
            courtyard_zone: RectZone(minX: 9, maxX: 19, minY: 16, maxY: 24),
            pagoda_precinct_zone: RectZone(minX: 18, maxX: 23, minY: 5, maxY: 11),
            waterside_zone: RectZone(minX: 18, maxX: 24, minY: 12, maxY: 16),
            forest_edge_zone: forestEdgeCells
        )

        if creekCells.contains(where: { zones.courtyard_zone.contains($0) }) {
            fail("courtyard zone is cut by creek")
        }

        for yy in zones.courtyard_zone.minY...zones.courtyard_zone.maxY {
            for xx in zones.courtyard_zone.minX...zones.courtyard_zone.maxX {
                let c = MapCoord(x: xx, y: yy)
                guard inPlay(c), !pathCells.contains(c), !creekCells.contains(c) else { continue }
                terrain.set(.dirt, at: c)
            }
        }

        for yy in zones.pagoda_precinct_zone.minY...zones.pagoda_precinct_zone.maxY {
            for xx in zones.pagoda_precinct_zone.minX...zones.pagoda_precinct_zone.maxX {
                let c = MapCoord(x: xx, y: yy)
                guard inPlay(c), !pathCells.contains(c), !creekCells.contains(c) else { continue }
                terrain.set(.dirt, at: c)
            }
        }

        // ============================================================
        // Shared placement state and rules
        // ============================================================
        var props: [PropPlacement] = []
        var placedElements: [PlacedElement] = []

        var occupiedSolid = Set<MapCoord>()
        var occupiedBuildings = Set<MapCoord>()
        var occupiedWalls = Set<MapCoord>()
        var occupiedTrees = Set<MapCoord>()

        let southAxis = Set((14...25).map { MapCoord(x: 14, y: $0) })

        func place(kind: PropKind, role: ElementRole, anchor: MapCoord, rule: PlacementRule) {
            guard onMap(anchor) else { fail("\(role) anchor off map: \(anchor)") }

            let footprint = footprintCells(anchor: anchor, width: rule.footprintWidth, height: rule.footprintHeight)
            if footprint.isEmpty { fail("\(role) has empty footprint") }
            if footprint.contains(where: { !onMap($0) }) { fail("\(role) footprint out of map") }
            if footprint.contains(where: { creekCells.contains($0) }) {
                fail("\(role) footprint overlaps water")
            }
            if footprint.contains(where: { occupiedSolid.contains($0) }) {
                fail("\(role) footprint overlaps existing solids")
            }
            if footprint.contains(where: { pathCells.contains($0) }) {
                fail("\(role) footprint overlaps path")
            }

            // Zone checks.
            if !rule.allowedZones.isEmpty {
                for cell in footprint {
                    let z = zones.zoneSet(for: cell)
                    if z.intersection(rule.allowedZones).isEmpty {
                        fail("\(role) cell \(cell) not in allowed zones")
                    }
                }
            }
            for cell in footprint {
                let z = zones.zoneSet(for: cell)
                if !z.intersection(rule.forbiddenZones).isEmpty {
                    fail("\(role) cell \(cell) in forbidden zone")
                }
            }

            // Clearance checks.
            if rule.clearanceToWater > 0 {
                for cell in footprint {
                    for w in creekCells {
                        if manhattanDistance(cell, w) < rule.clearanceToWater {
                            fail("\(role) violates water clearance")
                        }
                    }
                }
            }
            if rule.clearanceToPath > 0 {
                for cell in footprint {
                    for p in pathCells {
                        if manhattanDistance(cell, p) < rule.clearanceToPath {
                            fail("\(role) violates path clearance")
                        }
                    }
                }
            }
            if rule.clearanceToBuildings > 0 {
                for cell in footprint {
                    for b in occupiedBuildings {
                        if manhattanDistance(cell, b) < rule.clearanceToBuildings {
                            fail("\(role) violates building clearance")
                        }
                    }
                }
            }

            props.append(.init(kind: kind, coord: anchor))
            let element = PlacedElement(kind: kind, role: role, anchor: anchor, rule: rule, footprint: footprint)
            placedElements.append(element)

            occupiedSolid.formUnion(footprint)
            if isMajorStructure(role) { occupiedBuildings.formUnion(footprint) }
            if role == .wall { occupiedWalls.formUnion(footprint) }
            if role == .cherryTree || role == .forestTree { occupiedTrees.formUnion(footprint) }
        }

        // ============================================================
        // Layer 3: Structures (major buildings only)
        // ============================================================
        let mainHallRule = PlacementRule(
            footprintWidth: 5,
            footprintHeight: 4,
            facing: .south,
            clearanceToWater: 3,
            clearanceToPath: 0,
            clearanceToBuildings: 2,
            allowedZones: [.courtyard],
            forbiddenZones: [.waterside, .forestEdge],
            validationRules: ["face_courtyard", "front_open_depth"]
        )
        place(kind: .mansion, role: .mainHall, anchor: MapCoord(x: 14, y: 20), rule: mainHallRule)

        let eastAuxRule = PlacementRule(
            footprintWidth: 4,
            footprintHeight: 3,
            facing: .west,
            clearanceToWater: 2,
            clearanceToPath: 0,
            clearanceToBuildings: 2,
            allowedZones: [.courtyard],
            forbiddenZones: [.pagodaPrecinct, .waterside, .forestEdge],
            validationRules: ["courtyard_edge_east"]
        )
        place(kind: .japaneseHouse, role: .eastAuxiliary, anchor: MapCoord(x: 17, y: 19), rule: eastAuxRule)

        let westAuxRule = PlacementRule(
            footprintWidth: 2,
            footprintHeight: 2,
            facing: .east,
            clearanceToWater: 2,
            clearanceToPath: 0,
            clearanceToBuildings: 2,
            allowedZones: [.courtyard],
            forbiddenZones: [.pagodaPrecinct, .waterside, .forestEdge],
            validationRules: ["courtyard_edge_west"]
        )
        place(kind: .japaneseSmallHouse, role: .westAuxiliary, anchor: MapCoord(x: 10, y: 22), rule: westAuxRule)

        let pagodaRule = PlacementRule(
            footprintWidth: 2,
            footprintHeight: 3,
            facing: .south,
            clearanceToWater: 2,
            clearanceToPath: 0,
            clearanceToBuildings: 2,
            allowedZones: [.pagodaPrecinct],
            forbiddenZones: [.courtyard, .waterside, .forestEdge],
            validationRules: ["pagoda_context"]
        )
        place(kind: .pagoda, role: .pagoda, anchor: MapCoord(x: 21, y: 9), rule: pagodaRule)

        let toriiRule = PlacementRule(
            footprintWidth: 2,
            footprintHeight: 3,
            facing: .south,
            clearanceToWater: 2,
            clearanceToPath: 0,
            clearanceToBuildings: 1,
            allowedZones: [.pagodaPrecinct],
            forbiddenZones: [.courtyard, .waterside],
            validationRules: ["torii_open_gate_usage", "torii_passage_clear"]
        )
        place(kind: .torii, role: .torii, anchor: MapCoord(x: 19, y: 10), rule: toriiRule)

        let shrineRule = PlacementRule(
            footprintWidth: 3,
            footprintHeight: 3,
            facing: .south,
            clearanceToWater: 2,
            clearanceToPath: 0,
            clearanceToBuildings: 1,
            allowedZones: [.pagodaPrecinct],
            forbiddenZones: [.courtyard, .waterside],
            validationRules: ["pagoda_context"]
        )
        place(kind: .shrineSmall, role: .shrine, anchor: MapCoord(x: 22, y: 11), rule: shrineRule)

        let dockRule = PlacementRule(
            footprintWidth: 2,
            footprintHeight: 2,
            facing: .west,
            clearanceToWater: 0,
            clearanceToPath: 0,
            clearanceToBuildings: 2,
            allowedZones: [.waterside],
            forbiddenZones: [.courtyard, .pagodaPrecinct],
            validationRules: ["touch_water_and_land"]
        )
        place(kind: .dock, role: .dock, anchor: MapCoord(x: 19, y: 14), rule: dockRule)

        // ============================================================
        // Layer 4: Walls / gates / bridges
        // ============================================================
        let wallRule = PlacementRule(
            footprintWidth: 1,
            footprintHeight: 1,
            facing: .south,
            clearanceToWater: 1,
            clearanceToPath: 0,
            clearanceToBuildings: 1,
            allowedZones: [.courtyard],
            forbiddenZones: [.waterside],
            validationRules: ["courtyard_enclosure"]
        )

        for xx in zones.courtyard_zone.minX...zones.courtyard_zone.maxX {
            place(kind: .lowWall, role: .wall, anchor: MapCoord(x: xx, y: zones.courtyard_zone.minY), rule: wallRule)
        }
        for yy in zones.courtyard_zone.minY...zones.courtyard_zone.maxY {
            place(kind: .lowWall, role: .wall, anchor: MapCoord(x: zones.courtyard_zone.minX, y: yy), rule: wallRule)
            place(kind: .lowWall, role: .wall, anchor: MapCoord(x: zones.courtyard_zone.maxX, y: yy), rule: wallRule)
        }
        for xx in zones.courtyard_zone.minX...12 {
            place(kind: .lowWall, role: .wall, anchor: MapCoord(x: xx, y: zones.courtyard_zone.maxY), rule: wallRule)
        }
        for xx in 16...zones.courtyard_zone.maxX {
            place(kind: .lowWall, role: .wall, anchor: MapCoord(x: xx, y: zones.courtyard_zone.maxY), rule: wallRule)
        }

        let gateRule = PlacementRule(
            footprintWidth: 2,
            footprintHeight: 2,
            facing: .north,
            clearanceToWater: 2,
            clearanceToPath: 0,
            clearanceToBuildings: 1,
            allowedZones: [],
            forbiddenZones: [.waterside],
            validationRules: ["gate_front_back_clear"]
        )
        place(kind: .gate, role: .gate, anchor: MapCoord(x: 14, y: 25), rule: gateRule)

        let bridgeNeeded = pathCells.contains(MapCoord(x: 14, y: 14)) &&
            pathCells.contains(MapCoord(x: 14, y: 11)) &&
            creekCells.contains(MapCoord(x: 14, y: 13))

        if bridgeNeeded {
            let bridgeRule = PlacementRule(
                footprintWidth: 3,
                footprintHeight: 2,
                facing: .north,
                clearanceToWater: 0,
                clearanceToPath: 0,
                clearanceToBuildings: 2,
                allowedZones: [.waterside],
                forbiddenZones: [.courtyard, .pagodaPrecinct],
                validationRules: ["bridge_real_crossing"]
            )
            place(kind: .japaneseBridge, role: .bridge, anchor: MapCoord(x: 14, y: 13), rule: bridgeRule)
        }

        // ============================================================
        // Layer 5: Trees
        // ============================================================
        let cherryRuleCourtyard = PlacementRule(
            footprintWidth: 2,
            footprintHeight: 3,
            facing: .south,
            clearanceToWater: 2,
            clearanceToPath: 1,
            clearanceToBuildings: 1,
            allowedZones: [.courtyard, .pagodaPrecinct],
            forbiddenZones: [.waterside, .forestEdge],
            validationRules: ["cherry_zone_only", "not_on_main_axis"]
        )

        let cherryAnchors = [
            MapCoord(x: 10, y: 18),
            MapCoord(x: 18, y: 22),
            MapCoord(x: 20, y: 6),
            MapCoord(x: 22, y: 8)
        ]
        for c in cherryAnchors {
            if southAxis.contains(c) { fail("cherry tree on south entrance axis") }
            if hasNearWater(c, water: creekCells, maxDistance: 1) { fail("cherry tree too close to creek") }
            place(kind: .cherryTree, role: .cherryTree, anchor: c, rule: cherryRuleCourtyard)
        }

        let forestTreeRule = PlacementRule(
            footprintWidth: 3,
            footprintHeight: 4,
            facing: .south,
            clearanceToWater: 1,
            clearanceToPath: 1,
            clearanceToBuildings: 2,
            allowedZones: [.forestEdge],
            forbiddenZones: [.courtyard, .pagodaPrecinct, .waterside],
            validationRules: ["forest_wrap"]
        )

        var toggle = false
        for c in zones.forest_edge_zone.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }) {
            if (c.x + c.y) % 2 != 0 { continue }
            if southAxis.contains(c) { continue }
            if occupiedSolid.contains(c) || pathCells.contains(c) || creekCells.contains(c) { continue }
            toggle.toggle()
            place(kind: toggle ? .roundTree : .tallTree, role: .forestTree, anchor: c, rule: forestTreeRule)
        }

        // ============================================================
        // Layer 6: Props
        // ============================================================
        let reedRule = PlacementRule(
            footprintWidth: 2,
            footprintHeight: 2,
            facing: .south,
            clearanceToWater: 0,
            clearanceToPath: 1,
            clearanceToBuildings: 2,
            allowedZones: [.waterside],
            forbiddenZones: [.courtyard, .pagodaPrecinct],
            validationRules: ["reed_near_water"]
        )
        for c in [MapCoord(x: 18, y: 15), MapCoord(x: 21, y: 15)] {
            if !hasNearWater(c, water: creekCells, maxDistance: 1) {
                fail("reed placed away from water")
            }
            place(kind: .reedCluster, role: .reed, anchor: c, rule: reedRule)
        }

        let lanternRule = PlacementRule(
            footprintWidth: 1,
            footprintHeight: 2,
            facing: .south,
            clearanceToWater: 1,
            clearanceToPath: 0,
            clearanceToBuildings: 1,
            allowedZones: [.pagodaPrecinct],
            forbiddenZones: [.courtyard, .waterside],
            validationRules: ["ritual_path_marker"]
        )
        place(kind: .stoneLanternJp, role: .lantern, anchor: MapCoord(x: 18, y: 10), rule: lanternRule)
        place(kind: .stoneLanternJp, role: .lantern, anchor: MapCoord(x: 20, y: 10), rule: lanternRule)

        let stoneRule = PlacementRule(
            footprintWidth: 1,
            footprintHeight: 1,
            facing: .south,
            clearanceToWater: 1,
            clearanceToPath: 1,
            clearanceToBuildings: 1,
            allowedZones: [.courtyard, .pagodaPrecinct],
            forbiddenZones: [.waterside],
            validationRules: ["edge_detail_only"]
        )
        place(kind: .smallRock, role: .stone, anchor: MapCoord(x: 9, y: 23), rule: stoneRule)
        place(kind: .smallRock, role: .stone, anchor: MapCoord(x: 23, y: 9), rule: stoneRule)

        let flowerRule = PlacementRule(
            footprintWidth: 1,
            footprintHeight: 1,
            facing: .south,
            clearanceToWater: 1,
            clearanceToPath: 1,
            clearanceToBuildings: 1,
            allowedZones: [.courtyard],
            forbiddenZones: [.pagodaPrecinct, .waterside, .forestEdge],
            validationRules: ["not_on_gate_front"]
        )
        place(kind: .pinkFlower, role: .flower, anchor: MapCoord(x: 10, y: 24), rule: flowerRule)
        place(kind: .yellowFlower, role: .flower, anchor: MapCoord(x: 18, y: 24), rule: flowerRule)

        let signpostRule = PlacementRule(
            footprintWidth: 1,
            footprintHeight: 2,
            facing: .north,
            clearanceToWater: 1,
            clearanceToPath: 0,
            clearanceToBuildings: 1,
            allowedZones: [],
            forbiddenZones: [.waterside],
            validationRules: ["wayfinding_clear"]
        )
        place(kind: .signpost, role: .signpost, anchor: MapCoord(x: 13, y: 25), rule: signpostRule)

        // ============================================================
        // Layer 7: Animals
        // ============================================================
        var animals: [AnimalPlacement] = []
        var animalBlocked = occupiedSolid.union(pathCells).union(creekCells)

        for wall in occupiedWalls {
            for d in [(0, 1), (0, -1), (1, 0), (-1, 0)] {
                animalBlocked.insert(MapCoord(x: wall.x + d.0, y: wall.y + d.1))
            }
        }

        let gateFront = MapCoord(x: 14, y: 24)
        let gateBack = MapCoord(x: 14, y: 26)
        animalBlocked.insert(gateFront)
        if onMap(gateBack) { animalBlocked.insert(gateBack) }

        if let toriiElement = placedElements.first(where: { $0.role == .torii }) {
            animalBlocked.formUnion(toriiElement.footprint)
        }

        struct SeededGenerator: RandomNumberGenerator {
            var state: UInt64
            mutating func next() -> UInt64 {
                state = state &* 6364136223846793005 &+ 1442695040888963407
                return state
            }
        }

        var rng = SeededGenerator(state: context.seed ^ 0xA11C_E51A)

        var meadowCandidates: [MapCoord] = []
        var forestInnerCandidates: [MapCoord] = []

        for yy in 1..<(height - 1) {
            for xx in 1..<(width - 1) {
                let c = MapCoord(x: xx, y: yy)
                if animalBlocked.contains(c) { continue }
                if southAxis.contains(c) { continue }
                if terrain.landform(at: c).isWaterLike { continue }

                let z = zones.zoneSet(for: c)
                if z.contains(.forestEdge) {
                    forestInnerCandidates.append(c)
                } else {
                    meadowCandidates.append(c)
                }
            }
        }

        func placeAnimal(_ kind: AnimalKind, from pool: inout [MapCoord]) {
            guard !pool.isEmpty else { return }
            let idx = Int.random(in: 0..<pool.count, using: &rng)
            let c = pool.remove(at: idx)
            if animalBlocked.contains(c) { return }
            animals.append(.init(kind: kind, coord: c))
            animalBlocked.insert(c)
        }

        placeAnimal(.deer, from: &meadowCandidates)
        placeAnimal(.rabbit, from: &meadowCandidates)
        placeAnimal(.rabbit, from: &meadowCandidates)
        placeAnimal(.bird, from: &forestInnerCandidates)
        placeAnimal(.butterfly, from: &meadowCandidates)
        placeAnimal(.frog, from: &forestInnerCandidates)

        // ============================================================
        // Final validation pass (hard reject on any core failure)
        // ============================================================
        func validate() {
            // 1) structure overlap
            var structureOccupancy: [MapCoord: Int] = [:]
            for e in placedElements where isMajorStructure(e.role) {
                for c in e.footprint {
                    structureOccupancy[c, default: 0] += 1
                }
            }
            if structureOccupancy.values.contains(where: { $0 > 1 }) {
                fail("validation failed: structure overlap")
            }

            // 2) bridge without real water crossing
            let bridges = placedElements.filter { $0.role == .bridge }
            for bridge in bridges {
                let waterUnder = bridge.footprint.filter { creekCells.contains($0) }
                if waterUnder.count < 2 { fail("validation failed: bridge without real water coverage") }
                if !creekCells.contains(bridge.anchor) { fail("validation failed: bridge center not on water") }
                let north = MapCoord(x: bridge.anchor.x, y: bridge.anchor.y - 2)
                let south = MapCoord(x: bridge.anchor.x, y: bridge.anchor.y + 1)
                if !pathCells.contains(north) || !pathCells.contains(south) {
                    fail("validation failed: bridge endpoints not connected to path")
                }
            }
            if bridges.isEmpty && bridgeNeeded {
                fail("validation failed: bridge missing despite crossing need")
            }

            // 3) courtyard cut by creek
            if creekCells.contains(where: { zones.courtyard_zone.contains($0) }) {
                fail("validation failed: courtyard cut by creek")
            }

            // 4) wrong torii usage
            let toriis = placedElements.filter { $0.role == .torii }
            if toriis.contains(where: { $0.kind != .torii }) {
                fail("validation failed: wrong torii usage kind")
            }
            if toriis.isEmpty {
                fail("validation failed: missing torii in precinct")
            }

            // 5) cherry trees in invalid zones
            for c in placedElements.filter({ $0.role == .cherryTree }) {
                let inAllowed = c.footprint.allSatisfy { cell in
                    zones.courtyard_zone.contains(cell) || zones.pagoda_precinct_zone.contains(cell)
                }
                if !inAllowed || c.footprint.contains(where: { zones.waterside_zone.contains($0) }) {
                    fail("validation failed: cherry tree outside allowed zones")
                }
            }

            // 6) blocked gate
            guard let gate = placedElements.first(where: { $0.role == .gate }) else {
                fail("validation failed: missing gate")
            }
            let gateFrontCell = MapCoord(x: gate.anchor.x, y: gate.anchor.y - 1)
            let gateBackCell = MapCoord(x: gate.anchor.x, y: gate.anchor.y + 1)
            if !pathCells.contains(gateFrontCell) || !pathCells.contains(gate.anchor) {
                fail("validation failed: gate not aligned with path")
            }
            if occupiedSolid.contains(gateFrontCell) && !gate.footprint.contains(gateFrontCell) {
                fail("validation failed: gate front blocked")
            }
            if onMap(gateBackCell), occupiedSolid.contains(gateBackCell) {
                fail("validation failed: gate back blocked")
            }

            // 7) pagoda without shrine context
            guard let pagoda = placedElements.first(where: { $0.role == .pagoda }) else {
                fail("validation failed: missing pagoda")
            }
            let hasShrine = placedElements.contains { $0.role == .shrine && manhattanDistance($0.anchor, pagoda.anchor) <= 4 }
            let hasTorii = placedElements.contains { $0.role == .torii && manhattanDistance($0.anchor, pagoda.anchor) <= 4 }
            let hasLantern = placedElements.contains { $0.role == .lantern && manhattanDistance($0.anchor, pagoda.anchor) <= 4 }
            if !(hasShrine && hasTorii && hasLantern) {
                fail("validation failed: pagoda lacks shrine context")
            }
        }

        validate()

        let spawn = MapCoord(x: 12, y: 25)

        return TestMap(
            name: "Japanese Garden",
            width: width,
            height: height,
            terrain: terrain,
            props: props,
            animals: animals,
            petSpawn: CreatureSpawn(id: "pico", coord: spawn)
        )
    }
}
