//
//  MapView.swift
//  picod
//

import SwiftUI

struct MapView: View {
    let tileSize: CGFloat
    let testMap: TestMap?
    let showPetSpawn: Bool
    let petCoord: MapCoord?
    let petFormId: Int
    let petAccentHex: String?
    let runtimeProps: [PropPlacement]
    let runtimeAnimals: [AnimalPlacement]
    let ambientCurve: MapAmbientMoodCurve
    let weatherCondition: WeatherCondition
    let humidityPercent: Int
    let animateAmbient: Bool

    init(
        tileSize: CGFloat = 10,
        testMap: TestMap? = nil,
        showPetSpawn: Bool = false,
        petCoord: MapCoord? = nil,
        petFormId: Int = 0,
        petAccentHex: String? = nil,
        runtimeProps: [PropPlacement] = [],
        runtimeAnimals: [AnimalPlacement] = [],
        ambientCurve: MapAmbientMoodCurve = .neutral,
        weatherCondition: WeatherCondition = .sunny,
        humidityPercent: Int = 59,
        animateAmbient: Bool = true
    ) {
        self.tileSize = tileSize
        self.testMap = testMap
        self.showPetSpawn = showPetSpawn
        self.petCoord = petCoord
        self.petFormId = petFormId
        self.petAccentHex = petAccentHex
        self.runtimeProps = runtimeProps
        self.runtimeAnimals = runtimeAnimals
        self.ambientCurve = ambientCurve
        self.weatherCondition = weatherCondition
        self.humidityPercent = humidityPercent
        self.animateAmbient = animateAmbient
    }

    var body: some View {
        if animateAmbient {
            TimelineView(.animation) { timeline in
                canvas(time: timeline.date.timeIntervalSinceReferenceDate)
            }
        } else {
            canvas(time: 0)
        }
    }

    private func canvas(time: TimeInterval) -> some View {
        Canvas { ctx, size in
            if let map = testMap {
                drawWorld(ctx: &ctx, size: size, map: map, petCoord: petCoord, time: time)
            } else {
                drawFallbackGrid(ctx: &ctx, size: size, time: time)
            }
        }
    }

    private func drawFallbackGrid(ctx: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let t = tileSize
        let cols = Int(ceil(size.width / t))
        let rows = Int(ceil(size.height / t))
        let pulse = animateAmbient ? CGFloat((sin(time * 0.9) + 1) * 0.015) : 0
        for y in 0..<rows {
            for x in 0..<cols {
                let color = ((x + y).isMultiple(of: 2) ? Color.picod_tile_a : Color.picod_tile_b).opacity(0.98 + pulse)
                let rect = CGRect(x: CGFloat(x) * t, y: CGFloat(y) * t, width: t, height: t)
                ctx.fill(Path(rect), with: .color(color))
            }
        }
    }

    // MARK: - World Drawing

    private func drawWorld(ctx: inout GraphicsContext, size: CGSize, map: TestMap, petCoord: MapCoord?, time: TimeInterval) {
        let tile = min(size.width / CGFloat(map.width), size.height / CGFloat(map.height))
        let mapW = CGFloat(map.width) * tile
        let mapH = CGFloat(map.height) * tile
        let origin = CGPoint(x: (size.width - mapW) / 2, y: (size.height - mapH) / 2)

        for y in 0..<map.height {
            for x in 0..<map.width {
                let coord = MapCoord(x: x, y: y)
                let land = map.terrain.landform(at: coord)
                let rect = CGRect(x: origin.x + CGFloat(x) * tile, y: origin.y + CGFloat(y) * tile, width: tile, height: tile)
                drawTerrainTile(ctx: &ctx, rect: rect, coord: coord, landform: land, time: time)
            }
        }

        drawTerrainEdges(ctx: &ctx, map: map, origin: origin, tile: tile)

        let gridColor = Color.picod_ink.opacity(0.015)
        for x in 0...map.width {
            let xPos = origin.x + CGFloat(x) * tile
            var line = Path(); line.move(to: CGPoint(x: xPos, y: origin.y)); line.addLine(to: CGPoint(x: xPos, y: origin.y + mapH))
            ctx.stroke(line, with: .color(gridColor), lineWidth: 0.5)
        }
        for y in 0...map.height {
            let yPos = origin.y + CGFloat(y) * tile
            var line = Path(); line.move(to: CGPoint(x: origin.x, y: yPos)); line.addLine(to: CGPoint(x: origin.x + mapW, y: yPos))
            ctx.stroke(line, with: .color(gridColor), lineWidth: 0.5)
        }

        let props = runtimeProps.isEmpty ? map.props : runtimeProps
        let animals = runtimeAnimals.isEmpty ? map.animals : runtimeAnimals
        var layers: [RenderableObject] = []
        layers.reserveCapacity(props.count + animals.count + 6)
        for p in props { layers.append(.prop(p)) }
        for a in animals { layers.append(.animal(a)) }
        layers.append(contentsOf: ambientVisitorLayers(for: map, time: time))
        if let active = petCoord {
            layers.append(.pet(active))
        } else if showPetSpawn {
            layers.append(.pet(map.petSpawn.coord))
        }
        layers.sort { lhs, rhs in
            if lhs.sortY != rhs.sortY { return lhs.sortY < rhs.sortY }
            return lhs.sortX < rhs.sortX
        }
        for item in layers {
            switch item {
            case .prop(let p): drawProp(p.kind, coord: p.coord, origin: origin, tile: tile, time: time, ctx: &ctx)
            case .animal(let a): drawAnimal(a.kind, coord: a.coord, origin: origin, tile: tile, time: time, ctx: &ctx)
            case .pet(let c): drawPet(coord: c, origin: origin, tile: tile, time: time, ctx: &ctx)
            }
        }

        drawClimateOverlay(ctx: &ctx, rect: CGRect(x: origin.x, y: origin.y, width: mapW, height: mapH), tile: tile, time: time)
        drawAmbientOverlay(ctx: &ctx, rect: CGRect(x: origin.x, y: origin.y, width: mapW, height: mapH))
        drawAmbientSignalBubbles(ctx: &ctx, map: map, origin: origin, tile: tile, time: time)
    }

    private func drawAmbientOverlay(ctx: inout GraphicsContext, rect: CGRect) {
        let progress = max(0, min(1, ambientCurve.progress))
        guard progress > 0.2 else { return }

        let nightOpacity = min(0.52, max(0, (progress - 0.2) * 1.0))
        ctx.fill(Path(rect), with: .color(Color(hex: "1A1814").opacity(nightOpacity)))
    }

    // MARK: - Terrain

