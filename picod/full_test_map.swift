import Foundation

extension TestMapFactory {
    static let fullWorld: TestMap = fullWorld(context: .devPreset(.parkLike))

    static func aprilReferenceWorld(context: WorldGenerationContext) -> TestMap {
        let width = 28
        let height = 28
        var terrain = TerrainLayer(width: width, height: height, fill: .clearing)

        func c(_ x: Int, _ y: Int) -> MapCoord { MapCoord(x: x, y: y) }
        func paint(_ landform: Landform, _ x: Int, _ y: Int) {
            terrain.set(landform, at: c(x, y))
        }
        func fillRect(_ landform: Landform, x xs: ClosedRange<Int>, y ys: ClosedRange<Int>) {
            for yy in ys {
                for xx in xs {
                    paint(landform, xx, yy)
                }
            }
        }
        func paintCells(_ landform: Landform, _ cells: [(Int, Int)]) {
            for (xx, yy) in cells {
                paint(landform, xx, yy)
            }
        }

        for yy in 0..<height {
            for xx in 0..<width {
                if xx <= 1 || xx >= 26 || yy <= 1 || yy >= 26 {
                    paint(.forestEdge, xx, yy)
                } else {
                    let hash = (xx * 37 + yy * 53 + Int(context.seed % 17)) % 19
                    paint(hash == 0 ? .groveFloor : .clearing, xx, yy)
                }
            }
        }

        fillRect(.groveFloor, x: 0...4, y: 2...24)
        fillRect(.groveFloor, x: 24...27, y: 2...25)
        fillRect(.groveFloor, x: 2...27, y: 0...3)
        fillRect(.groveFloor, x: 3...24, y: 24...26)

        fillRect(.dirt, x: 17...24, y: 4...10)
        fillRect(.dirt, x: 8...19, y: 17...24)
        fillRect(.dirt, x: 11...20, y: 14...16)
        fillRect(.stoneGround, x: 10...17, y: 4...8)
        fillRect(.stoneGround, x: 12...17, y: 9...11)

        for xx in 3...23 {
            paint(.shallowWater, xx, 13)
            if xx % 4 != 1 { paint(.shallowWater, xx, 12) }
            if xx % 5 == 0 || xx % 5 == 3 { paint(.shallowWater, xx, 14) }
        }
        paintCells(.wetBank, [
            (2, 12), (2, 13), (2, 14), (24, 12), (24, 13),
            (11, 12), (18, 12), (19, 14), (20, 14), (21, 14)
        ])

        paintCells(.stoneGround, [
            (14, 10), (14, 11), (14, 12), (14, 13), (14, 14), (14, 15),
            (14, 16), (14, 17), (14, 18), (14, 19), (14, 20), (14, 21),
            (14, 22), (14, 23), (14, 24),
            (10, 21), (11, 21), (12, 21), (13, 21), (15, 21), (16, 21), (17, 21),
            (11, 19), (12, 19), (13, 19), (15, 19), (16, 19), (17, 19),
            (18, 9), (19, 9), (20, 9), (21, 9), (18, 10), (19, 10)
        ])

        paintCells(.flowerPatch, [
            (5, 16), (6, 18), (7, 19), (9, 20), (10, 18), (16, 17),
            (17, 18), (18, 18), (19, 17), (21, 11), (22, 7), (20, 5)
        ])

        var props: [PropPlacement] = []
        func prop(_ kind: PropKind, _ x: Int, _ y: Int) {
            props.append(.init(kind: kind, coord: c(x, y)))
        }

        for (index, point) in [
            (2, 2), (4, 1), (6, 1), (8, 1), (10, 1), (12, 1), (16, 1), (18, 1), (20, 1), (23, 2),
            (1, 5), (1, 8), (1, 11), (1, 15), (2, 20), (3, 24),
            (25, 4), (25, 7), (26, 10), (25, 14), (26, 18), (24, 22),
            (4, 25), (6, 25), (3, 22), (5, 26), (22, 25), (24, 25), (21, 24), (23, 24)
        ].enumerated() {
            prop(index.isMultiple(of: 2) ? .roundTree : .tallTree, point.0, point.1)
        }
        for point in [(3, 6), (3, 9), (4, 21), (22, 20), (23, 23), (24, 5)] {
            prop(.bigTree, point.0, point.1)
        }

        for point in [(4, 17), (5, 18), (5, 20), (6, 21), (7, 22), (8, 20), (10, 20), (18, 6), (21, 7)] {
            prop(.cherryTree, point.0, point.1)
        }
        prop(.weepingCherry, 6, 19)

        prop(.japaneseBridge, 14, 13)
        prop(.torii, 19, 10)
        prop(.pagoda, 22, 9)
        prop(.shrineSmall, 22, 11)
        prop(.japaneseHouse, 10, 22)
        prop(.japaneseHouse, 17, 21)
        prop(.japaneseSmallHouse, 12, 19)
        prop(.gate, 14, 24)
        prop(.dock, 20, 14)
        prop(.bench, 21, 15)
        prop(.signpost, 14, 24)

        for point in [(13, 8), (20, 7), (22, 11), (10, 23), (16, 23), (6, 21), (23, 19), (19, 5)] {
            prop(.stoneLanternJp, point.0, point.1)
        }
        for point in [(11, 16), (13, 16), (16, 16), (18, 16), (19, 19), (20, 18), (12, 23), (17, 23)] {
            prop(.flowerBed, point.0, point.1)
        }
        for point in [(12, 10), (16, 11), (21, 6), (23, 8), (8, 23), (11, 18), (20, 21)] {
            prop(.denseBush, point.0, point.1)
        }
        for point in [(9, 8), (13, 5), (17, 8), (18, 12), (9, 14), (6, 24), (21, 23)] {
            prop(.smallRock, point.0, point.1)
        }
        for point in [(11, 5), (21, 5)] {
            prop(.largeRock, point.0, point.1)
        }
        for point in [(19, 14), (21, 14)] {
            prop(.reedCluster, point.0, point.1)
        }
        for point in [(8, 9), (12, 15), (18, 20), (20, 22)] {
            prop(.crate, point.0, point.1)
        }
        for point in [(6, 10), (7, 10), (8, 10), (7, 23), (18, 23)] {
            prop(.fallenLog, point.0, point.1)
        }
        for point in [(6, 7), (9, 12), (15, 6), (23, 13), (5, 23)] {
            prop(.mushroomPatch, point.0, point.1)
        }

        let animals: [AnimalPlacement] = [
            .init(kind: .rabbit, coord: c(6, 11)),
            .init(kind: .rabbit, coord: c(24, 9)),
            .init(kind: .deer, coord: c(23, 20)),
            .init(kind: .bird, coord: c(19, 2)),
            .init(kind: .bird, coord: c(4, 24)),
            .init(kind: .forestSpirit, coord: c(12, 6)),
            .init(kind: .forestSpirit, coord: c(17, 4)),
            .init(kind: .nightLamplighter, coord: c(18, 7)),
            .init(kind: .caretaker, coord: c(23, 6)),
            .init(kind: .frog, coord: c(10, 24))
        ]

        return TestMap(
            name: "April Reference Garden",
            width: width,
            height: height,
            terrain: terrain,
            props: props,
            animals: animals,
            petSpawn: CreatureSpawn(id: "pico", coord: c(10, 24))
        )
    }

