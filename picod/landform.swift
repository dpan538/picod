import Foundation

struct MapCoord: Hashable, Codable {
    let x: Int
    let y: Int
}

enum Landform: String, CaseIterable, Codable {
    case grass
    case dirt
    case water
    case sand
    case flowerPatch
    case stone
}

struct TerrainLayer: Codable {
    let width: Int
    let height: Int
    private(set) var tiles: [[Landform]]

    init(width: Int, height: Int, fill: Landform) {
        self.width = width
        self.height = height
        self.tiles = Array(repeating: Array(repeating: fill, count: width), count: height)
    }

    mutating func set(_ landform: Landform, at coord: MapCoord) {
        guard coord.x >= 0, coord.x < width, coord.y >= 0, coord.y < height else { return }
        tiles[coord.y][coord.x] = landform
    }

    func landform(at coord: MapCoord) -> Landform {
        guard coord.x >= 0, coord.x < width, coord.y >= 0, coord.y < height else {
            return .grass
        }
        return tiles[coord.y][coord.x]
    }
}