    private func drawTerrainTile(ctx: inout GraphicsContext, rect: CGRect, coord: MapCoord, landform: Landform, time: TimeInterval) {
        let p = pal; let v = noise(coord.x, coord.y, 7) % 2; let v2 = noise(coord.x, coord.y, 17) % 2
        let px = rect.width / 8.0
        let wave = animateAmbient ? Int(floor(time * 2.0 + Double(noise(coord.x, coord.y, 23) % 3))) % 3 : 0
        func fill(_ c: Color) { ctx.fill(Path(rect), with: .color(c)) }
        func dot(_ r: Int, _ c: Int, _ color: Color) {
            let rr = CGRect(x: rect.minX + CGFloat(c) * px, y: rect.minY + CGFloat(r) * px, width: px + 0.5, height: px + 0.5)
            ctx.fill(Path(rr), with: .color(color))
        }
        func hLine(_ r: Int, _ x0: Int, _ x1: Int, _ color: Color) { for c in x0...x1 { dot(r, c, color) } }

        switch landform {
        case .grass:
            fill(p.grass)
            dot(v==0 ? 2:5, v2==0 ? 2:5, p.grassDark); dot(v==0 ? 6:1, v2==0 ? 6:3, p.grassDark)
            if v2==0 { dot(4, 4, p.grassLight) }
        case .tallGrass, .forestEdge:
            fill(p.grassDark)
            dot(2, v==0 ? 1:3, p.grass); dot(2, v==0 ? 2:4, p.grass)
            dot(4, v2==0 ? 5:2, p.grass); dot(4, v2==0 ? 6:3, p.grass); dot(6, 4, p.grassLight)
        case .dirt:
            fill(p.dirt)
            dot(v==0 ? 2:5, v2==0 ? 1:4, p.dirtDark); dot(v==0 ? 4:1, v2==0 ? 5:2, p.dirtDark)
        case .wornPath:
            fill(p.pathBase)
            hLine(0, 0, 7, p.pathEdge); hLine(7, 0, 7, p.pathEdge)
            dot(1, 0, p.pathEdge); dot(1, 7, p.pathEdge); dot(6, 0, p.pathEdge); dot(6, 7, p.pathEdge)
            if v==0 { dot(3, 3, p.dirt); dot(4, 5, p.dirt) }
        case .sand:
            fill(p.sand)
            dot(v==0 ? 1:4, v2==0 ? 2:5, p.sandDark); dot(v==0 ? 5:2, v2==0 ? 6:1, p.sandDark)
        case .stone, .stoneGround:
            fill(p.stone)
            hLine(3, 0, 7, p.stoneDark)
            dot(0, v==0 ? 4:2, p.stoneDark); dot(1, v==0 ? 4:2, p.stoneDark); dot(2, v==0 ? 4:2, p.stoneDark)
            dot(4, v2==0 ? 6:1, p.stoneDark); dot(5, v2==0 ? 6:1, p.stoneDark); dot(1, v==0 ? 6:5, p.stoneLight)
        case .mud:
            fill(p.mud); dot(2, v==0 ? 2:5, p.mudDark); dot(4, v2==0 ? 4:1, p.mudDark); dot(5, v==0 ? 6:3, p.mudDark)
        case .mossGround:
            fill(p.moss); dot(1, v==0 ? 2:5, p.mossDark); dot(3, v2==0 ? 4:1, p.mossDark); dot(5, v==0 ? 6:3, p.mossDark); dot(4, 2, p.grass)
        case .water, .pond, .shallowWater:
            fill(p.shallowWater)
            hLine(v==0 ? 2:5, max(0, (v2==0 ? 1:3) + wave - 1), min(7, (v2==0 ? 3:5) + wave - 1), p.waterHighlight)
            hLine(v==0 ? 5:2, max(0, (v2==0 ? 5:1) - wave + 1), min(7, (v2==0 ? 6:2) - wave + 1), p.waterHighlight)
        case .deepWater:
            fill(p.deepWater)
            hLine(v==0 ? 2:5, max(0, (v2==0 ? 2:4) + wave - 1), min(7, (v2==0 ? 4:6) + wave - 1), p.waterHighlight)
            dot(v==0 ? 6:1, v2==0 ? 5:2, p.shallowWater)
        case .reedsEdge:
            fill(p.wetBank); dot(1, v==0 ? 2:5, p.reed); dot(0, v==0 ? 2:5, p.reed)
            dot(2, v==0 ? 5:2, p.reed); dot(1, v==0 ? 5:2, p.reed); dot(4, 4, p.mud)
        case .wetBank:
            fill(p.wetBank); dot(v==0 ? 2:5, v2==0 ? 3:5, p.mud); dot(v==0 ? 4:1, v2==0 ? 6:1, p.mud)
        case .smallHill:
            fill(p.hill); hLine(2, 1, 6, p.hillLight); dot(3, v==0 ? 2:5, p.hillLight)
        case .cliffEdge:
            fill(p.cliff); hLine(1, 0, 7, p.cliffLight); hLine(6, 0, 7, p.cliffDark); hLine(7, 0, 7, p.cliffDark)
        case .clearing:
            fill(p.clearing)
            if v==0 { dot(3, 4, p.grassDark.opacity(0.5)) }; if v2==0 { dot(6, 2, p.grassDark.opacity(0.5)) }
        case .groveFloor:
            fill(p.groveFloor); dot(v==0 ? 1:4, v2==0 ? 2:5, p.groveFloorDark)
            dot(v==0 ? 3:6, v2==0 ? 5:1, p.groveFloorDark); dot(5, 3, p.moss)
        case .flowerPatch:
            fill(p.clearing); dot(2, v==0 ? 2:5, p.flowerAccent); dot(3, v==0 ? 5:2, p.flowerYellow)
            dot(5, v2==0 ? 3:6, p.flowerAccent); dot(1, 4, p.flowerLight)
        }
    }

    // MARK: - Terrain Edges

    private func drawTerrainEdges(ctx: inout GraphicsContext, map: TestMap, origin: CGPoint, tile: CGFloat) {
        let px = tile / 8.0
        for y in 0..<map.height {
            for x in 0..<map.width {
                let here = map.terrain.landform(at: MapCoord(x: x, y: y))
                let tileX = origin.x + CGFloat(x) * tile; let tileY = origin.y + CGFloat(y) * tile
                let hW = here.isWaterLike
                if y > 0 { let a = map.terrain.landform(at: MapCoord(x: x, y: y-1)); if hW != a.isWaterLike {
                    let bl = hW ? terrainBaseColor(a) : terrainBaseColor(here)
                    for c in 0..<8 where (c+x)%2==0 { ctx.fill(Path(CGRect(x: tileX+CGFloat(c)*px, y: tileY, width: px+0.5, height: px+0.5)), with: .color(bl.opacity(0.5))) }
                }}
                if y < map.height-1 { let b = map.terrain.landform(at: MapCoord(x: x, y: y+1)); if hW != b.isWaterLike {
                    let bl = hW ? terrainBaseColor(b) : terrainBaseColor(here)
                    for c in 0..<8 where (c+x+1)%2==0 { ctx.fill(Path(CGRect(x: tileX+CGFloat(c)*px, y: tileY+7*px, width: px+0.5, height: px+0.5)), with: .color(bl.opacity(0.5))) }
                }}
                if x > 0 { let l = map.terrain.landform(at: MapCoord(x: x-1, y: y)); if hW != l.isWaterLike {
                    let bl = hW ? terrainBaseColor(l) : terrainBaseColor(here)
                    for r in 0..<8 where (r+y)%2==0 { ctx.fill(Path(CGRect(x: tileX, y: tileY+CGFloat(r)*px, width: px+0.5, height: px+0.5)), with: .color(bl.opacity(0.5))) }
                }}
                if x < map.width-1 { let r = map.terrain.landform(at: MapCoord(x: x+1, y: y)); if hW != r.isWaterLike {
                    let bl = hW ? terrainBaseColor(r) : terrainBaseColor(here)
                    for row in 0..<8 where (row+y+1)%2==0 { ctx.fill(Path(CGRect(x: tileX+7*px, y: tileY+CGFloat(row)*px, width: px+0.5, height: px+0.5)), with: .color(bl.opacity(0.5))) }
                }}
            }
        }
    }

    private func terrainBaseColor(_ l: Landform) -> Color {
        let p = pal
        switch l {
        case .grass: return p.grass; case .tallGrass, .forestEdge: return p.grassDark; case .dirt: return p.dirt
        case .wornPath: return p.pathBase; case .sand: return p.sand; case .stone, .stoneGround: return p.stone
        case .mud: return p.mud; case .mossGround: return p.moss; case .water, .pond, .shallowWater: return p.shallowWater
        case .deepWater: return p.deepWater; case .reedsEdge: return p.wetBank; case .wetBank: return p.wetBank
        case .smallHill: return p.hill; case .cliffEdge: return p.cliff; case .clearing: return p.clearing
        case .groveFloor: return p.groveFloor; case .flowerPatch: return p.clearing
        }
    }

    // MARK: - Sprite Drawing

    private func drawSprite(spec: SpriteSpec, coord: MapCoord, origin: CGPoint, tile: CGFloat, motion: SpriteMotion = .still, ctx: inout GraphicsContext) {
        let ground = CGPoint(
            x: origin.x + (CGFloat(coord.x) + 0.5) * tile + motion.offset.width,
            y: origin.y + CGFloat(coord.y + 1) * tile + motion.offset.height
        )
        let sW = spec.tileFootprint.width * tile * motion.scale.width
        let sH = spec.tileFootprint.height * tile * motion.scale.height
        let sO = CGPoint(x: ground.x - sW * spec.anchor.x, y: ground.y - sH * spec.anchor.y)
        if motion.glowOpacity > 0 {
            let glowW = tile * spec.tileFootprint.width * 1.1
            let glowH = tile * spec.tileFootprint.height * 0.9
            ctx.fill(
                Path(ellipseIn: CGRect(x: ground.x - glowW / 2, y: ground.y - glowH, width: glowW, height: glowH)),
                with: .color(motion.glowColor.opacity(motion.glowOpacity))
            )
        }
        if spec.hasShadow {
            let sw = tile * spec.tileFootprint.width * 0.5; let sh = tile * 0.3
            ctx.fill(Path(ellipseIn: CGRect(x: ground.x - sw/2, y: ground.y - sh/2, width: sw, height: sh)), with: .color(Color(hex: "2F2A24").opacity(spec.shadowOpacity)))
        }
        let art = spec.pixels
        let rows = art.count
        let cols = art.map(\.count).max() ?? 0
        guard rows > 0, cols > 0 else { return }
        let pxW: CGFloat
        let pxH: CGFloat
        let drawOrigin: CGPoint
        if spec.preservesPixelAspect {
            let px = min(sW / CGFloat(cols), sH / CGFloat(rows)) * spec.pixelScale
            pxW = px
            pxH = px
            drawOrigin = CGPoint(
                x: sO.x + (sW - CGFloat(cols) * px) / 2,
                y: sO.y + sH - CGFloat(rows) * px
            )
        } else {
            pxW = sW / CGFloat(cols)
            pxH = sH / CGFloat(rows)
            drawOrigin = sO
        }
        for row in 0..<rows {
            let pixels = art[row]
            for col in 0..<pixels.count {
                let idx = Int(pixels[col])
                guard idx > 0, idx <= spec.palette.count else { continue }
                ctx.fill(Path(CGRect(x: drawOrigin.x + CGFloat(col)*pxW, y: drawOrigin.y + CGFloat(row)*pxH, width: pxW+0.5, height: pxH+0.5)), with: .color(spec.palette[idx-1]))
            }
        }
    }

