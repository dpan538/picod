import Combine
import Foundation

@MainActor
final class LifeAlbumStore: ObservableObject {
    @Published private(set) var albums: [LifeAlbum] = []

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? PicodAtomicJSON.fileURL(named: "life_albums_db.json")
        load()
    }

    func upsert(_ album: LifeAlbum) {
        if let index = albums.firstIndex(where: { $0.id == album.id }) {
            albums[index] = album
        } else {
            albums.append(album)
        }
        albums.sort { $0.endedAt < $1.endedAt }
        if albums.count > 60 {
            albums.removeFirst(albums.count - 60)
        }
        save()
    }

    func resetAll() {
        albums = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func load() {
        albums = PicodAtomicJSON.load([LifeAlbum].self, from: fileURL) ?? []
    }

    private func save() {
        PicodAtomicJSON.save(albums, to: fileURL)
    }
}
