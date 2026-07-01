import Foundation

struct TestMap {
    let name: String
    let width: Int
    let height: Int
    let terrain: TerrainLayer
    let props: [PropPlacement]
    let animals: [AnimalPlacement]
    let petSpawn: CreatureSpawn
}

enum TestMapFactory {
    static let quietPond: TestMap = {
        let width = 16
        let height = 16
        var terrain = TerrainLayer(width: width, height: height, fill: .grass)

        // Decorative outer ring.
        for y in 0..<height {
            for x in 0..<width {
                if x == 0 || y == 0 || x == width - 1 || y == height - 1 {
                    terrain.set(.stone, at: MapCoord(x: x, y: y))
                }
            }
        }

        // Hand-authored pond shape.
        let pond: [MapCoord] = [
            .init(x: 10, y: 4), .init(x: 11, y: 4), .init(x: 12, y: 4),
            .init(x: 9, y: 5), .init(x: 10, y: 5), .init(x: 11, y: 5), .init(x: 12, y: 5),
            .init(x: 9, y: 6), .init(x: 10, y: 6), .init(x: 11, y: 6), .init(x: 12, y: 6),
            .init(x: 10, y: 7), .init(x: 11, y: 7)
        ]
        pond.forEach { terrain.set(.water, at: $0) }

        // Sand edge around water.
        let sandEdge: [MapCoord] = [
            .init(x: 9, y: 4), .init(x: 13, y: 4),
            .init(x: 8, y: 5), .init(x: 13, y: 5),
            .init(x: 8, y: 6), .init(x: 13, y: 6),
            .init(x: 9, y: 7), .init(x: 12, y: 7),
            .init(x: 10, y: 8), .init(x: 11, y: 8)
        ]
        sandEdge.forEach { terrain.set(.sand, at: $0) }

        // Dirt path from lower-left toward center.
        let dirtPath: [MapCoord] = [
            .init(x: 2, y: 13), .init(x: 3, y: 13),
            .init(x: 3, y: 12), .init(x: 4, y: 12),
            .init(x: 4, y: 11), .init(x: 5, y: 11),
            .init(x: 5, y: 10), .init(x: 6, y: 10),
            .init(x: 6, y: 9), .init(x: 7, y: 9),
            .init(x: 8, y: 9), .init(x: 9, y: 9)
        ]
        dirtPath.forEach { terrain.set(.dirt, at: $0) }

        // Flower patches for environmental variety.
        let flowerPatches: [MapCoord] = [
            .init(x: 4, y: 4), .init(x: 5, y: 4),
            .init(x: 4, y: 5),
            .init(x: 7, y: 3), .init(x: 8, y: 3),
            .init(x: 12, y: 10), .init(x: 13, y: 10),
            .init(x: 11, y: 11)
        ]
        flowerPatches.forEach { terrain.set(.flowerPatch, at: $0) }

        let props: [PropPlacement] = [
            // Tree cluster (upper-left).
            .init(kind: .tree, coord: .init(x: 2, y: 2)),
            .init(kind: .tree, coord: .init(x: 3, y: 2)),
            .init(kind: .tree, coord: .init(x: 2, y: 3)),
            .init(kind: .bush, coord: .init(x: 4, y: 3)),
            .init(kind: .stump, coord: .init(x: 3, y: 4)),

            // Path-side props.
            .init(kind: .sign, coord: .init(x: 6, y: 11)),
            .init(kind: .crate, coord: .init(x: 7, y: 10)),
            .init(kind: .bench, coord: .init(x: 8, y: 11)),
            .init(kind: .log, coord: .init(x: 5, y: 9)),

            // Water-adjacent props.
            .init(kind: .reed, coord: .init(x: 8, y: 6)),
            .init(kind: .reed, coord: .init(x: 13, y: 7)),
            .init(kind: .rock, coord: .init(x: 12, y: 8)),

            // Scattered liveliness.
            .init(kind: .mushroomPatch, coord: .init(x: 10, y: 12)),
            .init(kind: .flower, coord: .init(x: 6, y: 4)),
            .init(kind: .fence, coord: .init(x: 14, y: 9)),
            .init(kind: .fence, coord: .init(x: 14, y: 10))
        ]

        let animals: [AnimalPlacement] = [
            .init(kind: .bird, coord: .init(x: 5, y: 3)),
            .init(kind: .duck, coord: .init(x: 10, y: 5)),
            .init(kind: .rabbit, coord: .init(x: 8, y: 12)),
            .init(kind: .cat, coord: .init(x: 6, y: 13)),
            .init(kind: .dog, coord: .init(x: 9, y: 10)),
            .init(kind: .deer, coord: .init(x: 12, y: 12))
        ]

        let petSpawn = CreatureSpawn(id: "pico", coord: .init(x: 7, y: 8))

        return TestMap(
            name: "Quiet Pond",
            width: width,
            height: height,
            terrain: terrain,
            props: props,
            animals: animals,
            petSpawn: petSpawn
        )
    }()
}