    private func drawProp(_ k: PropKind, coord: MapCoord, origin: CGPoint, tile: CGFloat, time: TimeInterval, ctx: inout GraphicsContext) {
        drawSprite(spec: propSpec(for: k), coord: coord, origin: origin, tile: tile, motion: propMotion(for: k, coord: coord, tile: tile, time: time), ctx: &ctx)
    }
    private func drawAnimal(_ k: AnimalKind, coord: MapCoord, origin: CGPoint, tile: CGFloat, time: TimeInterval, ctx: inout GraphicsContext) {
        drawSprite(spec: animalSpec(for: k), coord: coord, origin: origin, tile: tile, motion: animalMotion(for: k, coord: coord, tile: tile, time: time), ctx: &ctx)
    }
    private func drawPet(coord: MapCoord, origin: CGPoint, tile: CGFloat, time: TimeInterval, ctx: inout GraphicsContext) {
        drawSprite(spec: petSpec, coord: coord, origin: origin, tile: tile, motion: petMotion(coord: coord, tile: tile, time: time), ctx: &ctx)
    }

    private func propMotion(for kind: PropKind, coord: MapCoord, tile: CGFloat, time: TimeInterval) -> SpriteMotion {
        guard animateAmbient else { return .still }
        let phase = Double(noise(coord.x, coord.y, kind.rawValue.count)) * 0.01
        let wind = climateWindStrength
        switch kind {
        case .tree, .roundTree, .tallTree, .bigTree, .cherryTree, .weepingCherry,
                .cherryClump, .sacredEvergreen, .gardenPine, .tallPine, .dwarfPine:
            let sway = CGFloat(sin(time * 0.75 + phase)) * tile * (0.02 + wind * 0.055)
            return SpriteMotion(offset: CGSize(width: sway, height: 0))
        case .reed, .reedCluster, .flower, .pinkFlower, .yellowFlower, .flowerBed,
                .smallBush, .denseBush, .bushDense:
            let sway = CGFloat(sin(time * 1.25 + phase)) * tile * (0.03 + wind * 0.075)
            return SpriteMotion(offset: CGSize(width: sway, height: 0))
        case .lantern:
            let glow = 0.10 + CGFloat((sin(time * 1.8 + phase) + 1) * 0.08)
            return SpriteMotion(glowOpacity: glow, glowColor: Color(hex: "E8C848"))
        case .stoneLanternJp:
            let glow = 0.04 + CGFloat((sin(time * 1.25 + phase) + 1) * 0.04)
            return SpriteMotion(glowOpacity: glow, glowColor: Color(hex: "E8C848"))
        case .car, .orangeTruck:
            let roll = CGFloat(sin(time * 0.28 + phase)) * tile * 0.22
            return SpriteMotion(offset: CGSize(width: roll, height: 0))
        case .windmill:
            let bob = CGFloat(sin(time * 0.5 + phase)) * tile * 0.02
            return SpriteMotion(offset: CGSize(width: 0, height: bob))
        default:
            return .still
        }
    }

    private func animalMotion(for kind: AnimalKind, coord: MapCoord, tile: CGFloat, time: TimeInterval) -> SpriteMotion {
        guard animateAmbient else { return .still }
        let phase = Double(noise(coord.x, coord.y, kind.rawValue.count + 41)) * 0.01
        switch kind {
        case .bird, .butterfly, .forestSpirit, .toriiBetweenLight, .nightLamplighter:
            let dx = CGFloat(sin(time * 1.0 + phase)) * tile * 0.12
            let dy = CGFloat(cos(time * 1.4 + phase)) * tile * 0.10
            let glow: CGFloat = kind == .bird ? 0 : 0.08 + CGFloat((sin(time * 1.6 + phase) + 1) * 0.08)
            return SpriteMotion(offset: CGSize(width: dx, height: dy), glowOpacity: glow, glowColor: Color(hex: "F0E8C0"))
        case .duck, .fishShadow:
            let dx = CGFloat(sin(time * 0.65 + phase)) * tile * 0.16
            let dy = CGFloat(cos(time * 0.8 + phase)) * tile * 0.04
            return SpriteMotion(offset: CGSize(width: dx, height: dy))
        case .frog, .rabbit, .cat, .dog, .deer, .snail, .cow, .sheep, .horse:
            let dx = CGFloat(sin(time * 0.5 + phase)) * tile * 0.07
            let dy = CGFloat(cos(time * 0.9 + phase)) * tile * 0.035
            return SpriteMotion(offset: CGSize(width: dx, height: dy))
        case .child, .shrineMaiden, .caretaker, .fisher, .edgeTraveler, .truckDriver,
                .lostBackpacker, .umbrellaWoman, .doorKnocker, .mirrorMiko:
            let bob = CGFloat(sin(time * 0.85 + phase)) * tile * 0.035
            return SpriteMotion(offset: CGSize(width: 0, height: bob))
        }
    }

    private func petMotion(coord: MapCoord, tile: CGFloat, time: TimeInterval) -> SpriteMotion {
        guard animateAmbient else { return .still }
        let phase = Double(noise(coord.x, coord.y, petFormId + 73)) * 0.01
        let bob = CGFloat(sin(time * 1.0 + phase)) * tile * 0.05
        return SpriteMotion(offset: CGSize(width: 0, height: bob))
    }

    private var climateWindStrength: CGFloat {
        switch weatherCondition {
        case .stormy:
            return 1.0
        case .rainy:
            return 0.72
        case .foggy, .cloudy:
            return 0.48
        case .partlyCloudy, .snowy:
            return 0.36
        case .sunny:
            return 0.24
        case .night:
            return 0.18
        }
    }

    private func ambientVisitorLayers(for map: TestMap, time: TimeInterval) -> [RenderableObject] {
        guard animateAmbient else { return [] }
        let cycle = Int(time / 7.0) % 4
        var visitors: [RenderableObject] = []

        if map.name.contains("Village") {
            visitors.append(.prop(PropPlacement(kind: .orangeTruck, coord: MapCoord(x: 23, y: 20))))
            visitors.append(.animal(AnimalPlacement(kind: .truckDriver, coord: MapCoord(x: 21, y: 20))))
        }

        if map.name.contains("Wetland") || weatherCondition == .rainy || weatherCondition == .stormy {
            visitors.append(.animal(AnimalPlacement(kind: cycle.isMultiple(of: 2) ? .duck : .frog, coord: MapCoord(x: 20, y: 10))))
            visitors.append(.animal(AnimalPlacement(kind: .fishShadow, coord: MapCoord(x: 14, y: 12))))
        }

        if map.name.contains("Night") || weatherCondition == .foggy || weatherCondition == .night {
            visitors.append(.animal(AnimalPlacement(kind: .forestSpirit, coord: MapCoord(x: 8 + cycle, y: 16))))
            visitors.append(.animal(AnimalPlacement(kind: .toriiBetweenLight, coord: MapCoord(x: 18, y: 9))))
        }

        if weatherCondition == .sunny || weatherCondition == .partlyCloudy {
            visitors.append(.animal(AnimalPlacement(kind: cycle.isMultiple(of: 2) ? .butterfly : .bird, coord: MapCoord(x: 6 + cycle, y: 9))))
        }

        return visitors
    }

    private func drawClimateOverlay(ctx: inout GraphicsContext, rect: CGRect, tile: CGFloat, time: TimeInterval) {
        guard animateAmbient else { return }

        switch weatherCondition {
        case .sunny:
            drawSunBands(ctx: &ctx, rect: rect, time: time, opacity: 0.08)
        case .partlyCloudy:
            drawSunBands(ctx: &ctx, rect: rect, time: time, opacity: 0.04)
            drawCloudShadows(ctx: &ctx, rect: rect, tile: tile, time: time, opacity: 0.05)
        case .cloudy:
            drawCloudShadows(ctx: &ctx, rect: rect, tile: tile, time: time, opacity: 0.08)
        case .foggy:
            drawMistBands(ctx: &ctx, rect: rect, tile: tile, time: time, opacity: 0.16)
        case .rainy:
            drawCloudShadows(ctx: &ctx, rect: rect, tile: tile, time: time, opacity: 0.07)
            drawRain(ctx: &ctx, rect: rect, tile: tile, time: time, opacity: 0.16, density: 34)
        case .stormy:
            drawCloudShadows(ctx: &ctx, rect: rect, tile: tile, time: time, opacity: 0.10)
            drawRain(ctx: &ctx, rect: rect, tile: tile, time: time, opacity: 0.24, density: 46)
        case .snowy:
            drawMistBands(ctx: &ctx, rect: rect, tile: tile, time: time, opacity: 0.09)
        case .night:
            drawMistBands(ctx: &ctx, rect: rect, tile: tile, time: time, opacity: 0.05)
        }

        drawWaterGlints(ctx: &ctx, rect: rect, tile: tile, time: time)
        drawTimeParticles(ctx: &ctx, rect: rect, tile: tile, time: time)
    }

    private func drawSunBands(ctx: inout GraphicsContext, rect: CGRect, time: TimeInterval, opacity: CGFloat) {
        let drift = CGFloat(sin(time * 0.12)) * rect.width * 0.08
        for index in 0..<3 {
            let startX = rect.minX + rect.width * (0.18 + CGFloat(index) * 0.24) + drift
            var path = Path()
            path.move(to: CGPoint(x: startX, y: rect.minY))
            path.addLine(to: CGPoint(x: startX + rect.width * 0.20, y: rect.minY))
            path.addLine(to: CGPoint(x: startX - rect.width * 0.08, y: rect.maxY))
            path.addLine(to: CGPoint(x: startX - rect.width * 0.28, y: rect.maxY))
            path.closeSubpath()
            ctx.fill(path, with: .color(Color(hex: "F6E7A8").opacity(opacity)))
        }
    }