    static func fullWorld(context: WorldGenerationContext) -> TestMap {
        let width = 28
        let height = 28
        var terrain = TerrainLayer(width: width, height: height, fill: .grass)

        var generationWarnings: [String] = []

        func fail(_ reason: String) {
            generationWarnings.append(reason)
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
            guard onMap(anchor) else {
                fail("\(role) anchor off map: \(anchor)")
                return
            }

            let footprint = footprintCells(anchor: anchor, width: rule.footprintWidth, height: rule.footprintHeight)
            if footprint.isEmpty {
                fail("\(role) has empty footprint")
                return
            }
            if footprint.contains(where: { !onMap($0) }) {
                fail("\(role) footprint out of map")
                return
            }
            let waterOverlapRoles: Set<ElementRole> = [.bridge, .dock, .reed]
            if !waterOverlapRoles.contains(role), footprint.contains(where: { creekCells.contains($0) }) {
                fail("\(role) footprint overlaps water")
            }
            if footprint.contains(where: { occupiedSolid.contains($0) }) {
                fail("\(role) footprint overlaps existing solids")
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
            if let gate = placedElements.first(where: { $0.role == .gate }) {
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
            } else {
                fail("validation failed: missing gate")
            }

            // 7) pagoda without shrine context
            if let pagoda = placedElements.first(where: { $0.role == .pagoda }) {
                let hasShrine = placedElements.contains { $0.role == .shrine && manhattanDistance($0.anchor, pagoda.anchor) <= 4 }
                let hasTorii = placedElements.contains { $0.role == .torii && manhattanDistance($0.anchor, pagoda.anchor) <= 4 }
                let hasLantern = placedElements.contains { $0.role == .lantern && manhattanDistance($0.anchor, pagoda.anchor) <= 4 }
                if !(hasShrine && hasTorii && hasLantern) {
                    fail("validation failed: pagoda lacks shrine context")
                }
            } else {
                fail("validation failed: missing pagoda")
            }
        }

        validate()

        if !generationWarnings.isEmpty {
            print("Map generation warnings: \(generationWarnings.joined(separator: " | "))")
        }

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

    static func reviewWorld(context: WorldGenerationContext, variant: DevTestMode.MapReviewVariant) -> TestMap {
        switch variant {
        case .forestShrine:
            return forestShrineReviewWorld(context: context)
        case .wetlandLantern:
            return wetlandLanternReviewWorld(context: context)
        case .villageMarket:
            return villageMarketReviewWorld(context: context)
        case .nightGrove:
            return nightGroveReviewWorld(context: context)
        case .aprilDense:
            return aprilDenseReviewWorld(context: context)
        }
    }

    private static func aprilDenseReviewWorld(context: WorldGenerationContext) -> TestMap {
        let base = aprilReferenceWorld(context: context)
        return mapVariant(
            base: base,
            name: "April Dense Garden",
            terrain: { terrain in
                fillRect(.groveFloor, x: 2...6, y: 4...11, in: &terrain)
                fillRect(.groveFloor, x: 21...25, y: 16...24, in: &terrain)
                fillRect(.flowerPatch, x: 4...8, y: 15...19, in: &terrain)
                fillRect(.mossGround, x: 18...22, y: 5...8, in: &terrain)
            },
            props: [
                (.roundTree, 3, 4), (.roundTree, 5, 5), (.tallTree, 2, 8), (.bigTree, 4, 10),
                (.sacredEvergreen, 24, 16), (.tallPine, 25, 19), (.bigTree, 22, 23), (.dwarfPine, 20, 18),
                (.stoneWell, 9, 12), (.lantern, 7, 14), (.lantern, 21, 13), (.kiosk, 18, 19),
                (.flowerBed, 5, 15), (.flowerBed, 7, 18), (.mushroomPatch, 23, 21), (.fallenLog, 3, 13)
            ],
            animals: [
                (.rabbit, 8, 16), (.cat, 19, 20), (.bird, 5, 8), (.bird, 22, 18),
                (.forestSpirit, 20, 7), (.shrineMaiden, 21, 11)
            ],
            spawn: c(12, 23)
        )
    }

    private static func forestShrineReviewWorld(context: WorldGenerationContext) -> TestMap {
        let base = aprilReferenceWorld(context: context)
        return mapVariant(
            base: base,
            name: "Forest Shrine Review",
            terrain: { terrain in
                fillRect(.groveFloor, x: 0...8, y: 0...27, in: &terrain)
                fillRect(.groveFloor, x: 20...27, y: 0...27, in: &terrain)
                fillRect(.mossGround, x: 9...19, y: 3...10, in: &terrain)
                fillRect(.stoneGround, x: 11...17, y: 5...13, in: &terrain)
                fillRect(.wornPath, x: 13...15, y: 9...25, in: &terrain)
                fillRect(.wornPath, x: 6...22, y: 17...18, in: &terrain)
                fillRect(.wornPath, x: 4...9, y: 22...23, in: &terrain)
                fillRect(.wornPath, x: 18...23, y: 21...22, in: &terrain)
                fillRect(.stoneGround, x: 5...9, y: 19...21, in: &terrain)
                fillRect(.stoneGround, x: 18...23, y: 18...20, in: &terrain)
                fillRect(.mossGround, x: 4...8, y: 12...16, in: &terrain)
                fillRect(.mossGround, x: 19...24, y: 12...16, in: &terrain)
                fillRect(.flowerPatch, x: 9...12, y: 15...18, in: &terrain)
                fillRect(.flowerPatch, x: 16...21, y: 15...18, in: &terrain)
                fillRect(.flowerPatch, x: 4...8, y: 23...25, in: &terrain)
                for x in 4...23 {
                    if x % 3 != 1 {
                        terrain.set(.shallowWater, at: c(x, 14))
                    }
                }
                for (xx, yy) in [(4, 13), (5, 13), (22, 13), (23, 13), (5, 15), (22, 15), (3, 18), (24, 18)] {
                    terrain.set(.wetBank, at: c(xx, yy))
                }
            },
            props: [
                (.sacredEvergreen, 2, 3), (.tallPine, 4, 4), (.bigTree, 6, 7), (.roundTree, 3, 11),
                (.tallTree, 5, 16), (.bigTree, 3, 23), (.sacredEvergreen, 22, 3), (.tallPine, 24, 6),
                (.bigTree, 22, 10), (.roundTree, 25, 15), (.tallTree, 23, 21), (.bigTree, 25, 24),
                (.roundTree, 1, 8), (.tallTree, 7, 3), (.bigTree, 1, 18), (.roundTree, 6, 25),
                (.sacredEvergreen, 21, 25), (.tallPine, 26, 11), (.roundTree, 20, 2), (.bigTree, 26, 19),
                (.roundTree, 2, 6), (.gardenPine, 8, 4), (.tallTree, 10, 2), (.sacredEvergreen, 16, 2),
                (.bigTree, 2, 13), (.sacredEvergreen, 4, 14), (.tallPine, 7, 15), (.roundTree, 2, 21),
                (.gardenPine, 5, 24), (.dwarfPine, 8, 25), (.roundTree, 21, 4), (.bigTree, 24, 9),
                (.sacredEvergreen, 26, 14), (.gardenPine, 22, 16), (.tallTree, 24, 18), (.roundTree, 21, 23),
                (.tallPine, 24, 25), (.gardenPine, 18, 25),
                (.denseBush, 4, 6), (.denseBush, 23, 5), (.mushroomPatch, 3, 15), (.fallenLog, 22, 24),
                (.denseBush, 6, 14), (.denseBush, 24, 13), (.mushroomPatch, 21, 24),
                (.torii, 14, 9), (.shrineSmall, 14, 7), (.pagoda, 18, 7), (.stoneWell, 10, 10),
                (.stoneLanternJp, 11, 8), (.stoneLanternJp, 17, 8), (.stoneLanternJp, 12, 13), (.stoneLanternJp, 17, 13),
                (.japaneseBridge, 14, 14), (.mushroomPatch, 8, 19), (.mushroomPatch, 21, 18), (.flowerBed, 10, 16),
                (.flowerBed, 18, 17), (.signpost, 13, 23), (.fallenLog, 6, 20),
                (.japaneseSmallHouse, 6, 20), (.tinyShed, 21, 19), (.kiosk, 12, 20), (.bench, 8, 18),
                (.bench, 20, 17), (.crate, 10, 19), (.crate, 18, 20), (.lowWall, 7, 22), (.lowWall, 8, 22),
                (.lantern, 6, 18), (.lantern, 22, 18), (.stoneLanternJp, 9, 21), (.stoneLanternJp, 19, 21),
                (.reedCluster, 5, 14), (.reedCluster, 22, 14), (.flowerBed, 5, 24), (.flowerBed, 17, 16),
                (.mushroomPatch, 4, 17), (.mushroomPatch, 23, 16), (.largeRock, 7, 12), (.smallRock, 20, 13)
            ],
            animals: [
                (.shrineMaiden, 16, 10), (.nightLamplighter, 12, 12), (.rabbit, 7, 17),
                (.deer, 21, 21), (.bird, 6, 8), (.bird, 22, 15), (.forestSpirit, 18, 5),
                (.toriiBetweenLight, 14, 8), (.cat, 9, 20), (.dog, 19, 19), (.lostBackpacker, 6, 21),
                (.butterfly, 18, 16), (.snail, 8, 24), (.edgeTraveler, 22, 22)
            ],
            spawn: c(12, 24)
        )
    }

    private static func wetlandLanternReviewWorld(context: WorldGenerationContext) -> TestMap {
        let base = aprilReferenceWorld(context: context)
        return mapVariant(
            base: base,
            name: "Wetland Lantern Review",
            includeBaseProps: false,
            includeBaseAnimals: false,
            terrain: { terrain in
                fillRect(.clearing, x: 0...27, y: 0...27, in: &terrain)
                fillRect(.forestEdge, x: 0...27, y: 0...2, in: &terrain)
                fillRect(.forestEdge, x: 0...27, y: 25...27, in: &terrain)
                fillRect(.forestEdge, x: 0...2, y: 0...27, in: &terrain)
                fillRect(.forestEdge, x: 25...27, y: 0...27, in: &terrain)
                fillRect(.groveFloor, x: 3...9, y: 3...10, in: &terrain)
                fillRect(.groveFloor, x: 20...24, y: 16...24, in: &terrain)
                fillRect(.mossGround, x: 3...12, y: 18...24, in: &terrain)
                fillRect(.shallowWater, x: 3...21, y: 8...14, in: &terrain)
                fillRect(.deepWater, x: 15...24, y: 5...11, in: &terrain)
                fillRect(.wetBank, x: 2...22, y: 7...8, in: &terrain)
                fillRect(.wetBank, x: 2...22, y: 14...15, in: &terrain)
                fillRect(.reedsEdge, x: 17...24, y: 5...13, in: &terrain)
                fillRect(.wornPath, x: 5...8, y: 18...24, in: &terrain)
                fillRect(.wornPath, x: 7...19, y: 18...20, in: &terrain)
                fillRect(.wornPath, x: 19...21, y: 13...21, in: &terrain)
                fillRect(.wornPath, x: 9...13, y: 15...16, in: &terrain)
                fillRect(.wornPath, x: 14...18, y: 12...13, in: &terrain)
                fillRect(.stoneGround, x: 6...10, y: 16...17, in: &terrain)
                fillRect(.stoneGround, x: 20...23, y: 14...16, in: &terrain)
                fillRect(.mossGround, x: 9...14, y: 4...7, in: &terrain)
                fillRect(.flowerPatch, x: 12...15, y: 21...24, in: &terrain)
                fillRect(.flowerPatch, x: 4...9, y: 20...23, in: &terrain)
                for (xx, yy) in [(10, 10), (11, 10), (12, 11), (13, 11), (14, 12), (15, 12), (8, 13), (9, 13)] {
                    terrain.set(.deepWater, at: c(xx, yy))
                }
                for (xx, yy) in [
                    (18, 8), (19, 8), (20, 9), (22, 10), (23, 10),
                    (22, 12), (23, 12), (18, 14), (19, 14), (20, 14),
                    (10, 14), (11, 14), (21, 14), (22, 14)
                ] {
                    terrain.set(.shallowWater, at: c(xx, yy))
                }
            },
            props: [
                (.roundTree, 3, 4), (.tallTree, 5, 5), (.bigTree, 8, 7), (.sacredEvergreen, 22, 17),
                (.tallPine, 24, 19), (.bigTree, 22, 23), (.roundTree, 4, 24), (.gardenPine, 2, 18),
                (.roundTree, 11, 3), (.tallTree, 14, 4), (.bigTree, 24, 4), (.roundTree, 25, 13),
                (.tallPine, 3, 11), (.bigTree, 10, 24), (.roundTree, 15, 24), (.sacredEvergreen, 20, 24),
                (.bridgeShort, 8, 14), (.japaneseBridge, 19, 14), (.dock, 22, 12), (.dock, 18, 8),
                (.stoneWell, 21, 7), (.reedCluster, 17, 8), (.reedCluster, 20, 9), (.reedCluster, 23, 10),
                (.reedCluster, 4, 14), (.reedCluster, 11, 15), (.reedCluster, 6, 8), (.reedCluster, 14, 11),
                (.lantern, 6, 18), (.lantern, 12, 18),
                (.lantern, 20, 15), (.stoneLanternJp, 22, 8), (.weepingCherry, 5, 21), (.cherryTree, 8, 22),
                (.denseBush, 6, 17), (.flowerBed, 7, 21), (.flowerBed, 10, 20), (.mushroomPatch, 4, 23),
                (.flowerBed, 13, 22), (.flowerBed, 15, 23), (.denseBush, 12, 5), (.denseBush, 24, 15),
                (.fallenLog, 5, 16), (.fallenLog, 11, 6), (.signpost, 7, 24), (.smallRock, 14, 13),
                (.smallRock, 9, 7), (.largeRock, 15, 7), (.largeRock, 23, 6), (.bench, 11, 19),
                (.bridgeShort, 10, 15), (.bridgeShort, 15, 12), (.dock, 12, 10), (.dock, 21, 15),
                (.tinyShed, 7, 17), (.japaneseSmallHouse, 22, 15), (.crate, 9, 18), (.crate, 13, 17),
                (.lantern, 9, 16), (.lantern, 16, 13), (.flowerBed, 7, 16), (.flowerBed, 20, 16),
                (.reedCluster, 9, 11), (.reedCluster, 13, 12), (.reedCluster, 16, 11), (.mushroomPatch, 20, 20)
            ],
            animals: [
                (.duck, 20, 9), (.duck, 23, 8), (.frog, 6, 14), (.frog, 17, 14),
                (.fishShadow, 13, 11), (.fishShadow, 21, 7), (.fisher, 22, 13),
                (.bird, 5, 19), (.snail, 8, 23), (.umbrellaWoman, 19, 18),
                (.rabbit, 23, 20), (.bird, 12, 4), (.cat, 12, 23), (.forestSpirit, 14, 6),
                (.frog, 12, 15), (.duck, 10, 10), (.fishShadow, 16, 12), (.child, 8, 17)
            ],
            spawn: c(6, 23)
        )
    }

    private static func villageMarketReviewWorld(context: WorldGenerationContext) -> TestMap {
        let base = aprilReferenceWorld(context: context)
        return mapVariant(
            base: base,
            name: "Village Market Review",
            includeBaseProps: false,
            includeBaseAnimals: false,
            terrain: { terrain in
                fillRect(.clearing, x: 0...27, y: 0...27, in: &terrain)
                fillRect(.forestEdge, x: 0...27, y: 0...2, in: &terrain)
                fillRect(.forestEdge, x: 0...27, y: 25...27, in: &terrain)
                fillRect(.forestEdge, x: 0...2, y: 0...27, in: &terrain)
                fillRect(.forestEdge, x: 25...27, y: 0...27, in: &terrain)
                fillRect(.stoneGround, x: 5...22, y: 7...18, in: &terrain)
                fillRect(.dirt, x: 3...24, y: 18...21, in: &terrain)
                fillRect(.dirt, x: 5...8, y: 5...23, in: &terrain)
                fillRect(.wornPath, x: 8...20, y: 11...13, in: &terrain)
                fillRect(.wornPath, x: 16...18, y: 10...24, in: &terrain)
                fillRect(.wornPath, x: 8...10, y: 6...20, in: &terrain)
                fillRect(.wornPath, x: 4...22, y: 20...22, in: &terrain)
                fillRect(.stoneGround, x: 11...15, y: 15...18, in: &terrain)
                fillRect(.stoneGround, x: 19...23, y: 10...14, in: &terrain)
                fillRect(.flowerPatch, x: 3...9, y: 20...24, in: &terrain)
                fillRect(.groveFloor, x: 21...25, y: 4...24, in: &terrain)
                fillRect(.mossGround, x: 3...6, y: 4...10, in: &terrain)
                fillRect(.stoneGround, x: 10...14, y: 5...8, in: &terrain)
            },
            props: [
                (.japaneseHouse, 6, 8), (.japaneseHouse, 18, 8), (.japaneseSmallHouse, 7, 21),
                (.japaneseSmallHouse, 17, 22), (.tinyShed, 22, 17), (.kiosk, 12, 13),
                (.kiosk, 15, 13), (.kiosk, 19, 14), (.mailbox, 9, 16), (.crate, 10, 12),
                (.crate, 13, 12), (.crate, 19, 12), (.crate, 21, 15), (.bench, 8, 15),
                (.bench, 20, 17), (.signpost, 17, 20), (.lantern, 10, 10), (.lantern, 18, 10),
                (.stoneLanternJp, 22, 8), (.roundTree, 3, 5), (.cherryTree, 4, 21),
                (.weepingCherry, 6, 23), (.roundTree, 24, 6), (.tallTree, 24, 12),
                (.bigTree, 23, 22), (.tallPine, 25, 18), (.denseBush, 21, 9),
                (.roundTree, 4, 11), (.tallTree, 3, 17), (.bigTree, 9, 4), (.cherryTree, 12, 5),
                (.roundTree, 14, 4), (.tallTree, 25, 9), (.bigTree, 24, 16), (.gardenPine, 21, 23),
                (.kiosk, 11, 16), (.kiosk, 14, 16), (.crate, 9, 18), (.crate, 12, 19),
                (.crate, 20, 20), (.lowWall, 10, 7), (.lowWall, 13, 7), (.billboard, 21, 13),
                (.lantern, 6, 12), (.lantern, 18, 18), (.stoneLanternJp, 6, 18),
                (.flowerBed, 5, 23), (.flowerBed, 8, 21), (.flowerBed, 20, 19),
                (.flowerBed, 16, 6), (.flowerBed, 23, 14), (.mushroomPatch, 22, 21),
                (.smallRock, 11, 18), (.smallRock, 14, 10), (.largeRock, 23, 10), (.fallenLog, 4, 15),
                (.japaneseHouse, 9, 7), (.japaneseSmallHouse, 22, 12), (.tinyShed, 12, 17),
                (.kiosk, 8, 18), (.kiosk, 13, 18), (.kiosk, 18, 19), (.crate, 7, 20),
                (.crate, 10, 20), (.crate, 15, 21), (.mailbox, 21, 11), (.billboard, 22, 18),
                (.lantern, 9, 10), (.lantern, 17, 13), (.lantern, 22, 20),
                (.bench, 11, 15), (.bench, 19, 15), (.flowerBed, 12, 16), (.flowerBed, 14, 17)
            ],
            animals: [
                (.cat, 12, 18), (.dog, 17, 18), (.child, 15, 15), (.caretaker, 20, 12),
                (.bird, 5, 7), (.rabbit, 23, 20), (.lostBackpacker, 8, 13),
                (.doorKnocker, 18, 8), (.truckDriver, 21, 20), (.bird, 13, 5),
                (.cat, 7, 16), (.dog, 20, 17), (.edgeTraveler, 6, 19),
                (.child, 10, 20), (.caretaker, 18, 21), (.bird, 22, 9), (.rabbit, 4, 23)
            ],
            spawn: c(8, 22)
        )
    }

    private static func nightGroveReviewWorld(context: WorldGenerationContext) -> TestMap {
        let base = aprilReferenceWorld(context: context)
        return mapVariant(
            base: base,
            name: "Night Grove Review",
            includeBaseProps: false,
            includeBaseAnimals: false,
            terrain: { terrain in
                fillRect(.groveFloor, x: 0...27, y: 0...27, in: &terrain)
                fillRect(.forestEdge, x: 0...27, y: 0...2, in: &terrain)
                fillRect(.forestEdge, x: 0...27, y: 25...27, in: &terrain)
                fillRect(.forestEdge, x: 0...2, y: 0...27, in: &terrain)
                fillRect(.forestEdge, x: 25...27, y: 0...27, in: &terrain)
                fillRect(.mossGround, x: 4...23, y: 4...24, in: &terrain)
                fillRect(.stoneGround, x: 14...22, y: 6...13, in: &terrain)
                fillRect(.shallowWater, x: 3...8, y: 13...17, in: &terrain)
                fillRect(.flowerPatch, x: 15...22, y: 17...23, in: &terrain)
                fillRect(.groveFloor, x: 3...12, y: 18...24, in: &terrain)
                fillRect(.mossGround, x: 5...10, y: 6...12, in: &terrain)
                fillRect(.stoneGround, x: 4...8, y: 20...22, in: &terrain)
                fillRect(.mossGround, x: 19...24, y: 15...23, in: &terrain)
                fillRect(.flowerPatch, x: 4...7, y: 6...9, in: &terrain)
                for (xx, yy) in [
                    (6, 23), (7, 23), (8, 23), (9, 22), (10, 21), (11, 20),
                    (12, 20), (13, 19), (14, 18), (15, 18), (16, 17), (17, 16),
                    (18, 15), (18, 14), (18, 13), (17, 12), (16, 11), (15, 10),
                    (15, 9), (16, 8), (17, 8), (18, 8), (19, 8)
                ] {
                    terrain.set(.wornPath, at: c(xx, yy))
                    terrain.set(.wornPath, at: c(xx, min(yy + 1, 24)))
                }
            },
            props: [
                (.bigTree, 2, 4), (.tallTree, 5, 5), (.bigTree, 7, 9), (.sacredEvergreen, 4, 22),
                (.tallPine, 20, 4), (.bigTree, 23, 7), (.roundTree, 24, 14), (.bigTree, 22, 23),
                (.tallTree, 10, 6), (.roundTree, 12, 24), (.sacredEvergreen, 25, 19),
                (.roundTree, 3, 12), (.tallPine, 6, 16), (.bigTree, 8, 20), (.roundTree, 11, 3),
                (.tallTree, 14, 4), (.bigTree, 24, 10), (.roundTree, 25, 16), (.gardenPine, 19, 23),
                (.lantern, 9, 22), (.lantern, 12, 20), (.lantern, 16, 17), (.lantern, 18, 13),
                (.lantern, 16, 9), (.stoneLanternJp, 8, 16), (.stoneLanternJp, 19, 8),
                (.lantern, 6, 23), (.lantern, 10, 18), (.stoneLanternJp, 14, 11),
                (.torii, 17, 10), (.pagoda, 21, 9), (.stoneWell, 7, 15), (.mushroomPatch, 6, 21),
                (.mushroomPatch, 18, 21), (.fallenLog, 4, 18), (.denseBush, 20, 17),
                (.denseBush, 9, 8), (.denseBush, 23, 18), (.flowerBed, 18, 19),
                (.flowerBed, 21, 21), (.flowerBed, 16, 22), (.signpost, 7, 24),
                (.smallRock, 12, 16), (.smallRock, 7, 10), (.largeRock, 11, 10),
                (.largeRock, 22, 5), (.fallenLog, 5, 12),
                (.japaneseSmallHouse, 6, 21), (.tinyShed, 21, 18), (.kiosk, 12, 19),
                (.lantern, 7, 21), (.lantern, 20, 18), (.lantern, 23, 15), (.lantern, 5, 9),
                (.stoneLanternJp, 6, 7), (.stoneLanternJp, 22, 20), (.flowerBed, 5, 7),
                (.flowerBed, 20, 20), (.mushroomPatch, 7, 22), (.mushroomPatch, 23, 17),
                (.denseBush, 4, 8), (.denseBush, 24, 22), (.roundTree, 4, 4), (.tallTree, 23, 3)
            ],
            animals: [
                (.nightLamplighter, 18, 18), (.forestSpirit, 11, 10), (.forestSpirit, 21, 15),
                (.edgeTraveler, 8, 20), (.bird, 6, 8), (.deer, 22, 21), (.cat, 17, 20),
                (.mirrorMiko, 16, 11), (.toriiBetweenLight, 17, 9), (.rabbit, 6, 17),
                (.bird, 12, 4), (.snail, 9, 23), (.forestSpirit, 23, 18),
                (.forestSpirit, 6, 8), (.nightLamplighter, 8, 21), (.cat, 5, 22), (.rabbit, 22, 19)
            ],
            spawn: c(8, 23)
        )
    }

    private static func mapVariant(
        base: TestMap,
        name: String,
        includeBaseProps: Bool = true,
        includeBaseAnimals: Bool = true,
        terrain mutateTerrain: (inout TerrainLayer) -> Void,
        props extraProps: [(PropKind, Int, Int)],
        animals extraAnimals: [(AnimalKind, Int, Int)],
        spawn: MapCoord
    ) -> TestMap {
        var terrain = base.terrain
        mutateTerrain(&terrain)
        let props = (includeBaseProps ? base.props : []) + extraProps.map { PropPlacement(kind: $0.0, coord: c($0.1, $0.2)) }
        let animals = (includeBaseAnimals ? base.animals : []) + extraAnimals.map { AnimalPlacement(kind: $0.0, coord: c($0.1, $0.2)) }
        return TestMap(
            name: name,
            width: base.width,
            height: base.height,
            terrain: terrain,
            props: props,
            animals: animals,
            petSpawn: CreatureSpawn(id: "pico", coord: spawn)
        )
    }

    private static func fillRect(_ land: Landform, x xs: ClosedRange<Int>, y ys: ClosedRange<Int>, in terrain: inout TerrainLayer) {
        for yy in ys {
            for xx in xs {
                terrain.set(land, at: c(xx, yy))
            }
        }
    }

    private static func c(_ x: Int, _ y: Int) -> MapCoord {
        MapCoord(x: x, y: y)
    }
}
