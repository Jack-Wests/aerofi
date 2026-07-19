import Foundation
import SwiftData

@Model
final class Playlist {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateCreated: Date
    var dateModified: Date
    /// SF Symbol used when the playlist has no songs yet to derive artwork from.
    var iconSymbolName: String

    @Relationship(deleteRule: .cascade, inverse: \PlaylistItem.playlist) var items: [PlaylistItem]?

    init(
        id: UUID = UUID(),
        name: String,
        dateCreated: Date = Date(),
        iconSymbolName: String = "music.note.list"
    ) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.dateModified = dateCreated
        self.iconSymbolName = iconSymbolName
    }

    var sortedItems: [PlaylistItem] {
        (items ?? []).sorted { $0.position < $1.position }
    }

    var songs: [Song] {
        sortedItems.compactMap { $0.song }
    }

    var totalDuration: TimeInterval {
        songs.reduce(0) { $0 + $1.duration }
    }

    /// Up to 4 artworks for a collage-style playlist tile.
    var artworkCollage: [Data] {
        Array(songs.compactMap { $0.artworkData }.prefix(4))
    }
}