    private func drawCloudShadows(ctx: inout GraphicsContext, rect: CGRect, tile: CGFloat, time: TimeInterval, opacity: CGFloat) {
        for index in 0..<4 {
            let width = rect.width * (0.32 + CGFloat(index % 2) * 0.16)
            let cycle = CGFloat((time * (0.018 + Double(index) * 0.004) + Double(index) * 0.31).truncatingRemainder(dividingBy: 1))
            let x = rect.minX - width + (rect.width + width * 2) * cycle
            let y = rect.minY + rect.height * (0.16 + CGFloat(index) * 0.18)
            let cloudRect = CGRect(x: x, y: y, width: width, height: tile * 2.3)
            ctx.fill(Path(cloudRect), with: .color(Color(hex: "1A1814").opacity(opacity)))
        }
    }

    private func drawMistBands(ctx: inout GraphicsContext, rect: CGRect, tile: CGFloat, time: TimeInterval, opacity: CGFloat) {
        let humidityBoost = CGFloat(max(0, humidityPercent - 60)) / 100.0
        for index in 0..<5 {
            let width = rect.width * (0.42 + CGFloat(index % 3) * 0.12)
            let cycle = CGFloat((time * (0.012 + Double(index) * 0.002) + Double(index) * 0.19).truncatingRemainder(dividingBy: 1))
            let x = rect.minX - width + (rect.width + width * 2) * cycle
            let y = rect.minY + rect.height * (0.10 + CGFloat(index) * 0.17)
            let mistRect = CGRect(x: x, y: y, width: width, height: tile * 1.25)
            ctx.fill(Path(mistRect), with: .color(Color.picod_paper.opacity(opacity + humidityBoost * 0.05)))
        }
    }

    private func drawRain(ctx: inout GraphicsContext, rect: CGRect, tile: CGFloat, time: TimeInterval, opacity: CGFloat, density: Int) {
        for index in 0..<density {
            let seedX = CGFloat((index * 37) % 100) / 100.0
            let seedY = CGFloat((index * 53) % 100) / 100.0
            let fall = CGFloat((Double(seedY) + time * 0.22).truncatingRemainder(dividingBy: 1))
            let x = rect.minX + seedX * rect.width + CGFloat(sin(time * 0.7 + Double(index))) * tile * 0.5
            let y = rect.minY + fall * rect.height
            var line = Path()
            line.move(to: CGPoint(x: x, y: y))
            line.addLine(to: CGPoint(x: x - tile * 0.35, y: y + tile * 0.75))
            ctx.stroke(line, with: .color(Color(hex: "DCE7E8").opacity(opacity)), lineWidth: max(1, tile * 0.08))
        }
    }

    private func drawWaterGlints(ctx: inout GraphicsContext, rect: CGRect, tile: CGFloat, time: TimeInterval) {
        guard weatherCondition != .stormy else { return }
        let progress = max(0, min(1, ambientCurve.progress))
        let opacity: CGFloat = weatherCondition == .sunny || weatherCondition == .partlyCloudy ? 0.15 : 0.08
        for index in 0..<8 {
            let phase = time * (0.32 + Double(index) * 0.03) + Double(index) * 0.71
            let pulse = CGFloat((sin(phase) + 1) / 2)
            let x = rect.minX + rect.width * CGFloat((Double((index * 17) % 100) / 100.0))
            let y = rect.minY + rect.height * CGFloat(0.30 + Double((index * 11) % 24) / 100.0)
            let width = tile * (0.5 + pulse * 0.9)
            let lineRect = CGRect(x: x, y: y, width: width, height: max(1, tile * 0.10))
            let nightFade = CGFloat(1 - min(0.55, progress))
            ctx.fill(Path(lineRect), with: .color(Color(hex: "E8F2E0").opacity(opacity * pulse * nightFade)))
        }
    }

    private func drawTimeParticles(ctx: inout GraphicsContext, rect: CGRect, tile: CGFloat, time: TimeInterval) {
        let progress = max(0, min(1, ambientCurve.progress))
        if progress >= 0.55 || weatherCondition == .night || weatherCondition == .foggy {
            drawFireflies(ctx: &ctx, rect: rect, tile: tile, time: time, density: progress >= 0.65 ? 12 : 7)
        } else if weatherCondition == .sunny || weatherCondition == .partlyCloudy {
            drawFloatingPollen(ctx: &ctx, rect: rect, tile: tile, time: time, density: 10)
        }

        if climateWindStrength > 0.42 {
            drawWindLeaves(ctx: &ctx, rect: rect, tile: tile, time: time, density: weatherCondition == .stormy ? 16 : 9)
        }
    }

    private func drawFireflies(ctx: inout GraphicsContext, rect: CGRect, tile: CGFloat, time: TimeInterval, density: Int) {
        for index in 0..<density {
            let xSeed = CGFloat((index * 29 + 7) % 100) / 100.0
            let ySeed = CGFloat((index * 43 + 11) % 100) / 100.0
            let driftX = CGFloat(sin(time * 0.36 + Double(index))) * tile * 0.7
            let driftY = CGFloat(cos(time * 0.29 + Double(index) * 0.7)) * tile * 0.45
            let glow = CGFloat((sin(time * 1.8 + Double(index) * 1.3) + 1) / 2)
            let glowRect = CGRect(
                x: rect.minX + xSeed * rect.width + driftX,
                y: rect.minY + ySeed * rect.height * 0.78 + driftY,
                width: max(1, tile * 0.18),
                height: max(1, tile * 0.18)
            )
            ctx.fill(Path(ellipseIn: glowRect), with: .color(Color(hex: "E8D878").opacity(0.18 + glow * 0.34)))
        }
    }

    private func drawFloatingPollen(ctx: inout GraphicsContext, rect: CGRect, tile: CGFloat, time: TimeInterval, density: Int) {
        for index in 0..<density {
            let cycle = CGFloat((time * (0.018 + Double(index) * 0.001) + Double(index) * 0.17).truncatingRemainder(dividingBy: 1))
            let x = rect.minX + cycle * rect.width
            let y = rect.minY + rect.height * CGFloat(0.12 + Double((index * 13) % 70) / 100.0)
            let dot = CGRect(x: x, y: y, width: max(1, tile * 0.12), height: max(1, tile * 0.12))
            ctx.fill(Path(ellipseIn: dot), with: .color(Color(hex: "E9D98F").opacity(0.16)))
        }
    }

    private func drawWindLeaves(ctx: inout GraphicsContext, rect: CGRect, tile: CGFloat, time: TimeInterval, density: Int) {
        for index in 0..<density {
            let cycle = CGFloat((time * (0.045 + Double(index) * 0.002) + Double(index) * 0.11).truncatingRemainder(dividingBy: 1))
            let x = rect.minX - tile + cycle * (rect.width + tile * 2)
            let y = rect.minY + rect.height * CGFloat(0.10 + Double((index * 19) % 76) / 100.0)
            let leaf = CGRect(x: x, y: y + CGFloat(sin(time + Double(index))) * tile * 0.5, width: tile * 0.28, height: tile * 0.16)
            ctx.fill(Path(ellipseIn: leaf), with: .color(Color(hex: "9FB879").opacity(0.22)))
        }
    }

    private func drawAmbientSignalBubbles(ctx: inout GraphicsContext, map: TestMap, origin: CGPoint, tile: CGFloat, time: TimeInterval) {
        guard animateAmbient else { return }
        let cycle = Int(time / 6.0) % 4
        if map.name.contains("Village") {
            drawSignalBubble("...", coord: MapCoord(x: 21, y: 19), origin: origin, tile: tile, ctx: &ctx)
        } else if map.name.contains("Night") || weatherCondition == .foggy {
            drawSignalBubble("?", coord: MapCoord(x: 18, y: 8), origin: origin, tile: tile, ctx: &ctx)
        } else if map.name.contains("Wetland") || weatherCondition == .rainy {
            drawSignalBubble(cycle.isMultiple(of: 2) ? "..." : "!", coord: MapCoord(x: 20, y: 9), origin: origin, tile: tile, ctx: &ctx)
        } else if cycle.isMultiple(of: 2) {
            drawSignalBubble("!", coord: MapCoord(x: 6, y: 8), origin: origin, tile: tile, ctx: &ctx)
        }
    }

    private func drawSignalBubble(_ text: String, coord: MapCoord, origin: CGPoint, tile: CGFloat, ctx: inout GraphicsContext) {
        let anchor = CGPoint(x: origin.x + (CGFloat(coord.x) + 0.5) * tile, y: origin.y + CGFloat(coord.y) * tile)
        let width = max(tile * 1.7, CGFloat(text.count) * tile * 0.68 + tile * 0.9)
        let height = tile * 1.05
        let rect = CGRect(x: anchor.x - width / 2, y: anchor.y - height - tile * 0.35, width: width, height: height)
        let bubble = Path(rect)
        ctx.fill(bubble, with: .color(Color.picod_paper.opacity(0.92)))
        ctx.stroke(bubble, with: .color(Color.picod_ink.opacity(0.72)), lineWidth: max(1, tile * 0.08))
        ctx.draw(
            Text(text)
                .font(.system(size: max(8, tile * 0.72), weight: .bold, design: .monospaced))
                .foregroundColor(.picod_ink),
            at: CGPoint(x: rect.midX, y: rect.midY)
        )
    }

