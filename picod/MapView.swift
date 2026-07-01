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

    init(tileSize: CGFloat = 10, testMap: TestMap? = nil, showPetSpawn: Bool = false, petCoord: MapCoord? = nil) {
        self.tileSize = tileSize
        self.testMap = testMap
        self.showPetSpawn = showPetSpawn
        self.petCoord = petCoord
    }

    var body: some View {
        Canvas { ctx, size in
            if let map = testMap {
                drawWorld(ctx: &ctx, size: size, map: map, petCoord: petCoord)
            } else {
                drawFallbackGrid(ctx: &ctx, size: size)
            }
        }
    }

    private func drawFallbackGrid(ctx: inout GraphicsContext, size: CGSize) {
        let t = tileSize
        let cols = Int(ceil(size.width / t))
        let rows = Int(ceil(size.height / t))
        for y in 0..<rows {
            for x in 0..<cols {
                let color = (x + y).isMultiple(of: 2) ? Color.picod_tile_a : Color.picod_tile_b
                let rect = CGRect(x: CGFloat(x) * t, y: CGFloat(y) * t, width: t, height: t)
                ctx.fill(Path(rect), with: .color(color))
            }
        }
    }

    // MARK: - World Drawing

    private func drawWorld(ctx: inout GraphicsContext, size: CGSize, map: TestMap, petCoord: MapCoord?) {
        let tile = min(size.width / CGFloat(map.width), size.height / CGFloat(map.height))
        let mapW = CGFloat(map.width) * tile
        let mapH = CGFloat(map.height) * tile
        let origin = CGPoint(x: (size.width - mapW) / 2, y: (size.height - mapH) / 2)

        for y in 0..<map.height {
            for x in 0..<map.width {
                let coord = MapCoord(x: x, y: y)
                let land = map.terrain.landform(at: coord)
                let rect = CGRect(x: origin.x + CGFloat(x) * tile, y: origin.y + CGFloat(y) * tile, width: tile, height: tile)
                drawTerrainTile(ctx: &ctx, rect: rect, coord: coord, landform: land)
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

        var layers: [RenderableObject] = []
        layers.reserveCapacity(map.props.count + map.animals.count + 1)
        for p in map.props { layers.append(.prop(p)) }
        for a in map.animals { layers.append(.animal(a)) }
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
            case .prop(let p): drawProp(p.kind, coord: p.coord, origin: origin, tile: tile, ctx: &ctx)
            case .animal(let a): drawAnimal(a.kind, coord: a.coord, origin: origin, tile: tile, ctx: &ctx)
            case .pet(let c): drawPet(coord: c, origin: origin, tile: tile, ctx: &ctx)
            }
        }
    }

    // MARK: - Terrain

    private func drawTerrainTile(ctx: inout GraphicsContext, rect: CGRect, coord: MapCoord, landform: Landform) {
        let p = pal; let v = noise(coord.x, coord.y, 7) % 2; let v2 = noise(coord.x, coord.y, 17) % 2
        let px = rect.width / 8.0
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
        case .tallGrass:
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
        case .stoneGround:
            fill(p.stone)
            hLine(3, 0, 7, p.stoneDark)
            dot(0, v==0 ? 4:2, p.stoneDark); dot(1, v==0 ? 4:2, p.stoneDark); dot(2, v==0 ? 4:2, p.stoneDark)
            dot(4, v2==0 ? 6:1, p.stoneDark); dot(5, v2==0 ? 6:1, p.stoneDark); dot(1, v==0 ? 6:5, p.stoneLight)
        case .mud:
            fill(p.mud); dot(2, v==0 ? 2:5, p.mudDark); dot(4, v2==0 ? 4:1, p.mudDark); dot(5, v==0 ? 6:3, p.mudDark)
        case .mossGround:
            fill(p.moss); dot(1, v==0 ? 2:5, p.mossDark); dot(3, v2==0 ? 4:1, p.mossDark); dot(5, v==0 ? 6:3, p.mossDark); dot(4, 2, p.grass)
        case .pond, .shallowWater:
            fill(p.shallowWater)
            hLine(v==0 ? 2:5, v2==0 ? 1:3, v2==0 ? 3:5, p.waterHighlight)
            hLine(v==0 ? 5:2, v2==0 ? 5:1, v2==0 ? 6:2, p.waterHighlight)
        case .deepWater:
            fill(p.deepWater)
            hLine(v==0 ? 2:5, v2==0 ? 2:4, v2==0 ? 4:6, p.waterHighlight)
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
        case .grass: return p.grass; case .tallGrass: return p.grassDark; case .dirt: return p.dirt
        case .wornPath: return p.pathBase; case .sand: return p.sand; case .stoneGround: return p.stone
        case .mud: return p.mud; case .mossGround: return p.moss; case .pond, .shallowWater: return p.shallowWater
        case .deepWater: return p.deepWater; case .reedsEdge: return p.wetBank; case .wetBank: return p.wetBank
        case .smallHill: return p.hill; case .cliffEdge: return p.cliff; case .clearing: return p.clearing
        case .groveFloor: return p.groveFloor; case .flowerPatch: return p.clearing
        }
    }

    // MARK: - Sprite Drawing

    private func drawSprite(spec: SpriteSpec, coord: MapCoord, origin: CGPoint, tile: CGFloat, ctx: inout GraphicsContext) {
        let ground = CGPoint(x: origin.x + (CGFloat(coord.x) + 0.5) * tile, y: origin.y + CGFloat(coord.y + 1) * tile)
        let sW = spec.tileFootprint.width * tile; let sH = spec.tileFootprint.height * tile
        let sO = CGPoint(x: ground.x - sW * spec.anchor.x, y: ground.y - sH * spec.anchor.y)
        if spec.hasShadow {
            let sw = tile * spec.tileFootprint.width * 0.5; let sh = tile * 0.3
            ctx.fill(Path(ellipseIn: CGRect(x: ground.x - sw/2, y: ground.y - sh/2, width: sw, height: sh)), with: .color(Color(hex: "2F2A24").opacity(0.18)))
        }
        let art = spec.pixels; let rows = art.count; let cols = art.first?.count ?? 0
        guard rows > 0, cols > 0 else { return }
        let pxW = sW / CGFloat(cols); let pxH = sH / CGFloat(rows)
        for row in 0..<rows {
            for col in 0..<cols {
                let idx = Int(art[row][col])
                guard idx > 0, idx <= spec.palette.count else { continue }
                ctx.fill(Path(CGRect(x: sO.x + CGFloat(col)*pxW, y: sO.y + CGFloat(row)*pxH, width: pxW+0.5, height: pxH+0.5)), with: .color(spec.palette[idx-1]))
            }
        }
    }

    private func drawProp(_ k: PropKind, coord: MapCoord, origin: CGPoint, tile: CGFloat, ctx: inout GraphicsContext) {
        drawSprite(spec: propSpec(for: k), coord: coord, origin: origin, tile: tile, ctx: &ctx)
    }
    private func drawAnimal(_ k: AnimalKind, coord: MapCoord, origin: CGPoint, tile: CGFloat, ctx: inout GraphicsContext) {
        drawSprite(spec: animalSpec(for: k), coord: coord, origin: origin, tile: tile, ctx: &ctx)
    }
    private func drawPet(coord: MapCoord, origin: CGPoint, tile: CGFloat, ctx: inout GraphicsContext) {
        drawSprite(spec: petSpec, coord: coord, origin: origin, tile: tile, ctx: &ctx)
    }

    // MARK: - Pet Spec
    private var petSpec: SpriteSpec {
        SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "F0EDE8"), Color(hex: "D8D4CE"), Color(hex: "5A5550"), Color(hex: "2A2825"), Color(hex: "E8B0A0")
        ], pixels: PA.pet)
    }

    // MARK: - Prop Specs
    private func propSpec(for k: PropKind) -> SpriteSpec {
        switch k {
        case .house: return SpriteSpec(tileFootprint: CGSize(width: 4, height: 5), palette: [
            Color(hex: "8090A0"),Color(hex: "606878"),Color(hex: "A8B8C8"),Color(hex: "E8D8C0"),Color(hex: "C8B8A0"),
            Color(hex: "506878"),Color(hex: "886848"),Color(hex: "685038"),Color(hex: "A07060"),Color(hex: "808078"),
            Color(hex: "3A3228"),Color(hex: "B0A898")], pixels: PA.house)
        case .roundTree: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 4), palette: [
            Color(hex: "6CA050"),Color(hex: "4A7838"),Color(hex: "3A6030"),Color(hex: "88C068"),Color(hex: "806040"),Color(hex: "5A4030")], pixels: PA.roundTree)
        case .tallTree: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 4), palette: [
            Color(hex: "4A7838"),Color(hex: "3A6030"),Color(hex: "6CA050"),Color(hex: "88C068"),Color(hex: "806040"),Color(hex: "5A4030")], pixels: PA.tallTree)
        case .bigTree: return SpriteSpec(tileFootprint: CGSize(width: 4, height: 5), palette: [
            Color(hex: "5A8848"),Color(hex: "3E6830"),Color(hex: "7AB060"),Color(hex: "98D078"),Color(hex: "705838"),Color(hex: "503820")], pixels: PA.bigTree)
        case .smallBush: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 1), palette: [
            Color(hex: "3E5638"),Color(hex: "5A7848"),Color(hex: "88C068")], pixels: PA.smallBush)
        case .denseBush: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 2), palette: [
            Color(hex: "3E5638"),Color(hex: "4F6A47"),Color(hex: "6CA050"),Color(hex: "88C068")], pixels: PA.denseBush)
        case .pinkFlower: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "D87090"),Color(hex: "E8A0B0"),Color(hex: "C85070"),Color(hex: "4A7838")], pixels: PA.flower, hasShadow: false)
        case .yellowFlower: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "D8B040"),Color(hex: "E8D070"),Color(hex: "C89830"),Color(hex: "4A7838")], pixels: PA.flower, hasShadow: false)
        case .flowerBed: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 1), palette: [
            Color(hex: "D87090"),Color(hex: "E8D070"),Color(hex: "C85070"),Color(hex: "4A7838"),Color(hex: "D8B040")], pixels: PA.flowerBed, hasShadow: false)
        case .mushroomPatch: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "C88060"),Color(hex: "E8C8A0"),Color(hex: "D8D0C0")], pixels: PA.mushroom, hasShadow: false)
        case .reedCluster: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "5B744A"),Color(hex: "7A9860")], pixels: PA.reedCluster, hasShadow: false)
        case .stump: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "A08060")], pixels: PA.stump)
        case .fallenLog: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 1), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "A08060")], pixels: PA.fallenLog)
        case .smallRock: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "706860"),Color(hex: "908880"),Color(hex: "B0A8A0")], pixels: PA.smallRock)
        case .largeRock: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 2), palette: [
            Color(hex: "706860"),Color(hex: "908880"),Color(hex: "B0A8A0"),Color(hex: "585050")], pixels: PA.largeRock)
        case .signpost: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 2), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "A08060"),Color(hex: "E8D8C0")], pixels: PA.signpost)
        case .bench: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 1), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "A08060")], pixels: PA.bench)
        case .fenceShort: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "806040"),Color(hex: "6C513A")], pixels: PA.fence)
        case .crate: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 1), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "A08060")], pixels: PA.crate)
        case .lantern: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 2), palette: [
            Color(hex: "585050"),Color(hex: "E8C848"),Color(hex: "706860")], pixels: PA.lantern)
        case .mailbox: return SpriteSpec(tileFootprint: CGSize(width: 1, height: 2), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "B85040"),Color(hex: "903828")], pixels: PA.mailbox)
        case .stoneWell: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "908880"),Color(hex: "706860"),Color(hex: "B0A8A0"),Color(hex: "628BA2"),Color(hex: "806040")], pixels: PA.well)
        case .bridgeShort: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 1), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "A08060")], pixels: PA.bridge)
        case .gate: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "6C513A"),Color(hex: "806040"),Color(hex: "585050")], pixels: PA.gate)
        case .shrineSmall: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 3), palette: [
            Color(hex: "908880"),Color(hex: "706860"),Color(hex: "B0A8A0"),Color(hex: "B85040")], pixels: PA.shrine)
        case .tinyShed: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 3), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "908880"),Color(hex: "706860"),Color(hex: "E8D8C0")], pixels: PA.shed)
        case .kiosk: return SpriteSpec(tileFootprint: CGSize(width: 2, height: 2), palette: [
            Color(hex: "806040"),Color(hex: "6C513A"),Color(hex: "E8D8C0"),Color(hex: "B85040")], pixels: PA.kiosk)
        case .car: return SpriteSpec(tileFootprint: CGSize(width: 3, height: 2), palette: [
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
    let tileFootprint: CGSize; let anchor: CGPoint; let palette: [Color]; let pixels: [[UInt8]]; let hasShadow: Bool
    init(tileFootprint: CGSize, anchor: CGPoint = CGPoint(x: 0.5, y: 1.0), palette: [Color], pixels: [[UInt8]], hasShadow: Bool = true) {
        self.tileFootprint = tileFootprint; self.anchor = anchor; self.palette = palette; self.pixels = pixels; self.hasShadow = hasShadow
    }
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
        "....311111133...",
        "...3111111113...",
        "...3111111113...",
        "..31111111111133",
        "..311141114113..",
        "..311141114113..",
        "..31111111111133",
        "..311151115113..",
        "..31111111111133",
        "...3111111113...",
        "...31131131133..",
        "....33.33.33....",
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
