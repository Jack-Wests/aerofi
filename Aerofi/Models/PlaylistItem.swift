import Foundation
import SwiftData

/// Join model between Playlist and Song, ordered by `position`, so the same
/// song can appear in multiple playlists (or multiple times in one playlist)
/// without conflicting relationship state.
@Model
final class PlaylistItem {
    @Attribute(.unique) var id: UUID
    var position: Int
    var dateAdded: Date

    @Relationship var playlist: Playlist?
    @Relationship var song: Song?

    init(id: UUID = UUID(), position: Int, dateAdded: Date = Date(), playlist: Playlist? = nil, song: Song? = nil) {
        self.id = id
        self.position = position
        self.dateAdded = dateAdded
        self.playlist = playlist
        self.song = song
    }
}