    // MARK: - Pet Spec
    private var petSpec: SpriteSpec {
        let formId = max(0, petFormId)
        let sourceRows = PicoPortraitView.normalizedRows(for: formId)
        let rows = croppedPetRows(sourceRows, padding: 1)
        let sourceBounds = petVisibleBounds(for: sourceRows)
        let referenceBounds = petVisibleBounds(for: PicoPortraitView.normalizedRows(for: 0))
        let sourceVisibleWidth = CGFloat(max(1, sourceBounds.maxX - sourceBounds.minX + 1))
        let sourceVisibleHeight = CGFloat(max(1, sourceBounds.maxY - sourceBounds.minY + 1))
        let referenceVisibleWidth = CGFloat(max(1, referenceBounds.maxX - referenceBounds.minX + 1))
        let referenceVisibleHeight = CGFloat(max(1, referenceBounds.maxY - referenceBounds.minY + 1))
        let referenceScale = min(1, referenceVisibleWidth / sourceVisibleWidth, referenceVisibleHeight / sourceVisibleHeight)
        var palette: [Color] = []
        var tokenIndex: [Character: UInt8] = [:]

        let pixels: [[UInt8]] = rows.map { row in
            row.map { token in
                guard token != "." && token != "0" else { return 0 }
                if let index = tokenIndex[token] {
                    return index
                }
                let index = UInt8(min(255, palette.count + 1))
                palette.append(PicoPortraitView.resolvedColor(for: token, formId: formId, accentHex: petAccentHex))
                tokenIndex[token] = index
                return index
            }
        }

        let referenceFootprint = petReferenceFootprint
        return SpriteSpec(
            tileFootprint: referenceFootprint,
            palette: palette,
            pixels: pixels,
            shadowOpacity: 0.26,
            preservesPixelAspect: true,
            pixelScale: referenceScale
        )
    }

    private var petReferenceFootprint: CGSize {
        let rows = croppedPetRows(PicoPortraitView.normalizedRows(for: 0), padding: 1)
        let rowCount = CGFloat(max(1, rows.count))
        let colCount = CGFloat(max(1, rows.map(\.count).max() ?? 1))
        let footprintHeight: CGFloat = 2.0
        let footprintWidth = min(2.95, max(1.35, footprintHeight * colCount / rowCount))
        return CGSize(width: footprintWidth, height: footprintHeight)
    }

    private func petVisibleBounds(for rows: [String]) -> (minX: Int, maxX: Int, minY: Int, maxY: Int) {
        let matrix = rows.map { Array($0) }
        let width = matrix.first?.count ?? 1
        var minX = width
        var maxX = -1
        var minY = matrix.count
        var maxY = -1

        for (y, row) in matrix.enumerated() {
            for (x, token) in row.enumerated() where token != "." && token != "0" {
                minX = min(minX, x)
                maxX = max(maxX, x)
                minY = min(minY, y)
                maxY = max(maxY, y)
            }
        }

        guard maxX >= minX, maxY >= minY else {
            return (0, max(0, width - 1), 0, max(0, matrix.count - 1))
        }

        return (minX, maxX, minY, maxY)
    }

    private func croppedPetRows(_ rows: [String], padding: Int) -> [String] {
        let matrix = rows.map { Array($0) }
        guard let width = matrix.first?.count, width > 0, !matrix.isEmpty else {
            return rows
        }

        var minX = width
        var maxX = -1
        var minY = matrix.count
        var maxY = -1

        for (y, row) in matrix.enumerated() {
            for (x, token) in row.enumerated() where token != "." && token != "0" {
                minX = min(minX, x)
                maxX = max(maxX, x)
                minY = min(minY, y)
                maxY = max(maxY, y)
            }
        }

        guard maxX >= minX, maxY >= minY else {
            return rows
        }

        let left = max(0, minX - padding)
        let right = min(width - 1, maxX + padding)
        let top = max(0, minY - padding)
        let bottom = min(matrix.count - 1, maxY + padding)

        return (top...bottom).map { y in
            String(matrix[y][left...right])
        }
    }

