import Foundation
import SwiftData

@Model
final class Artist {
    @Attribute(.unique) var id: UUID
    var name: String

    @Relationship(deleteRule: .nullify, inverse: \Song.artist) var songs: [Song]?
    @Relationship(deleteRule: .nullify, inverse: \Album.artist) var albums: [Album]?

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    var sortedAlbums: [Album] {
        (albums ?? []).sorted { ($0.year ?? 0) > ($1.year ?? 0) }
    }

    /// Representative artwork: first available album artwork, falling back to any song's embedded artwork.
    var representativeArtworkData: Data? {
        if let art = albums?.compactMap({ $0.artworkData }).first {
            return art
        }
        return songs?.compactMap { $0.artworkData }.first
    }
}
