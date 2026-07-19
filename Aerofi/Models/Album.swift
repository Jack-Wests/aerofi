import Foundation
import SwiftData

@Model
final class Album {
    @Attribute(.unique) var id: UUID
    var name: String
    var albumArtist: String
    var year: Int?
    @Attribute(.externalStorage) var artworkData: Data?

    @Relationship(deleteRule: .nullify, inverse: \Song.album) var songs: [Song]?
    @Relationship var artist: Artist?

    init(id: UUID = UUID(), name: String, albumArtist: String, year: Int? = nil, artworkData: Data? = nil) {
        self.id = id
        self.name = name
        self.albumArtist = albumArtist
        self.year = year
        self.artworkData = artworkData
    }

    var sortedSongs: [Song] {
        (songs ?? []).sorted {
            if $0.discNumber != $1.discNumber {
                return ($0.discNumber ?? 0) < ($1.discNumber ?? 0)
            }
            return ($0.trackNumber ?? Int.max) < ($1.trackNumber ?? Int.max)
        }
    }

    var totalDuration: TimeInterval {
        (songs ?? []).reduce(0) { $0 + $1.duration }
    }
}