    // MARK: - Prop Specs
    private func propSpec(for k: PropKind) -> SpriteSpec {
        switch k {
        case .house, .mansion, .japaneseHouse: return SpriteSpec(tileFootprint: CGSize(width: 4, height: 5), palette: [
            Color(hex: "8090A0"),Color(hex: "606878"),Color(hex: "A8B8C8"),Color(hex: "E8D8C0"),Color(hex: "C8B8A0"),
            Color(hex: "506878"),Color(hex: "886848"),Color(hex: "685038"),Color(hex: "A07060"),Color(hex: "808078"),
            Color(hex: "3A3228"),Color(hex: "B0A898")], pixels: PA.house)
        case .cherryTree, .weepingCherry, .cherryClump: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 4), palette: [
            Color(hex: "D98BA8"),Color(hex: "F0A9C0"),Color(hex: "C76D8E"),Color(hex: "F4C1CF"),Color(hex: "6B4730"),Color(hex: "4E3324")], pixels: PA.cherryTree)
        case .tree, .roundTree, .sacredEvergreen, .gardenPine, .dwarfPine: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 4), palette: [
            Color(hex: "6CA050"),Color(hex: "4A7838"),Color(hex: "3A6030"),Color(hex: "88C068"),Color(hex: "806040"),Color(hex: "5A4030")], pixels: PA.roundTree)
        case .tallTree, .tallPine: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 4), palette: [
            Color(hex: "4A7838"),Color(hex: "3A6030"),Color(hex: "6CA050"),Color(hex: "88C068"),Color(hex: "806040"),Color(hex: "5A4030")], pixels: PA.tallTree)
        case .bigTree: return SpriteSpec(tileFootprint: CGSize(width: 4, height: 5), palette: [
            Color(hex: "5A8848"),Color(hex: "3E6830"),Color(hex: "7AB060"),Color(hex: "98D078"),Color(hex: "705838"),Color(hex: "503820")], pixels: PA.bigTree)
        case .bush, .smallBush: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 1), palette: [
            Color(hex: "3E5638"),Color(hex: "5A7848"),Color(hex: "88C068")], pixels: PA.smallBush)
        case .denseBush, .bushDense: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 2), palette: [
            Color(hex: "3E5638"),Color(hex: "4F6A47"),Color(hex: "6CA050"),Color(hex: "88C068")], pixels: PA.denseBush)
        case .flower, .pinkFlower: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "D87090"),Color(hex: "E8A0B0"),Color(hex: "C85070"),Color(hex: "4A7838")], pixels: PA.flower, hasShadow: false)
        case .yellowFlower: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "D8B040"),Color(hex: "E8D070"),Color(hex: "C89830"),Color(hex: "4A7838")], pixels: PA.flower, hasShadow: false)
        case .flowerBed: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 1), palette: [
            Color(hex: "D87090"),Color(hex: "E8D070"),Color(hex: "C85070"),Color(hex: "4A7838"),Color(hex: "D8B040")], pixels: PA.flowerBed, hasShadow: false)
        case .mushroomPatch: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "C88060"),Color(hex: "E8C8A0"),Color(hex: "D8D0C0")], pixels: PA.mushroom, hasShadow: false)
        case .reed, .reedCluster: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "5B744A"),Color(hex: "7A9860")], pixels: PA.reedCluster, hasShadow: false)
        case .stump: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "A08060")], pixels: PA.stump)
        case .log, .fallenLog: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 1), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "A08060")], pixels: PA.fallenLog)
        case .rock, .smallRock: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "706860"),Color(hex: "908880"),Color(hex: "B0A8A0")], pixels: PA.smallRock)
        case .largeRock: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 2), palette: [
            Color(hex: "706860"),Color(hex: "908880"),Color(hex: "B0A8A0"),Color(hex: "585050")], pixels: PA.largeRock)
        case .sign, .signpost: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 2), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "A08060"),Color(hex: "E8D8C0")], pixels: PA.signpost)
        case .bench: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 1), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "A08060")], pixels: PA.bench)
        case .fence, .fenceShort, .lowWall: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "806040"),Color(hex: "6C513A")], pixels: PA.fence)
        case .crate: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "A08060")], pixels: PA.crate)
        case .stoneLanternJp: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 2), palette: [
            Color(hex: "6B6A62"),Color(hex: "8A887E"),Color(hex: "AAA69A")], pixels: PA.stoneLantern)
        case .lantern: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 2), palette: [
            Color(hex: "585050"),Color(hex: "E8C848"),Color(hex: "706860")], pixels: PA.lantern)
        case .mailbox: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 2), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "B85040"),Color(hex: "903828")], pixels: PA.mailbox)
        case .stoneWell: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "908880"),Color(hex: "706860"),Color(hex: "B0A8A0"),Color(hex: "628BA2"),Color(hex: "806040")], pixels: PA.well)
        case .japaneseBridge: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 2), palette: [
            Color(hex: "C94332"),Color(hex: "E25A45"),Color(hex: "6E4A36"),Color(hex: "C9B9A0")], pixels: PA.japaneseBridge)
        case .bridgeShort, .dock: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 1), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "A08060")], pixels: PA.bridge)
        case .torii: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 3), palette: [
            Color(hex: "D83325"),Color(hex: "EF513B"),Color(hex: "7A3129"),Color(hex: "2A2825")], pixels: PA.torii, hasShadow: false)
        case .gate: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "6C513A"),Color(hex: "806040"),Color(hex: "585050")], pixels: PA.gate)
        case .pagoda: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 3), palette: [
            Color(hex: "2F4A64"),Color(hex: "405D78"),Color(hex: "6E4A30"),Color(hex: "A47648"),Color(hex: "1E2630")], pixels: PA.pagoda)
        case .shrineSmall: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 3), palette: [
            Color(hex: "6E4A30"),Color(hex: "9B6A3B"),Color(hex: "EFE2C5"),Color(hex: "2F4A64"),Color(hex: "1E2630")], pixels: PA.shrineJp)
        case .tinyShed, .japaneseSmallHouse: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 3), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "908880"),Color(hex: "706860"),Color(hex: "E8D8C0")], pixels: PA.shed)
        case .kiosk: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "E8D8C0"),Color(hex: "B85040")], pixels: PA.kiosk)
        case .car, .orangeTruck: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 2), palette: [
            Color(hex: "7888A0"),Color(hex: "586878"),Color(hex: "A8B8C8"),Color(hex: "D0D8E0"),Color(hex: "2A2825"),Color(hex: "B85040")], pixels: PA.car)
        case .billboard: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 3), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "E8E0D0"),Color(hex: "B85040"),Color(hex: "5888A8")], pixels: PA.billboard)
        case .windmill: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 5), palette: [
            Color(hex: "E8D8C0"),Color(hex: "C8B8A0"),Color(hex: "908880"),Color(hex: "706860"),Color(hex: "B85040"),Color(hex: "D8C8B0")], pixels: PA.windmill)
        }
    }

    // MARK: - Animal Specs
    private func animalSpec(for k: AnimalKind) -> SpriteSpec {
        switch k {
        case .bird: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "3D556B"),Color(hex: "5A7890"),Color(hex: "D8A030"),Color(hex: "2A2825")], pixels: PA.bird)
        case .duck: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "6C804F"),Color(hex: "8CA068"),Color(hex: "D88030"),Color(hex: "8FB6C8")], pixels: PA.duck)
        case .rabbit: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "C0B8A8"),Color(hex: "8D867A"),Color(hex: "2A2825"),Color(hex: "E0D8D0")], pixels: PA.rabbit)
        case .cat: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "6C6058"),Color(hex: "908478"),Color(hex: "2A2825"),Color(hex: "E0C0B0")], pixels: PA.cat)
        case .dog: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "7A624A"),Color(hex: "A08060"),Color(hex: "2A2825"),Color(hex: "E0C8B0")], pixels: PA.dog)
        case .deer: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 3), palette: [
            Color(hex: "5A4030"),Color(hex: "8A6A4E"),Color(hex: "B08860"),Color(hex: "2A2825"),Color(hex: "D0B890")], pixels: PA.deer)
        case .frog: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "5B744A"),Color(hex: "7A9860"),Color(hex: "2A2825")], pixels: PA.frog)
        case .butterfly: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "D87090"),Color(hex: "E8A0B0"),Color(hex: "2A2825")], pixels: PA.butterfly, hasShadow: false)
        case .snail: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "A08878"),Color(hex: "C8B8A0"),Color(hex: "706860")], pixels: PA.snail)
        case .fishShadow: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "628BA2").opacity(0.5),Color(hex: "8FB6C8").opacity(0.4)], pixels: PA.fish, hasShadow: false)
        case .child, .shrineMaiden, .caretaker, .fisher, .edgeTraveler, .lostBackpacker,
                .umbrellaWoman, .doorKnocker, .mirrorMiko:
            return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
                Color(hex: "C0B8A8"),Color(hex: "8D867A"),Color(hex: "2A2825"),Color(hex: "E0D8D0")], pixels: PA.rabbit)
        case .forestSpirit, .toriiBetweenLight, .nightLamplighter:
            return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
                Color(hex: "D8D8A8"),Color(hex: "F0E8C0"),Color(hex: "706860")], pixels: PA.butterfly, hasShadow: false)
        case .truckDriver:
            return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
                Color(hex: "7A624A"),Color(hex: "A08060"),Color(hex: "2A2825"),Color(hex: "E0C8B0")], pixels: PA.dog)
        case .cow: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "E8E0D8"),Color(hex: "3A3228"),Color(hex: "D8B898"),Color(hex: "C0B0A0")], pixels: PA.cow)
        case .sheep: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "E8E0D8"),Color(hex: "C8C0B8"),Color(hex: "5A5550"),Color(hex: "2A2825")], pixels: PA.sheep)
        case .horse: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "6C4830"),Color(hex: "8A6040"),Color(hex: "2A2825"),Color(hex: "A08060"),Color(hex: "3A2818")], pixels: PA.horse)
        }
    }

    // MARK: - Utilities
    private func noise(_ x: Int, _ y: Int, _ salt: Int) -> Int {
        var v = x &* 73856093; v ^= y &* 19349663; v ^= salt &* 83492791; return abs(v)
    }
    private var pal: Pal {
        Pal(grass:Color(hex:"C8D6B6"),grassDark:Color(hex:"A9BC91"),grassLight:Color(hex:"D6E2C6"),
            dirt:Color(hex:"B89D78"),dirtDark:Color(hex:"9E855F"),sand:Color(hex:"D8C6A1"),sandDark:Color(hex:"C5B089"),sandLight:Color(hex:"E4D5B7"),
            stone:Color(hex:"9C9287"),stoneDark:Color(hex:"837A70"),stoneLight:Color(hex:"B0A79D"),
            moss:Color(hex:"6F8766"),mossDark:Color(hex:"597050"),wetBank:Color(hex:"958A72"),mud:Color(hex:"7E6952"),mudDark:Color(hex:"6A5643"),
            shallowWater:Color(hex:"8FB6C8"),deepWater:Color(hex:"628BA2"),waterHighlight:Color(hex:"AFCFDA"),reed:Color(hex:"5B744A"),
            flowerAccent:Color(hex:"A0667A"),flowerLight:Color(hex:"D4B6C3"),flowerYellow:Color(hex:"C4A356"),
            pathBase:Color(hex:"A48A67"),pathEdge:Color(hex:"8B7558"),hill:Color(hex:"B7B48A"),hillLight:Color(hex:"C8C39D"),
            cliff:Color(hex:"867A68"),cliffLight:Color(hex:"9C907E"),cliffDark:Color(hex:"6C6253"),
            clearing:Color(hex:"C9D4AF"),groveFloor:Color(hex:"8D8E66"),groveFloorDark:Color(hex:"75764F"))
    }
}

// MARK: - Private Types
private enum RenderableObject {
    case prop(PropPlacement); case animal(AnimalPlacement); case pet(MapCoord)
    var sortY: Int { switch self { case .prop(let p): p.coord.y; case .animal(let a): a.coord.y; case .pet(let c): c.y } }
    var sortX: Int { switch self { case .prop(let p): p.coord.x; case .animal(let a): a.coord.x; case .pet(let c): c.x } }
}

private struct SpriteSpec {
    let tileFootprint: CGSize; let anchor: CGPoint; let palette: [Color]; let pixels: [[UInt8]]; let hasShadow: Bool; let shadowOpacity: CGFloat; let preservesPixelAspect: Bool; let pixelScale: CGFloat
    init(tileFootprint: CGSize, anchor: CGPoint = CGPoint(x: 0.5, y: 1.0), palette: [Color], pixels: [[UInt8]], hasShadow: Bool = true, shadowOpacity: CGFloat = 0.18, preservesPixelAspect: Bool = false, pixelScale: CGFloat = 1) {
        self.tileFootprint = tileFootprint; self.anchor = anchor; self.palette = palette; self.pixels = pixels; self.hasShadow = hasShadow; self.shadowOpacity = shadowOpacity; self.preservesPixelAspect = preservesPixelAspect; self.pixelScale = pixelScale
    }
}

private struct SpriteMotion {
    var offset: CGSize = .zero
    var scale: CGSize = CGSize(width: 1, height: 1)
    var glowOpacity: CGFloat = 0
    var glowColor: Color = Color(hex: "F0E8C0")

    static let still = SpriteMotion()
}

private struct Pal {
    let grass,grassDark,grassLight:Color; let dirt,dirtDark:Color; let sand,sandDark,sandLight:Color
    let stone,stoneDark,stoneLight:Color; let moss,mossDark:Color; let wetBank,mud,mudDark:Color
    let shallowWater,deepWater,waterHighlight:Color; let reed:Color
    let flowerAccent,flowerLight,flowerYellow:Color; let pathBase,pathEdge:Color; let hill,hillLight:Color
    let cliff,cliffLight,cliffDark:Color; let clearing:Color; let groveFloor,groveFloorDark:Color
}

// MARK: - Pixel Art (string-parsed for compactness)
private enum PA {
    static func px(_ rows: [String]) -> [[UInt8]] {
        rows.map { $0.map { c -> UInt8 in
            if c == "." || c == "0" { return 0 }
            if let v = UInt8(String(c), radix: 16), v > 0 { return v }
            return 0
        }}
    }

    // ── Pet 16×16 ──
    static let pet = px([
        "................",
        ".....33333......",
        "....3311133.....",
        "...331111133....",
        "..33111111133...",
        "..31111111113...",
        ".331411141133...",
        ".3114111411133..",
        ".3111161111133..",
        ".311151115113...",
        "..31111111113...",
        "..33111111133...",
        "...331313133....",
        "....33.3.33.....",
        "................",
        "................",
    ])

    // ── House 32×40 complex multi-part building ──
    static let house = px([
        "................................",
        "................................",
        "..........99....................",
        "..........9a....................",
        "..........99....................",
        ".......111111111111111111.......",
        "......1111311111131111111.......",
        ".....11111111111111111111b......",
        "....111111111111111111111b1.....",
        "...1111111111113111111111b11....",
        "..1111111111111111111111111111..",
        "..2222222222222222222222222222..",
        "..b54444444444c544444444444cb..",
        "..b44466644444544466644444445b.",
        "..b44466644444544466644444445b.",
        "..b44466644444544466644444445b.",
        "..b44444444444544444444444445b.",
        "..b44444444444544444444444445b.",
        "..b44466644444544444477884445b.",
        "..b44466644444544444478884445b.",
        "..b44466644444544444477884445b.",
        "..b44444444444544444444444445b.",
        "..b4444444444c5c4444444444c5b.",
        "..baaaaaaaaaaaaaaaaaaaaaaaaab..",
        "..baaaaaaaaaaaaaaaaaaaaaaaaab..",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ])

    // ── Round Tree 24×32 ──
    static let roundTree = px([
        "........................",
        "........................",
        "........114411..........",
        ".......1114411..........",
        "......111111111.........",
        ".....1141111111.........",
        "....111111141111........",
        "...11111111111111.......",
        "...11111111111111.......",
        "..1111411111114111......",
        "..1111111111111111......",
        "..1112211111112111......",
        "..1122211111122211......",
        "..1122222112222211......",
        "...122222222222211......",
        "...112233322233111......",
        "....11233332231.........",
        ".....1133331111.........",
        "......11131111..........",
        ".......1111.............",
        ".........55.............",
        ".........55.............",
        ".........55.............",
        ".........55.............",
        ".........55.............",
        "........5665............",
        "........6666............",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
    ])

    // ── Cherry Tree 24×32 ──
    static let cherryTree = px([
        "........................",
        "........................",
        "........224422..........",
        ".......2224422..........",
        "......222222222.........",
        ".....2242222222.........",
        "....222222242222........",
        "...22222222222222.......",
        "...22222222222222.......",
        "..2222422222224222......",
        "..2222222222222222......",
        "..2223312222113322......",
        "..2233332112333322......",
        "..2233333333333322......",
        "...23333333333322.......",
        "...223366633366222......",
        "....223666633622........",
        ".....2266662222.........",
        "......22262222..........",
        ".......2222.............",
        ".........55.............",
        ".........55.............",
        ".........55.............",
        ".........55.............",
        ".........55.............",
        "........5665............",
        "........6666............",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
    ])

    // ── Tall Tree 24×32 ──
    static let tallTree = px([
        "........................",
        "..........34............",
        ".........3314...........",
        "........331114..........",
        ".......11111111.........",
        ".......14111111.........",
        "......111111111.........",
        ".....1141111111.........",
        ".....1111141111.........",
        "....111111111111........",
        "....111111111111........",
        "...1111111111111........",
        "...1122111112211........",
        "...1122221222211........",
        "....12222222221.........",
        "....11222222211.........",
        ".....1222222111.........",
        "......1122211...........",
        ".......11211............",
        ".........55.............",
        ".........55.............",
        ".........55.............",
        ".........55.............",
        ".........55.............",
        ".........55.............",
        "........5665............",
        "........6666............",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
    ])

    // ── Big Tree 32×40 ──
    static let bigTree = px([
        "................................",
        "................................",
        "..........11341.................",
        ".........111111.................",
        "........1114111111..............",
        ".......111111111111.............",
        "......1111111141111.............",
        ".....111411111111111............",
        "....11111111111111111...........",
        "....111111111111111111..........",
        "...1111114111111114111..........",
        "...1111111111111111111..........",
        "..111111111111111111111.........",
        "..111111111111111111111.........",
        "..111122111111111221111.........",
        "..111222211111122221111.........",
        "..112222222112222222111.........",
        "...12222222222222221...........",
        "...11222222222222211...........",
        "....1122222222222111............",
        ".....11122222221111.............",
        "......11112221111...............",
        ".......11111111.................",
        "..........5555..................",
        "..........5555..................",
        "..........5555..................",
        "..........5555..................",
        "..........5555..................",
        ".........566665.................",
        ".........666666.................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ])

    // ── Small Bush 16×8 ──
    static let smallBush = px([
        "................",
        "......22........",
        ".....2332.......",
        "....223322......",
        "...22222222.....",
        "..1222222221....",
        "...11111111.....",
        "................",
    ])

    // ── Dense Bush 24×16 ──
    static let denseBush = px([
        "........................",
        "....22....22............",
        "...2342..2342...........",
        "..22332223322...........",
        ".2222222222222..........",
        ".2222322232222..........",
        "122222222222221.........",
        ".1111111111111..........",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
    ])

    // ── Flower 8×8 ──
    static let flower = px([
        "........",
        "...1....",
        "..131...",
        "...1....",
        "...4....",
        "...4....",
        "...4....",
        "........",
    ])

    // ── Flower Bed 16×8 ──
    static let flowerBed = px([
        "................",
        "..1..5..1..5....",
        ".131.5.131.5....",
        "..1..5..1..5....",
        "..4..4..4..4....",
        "..4..4..4..4....",
        ".44444444444....",
        "................",
    ])

    // ── Mushroom 8×8 ──
    static let mushroom = px([
        "........",
        "........",
        "..1111..",
        ".121121.",
        "..1111..",
        "...33...",
        "...33...",
        "........",
    ])

    // ── Reed Cluster 16×16 ──
    static let reedCluster = px([
        "................",
        "..1..1..1.......",
        "..1..1..1.......",
        "..1.11..1.......",
        ".11.11.11.......",
        ".11..1.11.......",
        ".1..11.11.......",
        ".1..11..1.......",
        ".1..1...1.......",
        ".2..2...2.......",
        ".2..2...2.......",
        ".2..2...2.......",
        ".2..2...2.......",
        ".2..2...2.......",
        "................",
        "................",
    ])

    // ── Stump 8×8 ──
    static let stump = px([
        "........",
        "........",
        "..3333..",
        "..1331..",
        "..1111..",
        "..2112..",
        "..2222..",
        "........",
    ])

    // ── Fallen Log 16×8 ──
    static let fallenLog = px([
        "................",
        "................",
        "................",
        "..33............",
        ".311111111113...",
        ".211111111112...",
        "..22222222222...",
        "................",
    ])

    // ── Small Rock 8×8 ──
    static let smallRock = px([
        "........",
        "........",
        "........",
        "...33...",
        "..3221..",
        "..2221..",
        "...11...",
        "........",
    ])

    // ── Large Rock 24×16 ──
    static let largeRock = px([
        "........................",
        "........................",
        "........................",
        "........................",
        ".......333333...........",
        "......33332222..........",
        ".....3333222222.........",
        "....333322222221........",
        "....333222222211........",
        "....332222222111........",
        ".....32222211111........",
        "......4222111...........",
        ".......4411.............",
        "........................",
        "........................",
        "........................",
    ])

    // ── Signpost 8×16 ──
    static let signpost = px([
        "........",
        "........",
        "........",
        ".444444.",
        ".444444.",
        ".244442.",
        "...11...",
        "...11...",
        "...11...",
        "...11...",
        "...11...",
        "...11...",
        "...22...",
        "...22...",
        "........",
        "........",
    ])

    // ── Bench 16×8 ──
    static let bench = px([
        "................",
        "................",
        "..333333333333..",
        "..111111111111..",
        "..211111111112..",
        "..2..........2..",
        "..2..........2..",
        "................",
    ])

    // ── Fence 8×8 ──
    static let fence = px([
        "........",
        ".1....1.",
        ".1....1.",
        ".111111.",
        ".1....1.",
        ".211112.",
        ".2....2.",
        "........",
    ])

    // ── Crate 8×8 ──
    static let crate = px([
        "........",
        "........",
        "..3333..",
        "..1331..",
        "..1111..",
        "..2112..",
        "..2222..",
        "........",
    ])

    // ── Lantern 8×16 ──
    static let lantern = px([
        "........",
        "........",
        "........",
        "...11...",
        "...11...",
        "..1221..",
        "..1221..",
        "..1221..",
        "...11...",
        "...33...",
        "...33...",
        "...33...",
        "...33...",
        "...33...",
        "........",
        "........",
    ])

    // ── Stone Lantern 8×16 ──
    static let stoneLantern = px([
        "........",
        "........",
        "...22...",
        "..2222..",
        ".222222.",
        "...11...",
        "...11...",
        "..1111..",
        "..1331..",
        "...33...",
        "...33...",
        "...33...",
        "..3333..",
        ".333333.",
        "........",
        "........",
    ])

    // ── Mailbox 8×16 ──
    static let mailbox = px([
        "........",
        "........",
        "........",
        "........",
        "..3333..",
        "..3443..",
        "..3333..",
        "...11...",
        "...11...",
        "...11...",
        "...11...",
        "...11...",
        "...22...",
        "...22...",
        "........",
        "........",
    ])

    // ── Well 16×16 ──
    static let well = px([
        "................",
        ".....55555......",
        "....5555555.....",
        ".....5...5......",
        ".....5...5......",
        ".....5...5......",
        "....1111111.....",
        "...113111311....",
        "...1144441111...",
        "...1144441111...",
        "...11111111111..",
        "....122222221...",
        ".....2222222....",
        "................",
        "................",
        "................",
    ])

    // ── Bridge 16×8 ──
    static let bridge = px([
        "................",
        "................",
        ".2............2.",
        ".13333333333331.",
        ".11111111111111.",
        ".21111111111112.",
        "..22222222222...",
        "................",
    ])

    // ── Japanese Arched Bridge 24×16 ──
    static let japaneseBridge = px([
        "........................",
        "........................",
        "........................",
        ".......1111111111.......",
        ".....11222222222211.....",
        "....1222222222222221....",
        "...12222........22221...",
        "..1222............2221..",
        ".1222..............2221.",
        ".133333333333333333331.",
        "..4444444444444444444..",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
    ])

    // ── Gate 16×16 ──
    static let gate = px([
        "................",
        "..1..........1..",
        "..1..........1..",
        "..1....33....1..",
        "..1222222222.1..",
        "..1..2...2...1..",
        "..1..2...2...1..",
        "..1222222222.1..",
        "..1..2...2...1..",
        "..1..2...2...1..",
        "..1..........1..",
        "..1..........1..",
        "................",
        "................",
        "................",
        "................",
    ])

    // ── Torii 16×24 ──
    static let torii = px([
        "................",
        "................",
        "..111111111111..",
        ".22222222222222.",
        "...3333333333...",
        "....11111111....",
        "....11111111....",
        "...2222222222...",
        "...2........2...",
        "...2........2...",
        "...2........2...",
        "...2........2...",
        "...2........2...",
        "...2........2...",
        "...2........2...",
        "..33........33..",
        "..33........33..",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    // ── Shrine 16×24 ──
    static let shrine = px([
        "................",
        ".......44.......",
        "......4444......",
        ".....411114.....",
        "....41111114....",
        "...422222222....",
        ".....1....1.....",
        ".....1....1.....",
        "....11111111....",
        "....13111131....",
        "....11111111....",
        "....11144111....",
        "....11144111....",
        "....11111111....",
        "....22222222....",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    // ── Pagoda 16×24 ──
    static let pagoda = px([
        "................",
        "......1111......",
        ".....111111.....",
        "....11111111....",
        "......3333......",
        ".....333333.....",
        "....33333333....",
        "...1111111111...",
        ".....333333.....",
        "....33333333....",
        "...1111111111...",
        ".....333333.....",
        "....33333333....",
        "...1111111111...",
        ".....333333.....",
        ".....344333.....",
        ".....344333.....",
        ".....333333.....",
        "....55555555....",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    // ── Small Shrine 24×24 ──
    static let shrineJp = px([
        "........................",
        "........................",
        ".........444444.........",
        "........44444444........",
        ".......4444444444.......",
        "......444444444444......",
        ".....11111111111111.....",
        ".....13333333333331.....",
        ".....13333333333331.....",
        ".....13335333353331.....",
        ".....13333333333331.....",
        ".....13333333333331.....",
        ".....13333333333331.....",
        ".....12222222222221.....",
        "......222222222222......",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
    ])

    // ── Shed 24×24 ──
    static let shed = px([
        "........................",
        "........................",
        ".......33333333.........",
        "......3333333333........",
        ".....33433334333........",
        "....333333333333........",
        "...44444444444444.......",
        "...2515555555552........",
        "...2515555555552........",
        "...2515552255552........",
        "...2515552255552........",
        "...2515552255552........",
        "...22222222222222.......",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
    ])

    // ── Kiosk 16×16 ──
    static let kiosk = px([
        "................",
        "...444444444....",
        "..44444444444...",
        "................",
        "..21111111112...",
        "..21133331112...",
        "..21133331112...",
        "..21111111112...",
        "..21111111112...",
        "..21111111112...",
        "..22222222222...",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    // ── Car 24×16 ──
    static let car = px([
        "........................",
        "........................",
        "........................",
        "........333333..........",
        ".......33443433.........",
        "......3344443331........",
        ".....11111111111111.....",
        "....1111111111111111....",
        "....1116111111611111....",
        "....1111111111111111....",
        "....2111111111111112....",
        ".....55..222222..55.....",
        ".....55..........55.....",
        "........................",
        "........................",
        "........................",
    ])

    // ── Billboard 16×24 ──
    static let billboard = px([
        "................",
        ".22222222222222.",
        ".23333333333332.",
        ".23345533455332.",
        ".23333333333332.",
        ".23333333333332.",
        ".23355333553332.",
        ".23333333333332.",
        ".22222222222222.",
        ".......11.......",
        ".......11.......",
        ".......11.......",
        ".......11.......",
        ".......11.......",
        ".......11.......",
        ".......11.......",
        ".......22.......",
        ".......22.......",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    // ── Windmill 24×40 ──
    static let windmill = px([
        "........................",
        "........................",
        "...........55...........",
        "..........5115..........",
        "..........5115..........",
        "..........5115..........",
        "...5......5115..........",
        "...55.....5115..........",
        "...555....5115..........",
        "....555...5115..........",
        ".....555..5115..........",
        "......5555511555555555..",
        ".......555511555555.....",
        "........5551155555......",
        ".........55115555.......",
        "..........511555........",
        "..........51155.........",
        "..........5115..........",
        ".........11111..........",
        "........1111111.........",
        "........1161611.........",
        "........1111111.........",
        "........1111111.........",
        "........1111111.........",
        "........1111111.........",
        "........1161611.........",
        "........1111111.........",
        "........1111111.........",
        "........2222222.........",
        ".......333333333........",
        ".......333333333........",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
    ])

    // ── Animals ──

    static let bird = px([
        "................",
        "................",
        "................",
        "................",
        ".....4.11.......",
        "....1111.3......",
        "...2111111......",
        "....1111........",
        ".....11.........",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    static let duck = px([
        "................",
        "................",
        "................",
        ".....11.........",
        "....1111.3......",
        "....2111........",
        "...44144........",
        "....444.........",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    static let rabbit = px([
        "................",
        "................",
        "....1..1........",
        "....1..1........",
        "....1..1........",
        "....1111........",
        "....3131........",
        "....1411........",
        "....1111........",
        ".....22.........",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    static let cat = px([
        "................",
        "................",
        "................",
        "....1..1........",
        "....1111........",
        "....3131........",
        "....11111.......",
        "....4141........",
        ".....22.........",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    static let dog = px([
        "................",
        "................",
        "................",
        "....111.........",
        "....1111........",
        "....3111........",
        "..1111111.......",
        "....41114.......",
        ".....2..2.......",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    static let deer = px([
        "........................",
        "..1.1...................",
        "..111...................",
        "...1....................",
        "..222...................",
        "..422...................",
        "..2222222222............",
        "....233323222...........",
        "....255525222...........",
        "....22222222222.........",
        "....2...2....2..........",
        "....2...2...............",
        "....1...1...............",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
    ])

    static let cow = px([
        "................",
        "................",
        "................",
        "....11.11.......",
        "....11111.......",
        "....41131.......",
        "..111113111.....",
        "..111111111.....",
        "..141111141.....",
        "...2..1..2......",
        "...2.....2......",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    static let sheep = px([
        "................",
        "................",
        "................",
        ".....33.........",
        "....31133.......",
        "....41143.......",
        "..111111111.....",
        "..121212121.....",
        "..111111111.....",
        "...3...3........",
        "...3...3........",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    static let horse = px([
        "................",
        "................",
        "....55..........",
        "...551..........",
        "...2211.........",
        "...3211.........",
        "..2211111.......",
        "...2222222......",
        "...2442442......",
        "...2..2..2......",
        "...1..1..........",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    static let frog = px([
        "........",
        "........",
        "..3.3...",
        "..111...",
        ".12121..",
        ".11111..",
        "..1.1...",
        "........",
    ])

    static let butterfly = px([
        "........",
        "........",
        ".1...1..",
        ".21321..",
        ".1.3.1..",
        "........",
        "........",
        "........",
    ])

    static let snail = px([
        "........",
        "........",
        "........",
        "..11....",
        ".1211...",
        ".33333..",
        "..333...",
        "........",
    ])

    static let fish = px([
        "........",
        "........",
        "........",
        "........",
        "..111...",
        ".21111..",
        "..111...",
        "........",
    ])
}

#Preview {
    MapView(tileSize: 10, testMap: TestMapFactory.fullWorld, showPetSpawn: true, petCoord: TestMapFactory.fullWorld.petSpawn.coord)
}
